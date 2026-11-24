# Read-only verification of prepared boss frames, including alpha; never repaints source/native sprites.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;
public static class BossV2ReadAudit {
 public static int[] Inspect(string path) {
  using(var b=new Bitmap(path)){
   int visible=0,transparent=0,partial=0,l=b.Width,t=b.Height,r=-1,d=-1;
   for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){
    int a=b.GetPixel(x,y).A;if(a==0){transparent++;continue;}visible++;if(a<255)partial++;
    l=Math.Min(l,x);r=Math.Max(r,x);t=Math.Min(t,y);d=Math.Max(d,y);
   }
   return new int[]{b.Width,b.Height,visible,transparent,partial,l,t,r,d,b.GetPixel(0,0).A,b.GetPixel(b.Width-1,0).A,b.GetPixel(0,b.Height-1).A,b.GetPixel(b.Width-1,b.Height-1).A};
  }
 }
}
'@
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/boss_v2'))
$expected=@{fire=32;ice=32;behemoth_life=16;behemoth_attacks=32;twins_fx=36;swamp_fx=36;brood=4;projectiles=8}
$sizes=@{fire=128;ice=128;behemoth_life=512;behemoth_attacks=512;twins_fx=256;swamp_fx=256;brood=96;projectiles=128}
$results=@();$failed=@();$total=0
foreach($family in $expected.Keys){
 $files=@(Get-ChildItem -LiteralPath (Join-Path $artRoot "frames/$family") -Filter '*.png')
 if($files.Count -ne $expected[$family]){$failed+="Unexpected count $family"}
 foreach($file in $files){
  $a=[BossV2ReadAudit]::Inspect($file.FullName)
  $valid=$a[0] -eq $sizes[$family] -and $a[1] -eq $sizes[$family] -and $a[2] -gt 0 -and $a[3] -gt 0
  if(-not $valid){$failed+=$file.FullName}
  $results+=@{family=$family;frame=$file.Name;valid=$valid;width=$a[0];height=$a[1];visible_pixels=$a[2];transparent_pixels=$a[3];partial_alpha_pixels=$a[4];bounds=@($a[5],$a[6],$a[7],$a[8]);corner_alpha=@($a[9],$a[10],$a[11],$a[12])}
  $total++
 }
}
$sourceFiles=@(Get-ChildItem -LiteralPath (Join-Path $artRoot 'sources') -Filter '*.png')
$report=@{status=$(if($failed.Count -eq 0){'PASS'}else{'FAIL'});passed=$failed.Count -eq 0;prepared_frames=$total;generated_source_images=$sourceFiles.Count;native_expected_sprite_resources=54;native_expected_frame_files=204;failures=$failed;frames=$results}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $artRoot 'art-audit.json')
Write-Output "Art audit: $($report.status); $total nonempty transparent frames; $($sourceFiles.Count) source atlases."
if($failed.Count -gt 0){exit 1}
