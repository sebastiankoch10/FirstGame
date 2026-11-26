"""Fresh isolated native VM tests for authored class cycles and countdown dragon encounters.
Builds outside the project in %LOCALAPPDATA%/FirstGame-Tests/classes/<stamp>; the copy and EXE are deleted afterwards."""
from pathlib import Path
import json,os,re,shutil,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
from gms_helpers.runner import GameMakerRunner
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def main():
 work=Path(os.environ['LOCALAPPDATA'])/'FirstGame-Tests'/'classes'/time.strftime('%Y%m%d-%H%M%S')
 try:run(work)
 finally:
  for n in ('project','build','cache','temp'):shutil.rmtree(work/n,ignore_errors=True)
def run(work):
 _unused=Path(os.environ['LOCALAPPDATA'])/'FirstGame-Tests'/'classes'/time.strftime('%Y%m%d-%H%M%S');project=work/'project';project.mkdir(parents=True)
 for name in ('objects','scripts','sprites','sounds','tilesets','rooms','options','shaders'):shutil.copytree(ROOT/name,project/name)
 yyp=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));yyp['name']=yyp['%Name']='FirstGameClassDragonSmoke';write(project/'FirstGameClassDragonSmoke.yyp',dumps(yyp))
 p=project/'options/main/options_main.yy';d=loads(p.read_text(encoding='utf-8'));d['option_gameguid']='8dab69de-9a58-4144-a259-78948fb4caf6';write(p,dumps(d))
 p=project/'options/windows/options_windows.yy';d=loads(p.read_text(encoding='utf-8'));d['option_windows_display_name']='FirstGame Class Dragon Native Check';write(p,dumps(d))
 p=project/'scripts/gameplay/gameplay.gml';write(p,p.read_text(encoding='utf-8-sig')+'\n'+(ROOT/'tests/class_dragon_harness.gml').read_text(encoding='utf-8-sig'))
 p=project/'objects/ObjectMainMenu/Create_0.gml';write(p,'global.master_volume=0;global.music_volume=0;global.effects_volume=0;\n'+p.read_text(encoding='utf-8-sig')+'\nexception_unhandled_handler(function(ex){show_debug_message("CLASS_DRAGON_EXCEPTION "+json_stringify(ex));game_end();return true;});\n')
 write(project/'objects/ObjectMainMenu/Step_0.gml','cd_menu_tick();')
 write(project/'objects/ObjectController/Step_0.gml','cd_controller_tick();')
 p=project/'objects/ObjectController/Draw_64.gml';write(p,p.read_text(encoding='utf-8-sig')+'\ncd_capture_draw();\n')
 for obj in ['ObjectPlayer','ObjectSpawner','ObjectMonster','ObjectBossMonster','ObjectFireball','ObjectIceball','ObjectLightningball']:
  p=project/f'objects/{obj}/Step_0.gml';write(p,'if(variable_global_exists("cd_hold") && global.cd_hold)exit;\n'+p.read_text(encoding='utf-8-sig'))
 for p in project.rglob('*.gml'):
  s=p.read_text(encoding='utf-8-sig');s=re.sub(r'\bdelta_time\s*/\s*1000000(?:\.0)?\b','cd_sim_dt()',s);write(p,s)
 p=project/'scripts/gameplay/gameplay.gml';write(p,p.read_text(encoding='utf-8')+'\nfunction cd_sim_dt(){return variable_global_exists("cd_dt") ? global.cd_dt : delta_time/1000000;}\n')
 runner=GameMakerRunner(project,runtime_version='2024.14.4.268');igor=runner.find_gamemaker_runtime();license_file=runner.find_license_file()
 if not igor or not license_file:raise RuntimeError('Installed Igor/runtime/license unavailable')
 for name in ('build','cache','temp'):(work/name).mkdir()
 cmd=[str(igor),f'/lf={license_file}',f'/uf={license_file.parent}',f'/rp={runner.runtime_path}',f'/project={project/"FirstGameClassDragonSmoke.yyp"}',f'/cache={work/"cache"}',f'/temp={work/"temp"}',f'/of={work/"build/FirstGameClassDragonSmoke"}',f'--tf={work/"build/FirstGameClassDragonSmoke.zip"}','--','Windows','PackageZip']
 print('Building class/dragon native test copy...',flush=True)
 with gamemaker_machine_operation('class-dragon-smoke-build',project):
  with (work/'build.log').open('w',encoding='utf-8') as log:subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,cwd=project,timeout=180)
 exe=work/'build/FirstGameClassDragonSmoke.exe'
 if 'Final Compile finished.' not in (work/'build.log').read_text(encoding='utf-8',errors='replace') or not exe.is_file():raise RuntimeError(f'Fresh build failed: {work}/build.log')
 started=time.time();startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=4
 with (work/'runtime.log').open('w',encoding='utf-8') as log:
  process=subprocess.Popen([str(exe),'-output',str(work/'runner.log')],cwd=exe.parent,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup)
  try:code=process.wait(timeout=180)
  except subprocess.TimeoutExpired:process.kill();process.wait();raise RuntimeError(f'Runtime timeout: {work}/runtime.log')
 result=None
 for p in [work/'runtime.log',work/'runner.log']:
  if p.exists():
   match=re.search(r'CLASS_DRAGON_RESULT (\{[^\r\n]+\})',p.read_text(encoding='utf-8',errors='replace'))
   if match:result=json.loads(match.group(1));break
 if result is None:raise RuntimeError(f'No explicit runtime result: {work}/runtime.log')
 for save in Path(os.environ['LOCALAPPDATA']).glob('FirstGame*'):
  if save.is_dir():
   for p in save.rglob('cdcapture-*.png'):
    if p.stat().st_mtime>=started:shutil.copyfile(p,work/p.name.removeprefix('cdcapture-'))
 result.update(exit_code=code,logs=str(work),rendered=[p.name for p in work.glob('*.png')]);result['passed']=result['passed'] and code==0
 write(ROOT/'tests/reports/class-dragon-native.json',json.dumps(result,indent=2)+'\n')
 print(json.dumps({k:result[k] for k in ['passed','checks','failures','logs','rendered']},indent=2),flush=True)
 if not result['passed']:raise RuntimeError('Native class/dragon assertions failed')
if __name__=='__main__':
 try:main()
 except Exception as e:print('FAIL:',e,file=sys.stderr,flush=True);raise SystemExit(1)
