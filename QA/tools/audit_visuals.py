"""Read-only production asset audit. Writes only QA evidence, never source/native art.

Uses GameMaker's local JSON helper and Windows System.Drawing (no paid/network API).
Composite frames are scanned once; native layer copies are hash compared separately.
Contact sheets intentionally show nearest-neighbour previews, not newly generated art.
"""
from pathlib import Path
from collections import Counter,defaultdict
import csv,hashlib,json,subprocess,sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads
DATA=ROOT/'QA/data';SHOTS=ROOT/'QA/screenshots'

def family(name):
    for prefix,label in [('spr_fg_swordsmanv3_','swordsman'),('spr_fg_magev3_','mage'),('spr_fg_rangerv3_','ranger'),('spr_master_skeleton_','skeleton'),('spr_fg_dragonboss_','dragon'),('spr_fg_dragonextra_','dragon'),('spr_bv2_behemoth_','behemoth'),('spr_bv2_fire_','twins'),('spr_bv2_ice_','twins'),('spr_master_','world'),('icon_','icons'),('spr_v2_fx_','spell_fx'),('spr_class_fx_','class_fx'),('spr_dragon_fx_','dragon_fx'),('spr_bv2_','boss_fx')]:
        if name.startswith(prefix):return label
    if name.startswith('spr_mage_star_'):return 'class_fx'
    if any(x in name for x in ['coin','chest','magnet','firebolt','icebolt']):return 'items_projectiles'
    return 'other_registered'

def main():
    DATA.mkdir(parents=True,exist_ok=True);SHOTS.mkdir(parents=True,exist_ok=True)
    project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8-sig'))
    sprites=[];frames=[];errors=[];sheets=[];groups=defaultdict(list);layer_checks=0
    for resource in project['resources']:
        path=ROOT/resource['id']['path']
        if not resource['id']['path'].startswith('sprites/'):continue
        d=loads(path.read_text(encoding='utf-8-sig'));name=d['name'];group=family(name)
        info={'name':name,'family':group,'frames':len(d['frames']),'width':d['width'],'height':d['height'],'origin':[d['sequence']['xorigin'],d['sequence']['yorigin']],'bbox':[d['bbox_left'],d['bbox_top'],d['bbox_right'],d['bbox_bottom']],'edge_filtering':d.get('edgeFiltering',False),'path':path.relative_to(ROOT).as_posix()}
        if not(0<=info['origin'][0]<=d['width'] and 0<=info['origin'][1]<=d['height']):errors.append(f'{name}: origin outside canvas')
        for i,frame in enumerate(d['frames']):
            uid=frame['name'];png=path.parent/(uid+'.png');key=f'{name}:{i}'
            entry={'key':key,'sprite':name,'index':i,'family':group,'path':str(png),'expected':[d['width'],d['height']]};frames.append(entry)
            if not png.exists():errors.append(f'{key}: missing composite');continue
            layers=list((path.parent/'layers'/uid).glob('*.png'))
            # Imported project uses one visible layer. Equality is only asserted for one-layer sprites.
            if len(d['layers'])==1:
                layer_checks+=1
                if len(layers)!=1 or hashlib.sha256(png.read_bytes()).digest()!=hashlib.sha256(layers[0].read_bytes()).digest():errors.append(f'{key}: composite/layer mismatch')
            if i==0:groups[group].append((str(png),name))
        sprites.append(info)
    # Every registered sprite appears once. Separate sequences show every frame in selected current actions.
    for group,entries in sorted(groups.items()):
        for start in range(0,len(entries),64):
            page=start//64+1;chunk=entries[start:start+64];target=SHOTS/f'visual-{group}-{page:02}.png'
            sheets.append({'heading':f'{group} / registered sprite first frames / page {page}','paths':[x[0] for x in chunk],'labels':[x[1].replace('spr_fg_','').replace('spr_master_','master_') for x in chunk],'target':str(target)})
    selected=[f for f in frames if f['family'] in ['swordsman','mage','ranger','skeleton'] and (f['sprite'].endswith('_right') or f['sprite'].endswith('_down'))]
    for group in ['swordsman','mage','ranger','skeleton']:
        entries=[f for f in selected if f['family']==group]
        for start in range(0,len(entries),64):
            page=start//64+1;chunk=entries[start:start+64]
            sheets.append({'heading':f'{group} / all frames down + right + right diagonals / page {page}','paths':[x['path'] for x in chunk],'labels':[x['sprite'].replace('spr_fg_','').replace('spr_master_','')+' #'+str(x['index']) for x in chunk],'target':str(SHOTS/f'sequence-{group}-{page:02}.png')})
    manifest={'frames':frames,'pixel_result':str(DATA/'visual-pixels.json'),'sheets':sheets}
    (DATA/'visual-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    subprocess.run(['powershell','-NoProfile','-ExecutionPolicy','Bypass','-File',str(Path(__file__).with_name('audit_visual_pixels.ps1')),'-Manifest',str(DATA/'visual-manifest.json')],check=True)
    metrics={r['key']:r for r in json.loads((DATA/'visual-pixels.json').read_text(encoding='utf-8-sig'))}
    edge=[];opaque=[];empty=[];partial=[];bounds_by_sprite=defaultdict(list)
    for f in frames:
        m=metrics[f['key']]
        if m['error']:errors.append(f"{f['key']}: {m['error']}");continue
        a=m['metrics'];f.update(width=a[0],height=a[1],visible_pixels=a[2],solid_pixels=a[3],partial_alpha_pixels=a[4],bounds=a[5:9],canvas_edge_pixels=a[9],white_canvas_edge_pixels=a[10],nontransparent_corners=a[11])
        if a[:2]!=f['expected']:errors.append(f"{f['key']}: dimension mismatch")
        if a[2]==0:empty.append(f['key'])
        if a[9]>0:edge.append(f['key'])
        if a[2]==a[0]*a[1]:opaque.append(f['key'])
        if a[4]>0:partial.append(f['key'])
        bounds_by_sprite[f['sprite']].append(a[8]-a[6]+1)
    variance=[]
    for n,heights in bounds_by_sprite.items():
        if len(heights)>1 and min(heights)>0 and max(heights)/min(heights)>1.35:variance.append({'sprite':n,'min_height':min(heights),'max_height':max(heights),'ratio':round(max(heights)/min(heights),3)})
    baseline=ROOT/'QA/baseline/manifest.json';preserved={}
    if baseline.exists():
        b=json.loads(baseline.read_text(encoding='utf-8-sig'))
        for key,val in b.items():
            if isinstance(val,dict) and any('.png' in x.lower() for x in val):
                checked=0;changed=[]
                for rel,digest in val.items():
                    if not rel.lower().endswith('.png'):continue
                    p=ROOT/rel
                    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:changed.append(rel)
                    checked+=1
                preserved[key]={'checked':checked,'changed':changed}
    summary={'status':'PASS' if not errors else 'FAIL','scope':'All registered sprite composite PNGs; matching one-layer files; machine bounds/alpha audit. Flags require human interpretation, not automatic defects.','registered_sprites':len(sprites),'registered_composite_frames':len(frames),'matching_layer_checks':layer_checks,'family_sprites':dict(Counter(s['family'] for s in sprites)),'family_frames':dict(Counter(f['family'] for f in frames)),'errors':errors,'empty_frames':empty,'canvas_edge_contact':edge,'fully_opaque_frames':opaque,'partial_alpha_frames':partial,'height_variance_over_35_percent':variance,'baseline_png_preservation':preserved,'contact_sheets':[str(Path(s['target']).relative_to(ROOT)).replace('\\','/') for s in sheets],'sprites':sprites,'frames':frames}
    (DATA/'visual-audit.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    cols=['sprite','index','family','width','height','visible_pixels','partial_alpha_pixels','bounds','canvas_edge_pixels','white_canvas_edge_pixels','nontransparent_corners']
    with (DATA/'visual-frames.csv').open('w',newline='',encoding='utf-8') as out:
        w=csv.DictWriter(out,fieldnames=cols,extrasaction='ignore');w.writeheader();w.writerows(frames)
    print(json.dumps({k:summary[k] for k in ['status','registered_sprites','registered_composite_frames','matching_layer_checks','family_frames','errors','baseline_png_preservation']},indent=2))
    print('Flags: edge contact',len(edge),'opaque',len(opaque),'empty',len(empty),'partial alpha',len(partial),'height variance',len(variance),'sheets',len(sheets))

if __name__=='__main__':main()
