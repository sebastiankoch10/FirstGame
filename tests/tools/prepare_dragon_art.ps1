# Deterministic alpha-preserving import of original generated dragon artwork.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Join-Path $PSScriptRoot '../../FirstGame_ArtPack/dragon_boss'
function Bounds($b) {
 $l=$b.Width;$t=$b.Height;$r=0;$bottom=0
 for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){if($b.GetPixel($x,$y).A -ge 128){$l=[Math]::Min($l,$x);$t=[Math]::Min($t,$y);$r=[Math]::Max($r,$x);$bottom=[Math]::Max($bottom,$y)}}}
 return [Drawing.Rectangle]::FromLTRB($l,$t,$r+1,$bottom+1)
}
function Cell($sheet,$index,$cols,$rows) {
 $col=$index%$cols;$row=[int][Math]::Floor($index/$cols)
 $left=[int][Math]::Floor($col*$sheet.Width/$cols);$top=[int][Math]::Floor($row*$sheet.Height/$rows)
 $right=[int][Math]::Floor(($col+1)*$sheet.Width/$cols);$bottom=[int][Math]::Floor(($row+1)*$sheet.Height/$rows)
 return ,$sheet.Clone([Drawing.Rectangle]::FromLTRB($left,$top,$right,$bottom),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
function Graphics($bitmap){$g=[Drawing.Graphics]::FromImage($bitmap);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor;$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half;return $g}
$life=[Drawing.Bitmap]::new((Join-Path $root 'sources/life.png'));$attack=[Drawing.Bitmap]::new((Join-Path $root 'sources/attacks.png'))
$groups=@{idle=@('life',0,1,2,3);walk=@('life',4,5,6,7);turn=@('life',8,9);hurt=@('life',10);phase=@('life',11);charge=@('attack',0,1);breath=@('attack',2,3);breath_up=@('attack',4);breath_down=@('attack',5);stomp=@('attack',6,7);death=@('attack',9,10,11)}
$phaseExtra=Cell $attack 8 4 3
$test=Cell $life 0 4 3;$idleBounds=Bounds $test;$unit=[Math]::Min(430.0/($idleBounds.Height/$test.Height),500.0);$test.Dispose()
$anchors=@{};$spec=@{charge=@(@(0.82,0.23),@(0.84,0.29));breath=@(@(0.90,0.33),@(0.95,0.41));breath_up=,@(0.88,0.19);breath_down=,@(0.92,0.45)}
foreach($action in $groups.Keys){$def=$groups[$action];$sheet=if($def[0] -eq 'life'){$life}else{$attack};$idx=0;$list=@()
 foreach($index in $def[1..($def.Length-1)]){
  $cell=Cell $sheet $index 4 3;$bounds=Bounds $cell;$factor=$unit/$cell.Width
  $out=[Drawing.Bitmap]::new(512,512,[Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=Graphics $out
  $dest=[Drawing.Rectangle]::new([int](256+($bounds.Left-$cell.Width/2)*$factor),[int](480-$bounds.Height*$factor),[int]($bounds.Width*$factor),[int]($bounds.Height*$factor))
  $g.DrawImage($cell,$dest,$bounds,[Drawing.GraphicsUnit]::Pixel);$g.Dispose();$out.Save((Join-Path $root "frames/$action-$idx.png"),[Drawing.Imaging.ImageFormat]::Png);$out.Dispose()
  if($spec.ContainsKey($action)){$point=$spec[$action][$idx];$list+=,@([Math]::Round(($point[0]-0.5)*$unit,2),[Math]::Round(($point[1]-$bounds.Bottom/$cell.Height)*$unit,2))}
  $cell.Dispose();$idx++
 }
 if($action -eq 'phase'){$bounds=Bounds $phaseExtra;$factor=$unit/$phaseExtra.Width;$out=[Drawing.Bitmap]::new(512,512);$g=Graphics $out;$g.DrawImage($phaseExtra,[Drawing.Rectangle]::new([int](256+($bounds.Left-$phaseExtra.Width/2)*$factor),[int](480-$bounds.Height*$factor),[int]($bounds.Width*$factor),[int]($bounds.Height*$factor)),$bounds,[Drawing.GraphicsUnit]::Pixel);$g.Dispose();$out.Save((Join-Path $root 'frames/phase-1.png'),[Drawing.Imaging.ImageFormat]::Png);$out.Dispose()}
 if($list.Length -gt 0){$anchors[$action]=$list}
}
$phaseExtra.Dispose();$life.Dispose();$attack.Dispose()
$anchors|ConvertTo-Json -Depth 8|Set-Content (Join-Path $root 'anchors.json') -Encoding UTF8
$vfx=[Drawing.Bitmap]::new((Join-Path $root 'sources/vfx.png'))
foreach($index in 0..7){$cell=Cell $vfx $index 4 2;$bounds=Bounds $cell
 if($index -lt 4){$name="flame-$index";$w=128;$h=64;$oy=64}else{if($index -lt 6){$name="muzzle-$($index-4)";$w=96;$h=96;$oy=96}else{$name="magma-$($index-6)";$w=96;$h=160;$oy=160}}
 $out=[Drawing.Bitmap]::new($w,$h,[Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=Graphics $out;$g.DrawImage($cell,[Drawing.Rectangle]::new(0,0,$w,$h),$bounds,[Drawing.GraphicsUnit]::Pixel);$g.Dispose();$out.Save((Join-Path $root "frames/$name.png"),[Drawing.Imaging.ImageFormat]::Png);$out.Dispose();$cell.Dispose()
}
$vfx.Dispose()
