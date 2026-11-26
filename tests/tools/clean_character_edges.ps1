# Conservative source-PNG repair: never erode the connected figure or threshold gray armor.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Collections.Generic;
public static class CharacterEdges {
 public static int[] Clean(string input,string output,bool quietPose) {
  using(var b=new Bitmap(input)) {
   int cleared=0,removed=0,partial=0;bool[,] seen=new bool[b.Width,b.Height];var components=new List<List<Point>>();int largest=0;
   for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){
    var c=b.GetPixel(x,y);if(c.A==0&&(c.R!=0||c.G!=0||c.B!=0)){b.SetPixel(x,y,Color.Transparent);cleared++;}
    if(c.A>0&&c.A<255)partial++;
    if(c.A>0&&!seen[x,y]){
     var group=new List<Point>();var queue=new Queue<Point>();queue.Enqueue(new Point(x,y));seen[x,y]=true;
     while(queue.Count>0){var p=queue.Dequeue();group.Add(p);for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){
      int nx=p.X+dx,ny=p.Y+dy;if(nx>=0&&ny>=0&&nx<b.Width&&ny<b.Height&&!seen[nx,ny]&&b.GetPixel(nx,ny).A>0){seen[nx,ny]=true;queue.Enqueue(new Point(nx,ny));}
     }}
     if(components.Count==0||group.Count>components[largest].Count)largest=components.Count;components.Add(group);
    }
   }
   if(components.Count>0)for(int i=0;i<components.Count;i++) {
    if(i==largest||components[i].Count>3)continue;bool gray=true,far=true;
    foreach(var p in components[i]){var c=b.GetPixel(p.X,p.Y);if(Math.Max(c.R,Math.Max(c.G,c.B))-Math.Min(c.R,Math.Min(c.G,c.B))>12||c.R<85)gray=false;
     int margin=quietPose?1:2;foreach(var q in components[largest])if(Math.Abs(p.X-q.X)<=margin&&Math.Abs(p.Y-q.Y)<=margin){far=false;break;}
    }
    if((gray||quietPose)&&far)foreach(var p in components[i]){b.SetPixel(p.X,p.Y,Color.Transparent);removed++;}
   }
   if(cleared+removed>0)b.Save(output,ImageFormat.Png);
   return new int[]{removed,cleared,partial};
  }
 }
}
'@
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$entries=Get-Content (Join-Path $root 'output/character_frames.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$records=@();$visible=0;$hidden=0;$count=0
foreach($entry in $entries){
 $path=Join-Path $root $entry.path;$clean=Join-Path $root ('FirstGame_ArtPack/vfx/spell_v2/clean_characters/'+$entry.sprite+'/'+$entry.frame+'.png')
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($clean)) | Out-Null
 $action=($entry.sprite -split '_')[3];$quietPose=$action -in @('idle','walk','run','jump','fall','dive','slide')
 $change=[CharacterEdges]::Clean($path,$clean,$quietPose);$count++
 if($change[0]+$change[1] -gt 0){
  $backup=Join-Path $root ('FirstGame_ArtPack/vfx/spell_v2/character_before/'+$entry.sprite+'/'+$entry.frame+'.png')
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup)) | Out-Null
  if(-not(Test-Path -LiteralPath $backup)){Copy-Item -LiteralPath $path -Destination $backup}
  Copy-Item -LiteralPath $clean -Destination $path;Copy-Item -LiteralPath $clean -Destination (Join-Path $root $entry.layer)
  $records+=@{path=$entry.path;removed_disconnected_speck_pixels=$change[0];cleared_invisible_rgb=$change[1];partial_alpha_preserved=$change[2];quiet_pose=$quietPose}
 }
 $visible+=$change[0];$hidden+=$change[1]
}
$report=@{status='PASS_CONSERVATIVE_REPAIR';frames_checked=$count;visible_detached_specks_removed=$visible;invisible_rgb_cleared=$hidden;changed=$records;connected_silhouettes_eroded=$false;rule='Quiet movement poses: remove only detached components <=3 pixels, never the connected figure. Attack poses: only distant gray specks; preserve colored effects.'}
$report | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 (Join-Path $root 'tests/reports/spell-v2-character-edges.json')
Write-Output "Checked $count active frames; removed $visible detached stray pixels; cleared $hidden invisible RGB pixels."
