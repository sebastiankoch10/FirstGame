from pathlib import Path
import json,sys,shutil
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
from gms_helpers.asset_types.media import SoundAsset
ROOT=Path(__file__).resolve().parents[2]
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def main():
    manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'))
    project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
    groups=['Audio','Audio/Music','Audio/UI','Audio/Weapons','Audio/Spells','Audio/Enemies','Audio/Bosses']
    for group in groups:
        folder='folders/'+group+'.yy'
        if not any(f['folderPath']==folder for f in project['Folders']):
            project['Folders'].append({'$GMFolder':'','%Name':group.split('/')[-1],'folderPath':folder,'name':group.split('/')[-1],'resourceType':'GMFolder','resourceVersion':'2.0'})
    for entry in manifest['files']:
        source=ROOT/entry['file'];name=('mus_fg_' if entry['category']=='Music' else 'sfx_fg_')+source.stem
        folder=ROOT/'sounds'/name;folder.mkdir(parents=True,exist_ok=True)
        data=SoundAsset().create_yy_data(name,'folders/Audio/'+entry['category']+'.yy',sample_rate=32000,format=2)
        data['duration']=entry['seconds'];data['channelFormat']=1 if entry['channels']==2 else 0
        data['compression']=0;data['preload']=entry['category']!='Music'
        shutil.copyfile(source,folder/(name+'.wav'));write(folder/(name+'.yy'),dumps(data))
        if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sounds/{name}/{name}.yy'}})
        entry['resource']=name
    template=loads((ROOT/'scripts/gameplay/gameplay.yy').read_text(encoding='utf-8'))
    template['name']=template['%Name']='audio_manager'
    write(ROOT/'scripts/audio_manager/audio_manager.yy',dumps(template))
    if not any(r['id']['name']=='audio_manager' for r in project['resources']):project['resources'].append({'id':{'name':'audio_manager','path':'scripts/audio_manager/audio_manager.yy'}})
    project['resources'].sort(key=lambda x:x['id']['name'].lower());project['Folders'].sort(key=lambda x:x['folderPath'].lower())
    write(ROOT/'FirstGame.yyp',dumps(project));write(ROOT/'Audio/manifest.json',json.dumps(manifest,indent=2)+'\n')
    print('Imported',len(manifest['files']),'real sound resources')
if __name__=='__main__':main()
