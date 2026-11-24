# Deterministic grid slicing only: preserves generated RGBA, uses nearest-neighbour scaling.
Add-Type -AssemblyName System.Drawing
$root=Join-Path $PSScriptRoot '../../FirstGame_ArtPack/atmosphere_v2'
function Bounds($b) {
 $l=$b.Width;$t=$b.Height;$r=0;$bottom=0
 for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){if($b.GetPixel($x,$y).A -ge 128){$l=[Math]::Min($l,$x);$t=[Math]::Min($t,$y);$r=[Math]::Max($r,$x);$bottom=[Math]::Max($bottom,$y)}}}
 return [Drawing.Rectangle]::FromLTRB($l,$t,$r+1,$bottom+1)
}
function Cell($sheet,$col,$row,$cols,$rows) {
 $w=[int]($sheet.Width/$cols);$h=[int]($sheet.Height/$rows)
 return ,$sheet.Clone([Drawing.Rectangle]::new($col*$w,$row*$h,$w,$h),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
function Save-Frame($cell,$bounds,$factor,$size,$originY,$path) {
 $result=[Drawing.Bitmap]::new($size,$size,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($result);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor;$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
 $w=[int][Math]::Round($bounds.Width*$factor);$h=[int][Math]::Round($bounds.Height*$factor)
 $g.DrawImage($cell,[Drawing.Rectangle]::new([int](($size-$w)/2),$originY-$h,$w,$h),$bounds,[Drawing.GraphicsUnit]::Pixel)
 $g.Dispose();$result.Save($path,[Drawing.Imaging.ImageFormat]::Png);$result.Dispose()
}
$sheet=[Drawing.Bitmap]::new((Join-Path $root 'sources/knight-sheet.png'))
$dirs=@('right','down','up');$actions=@{idle=@(0);walk=@(1,2);run=@(1,2);attack=@(3,4);jump=@(5);fall=@(5);dive=@(6);slide=@(6);dodge=@(6);hurt=@(7)}
foreach($row in 0..2){$idle=Cell $sheet 0 $row 8 3;$factor=48.0/(Bounds $idle).Height;$idle.Dispose()
 foreach($action in $actions.Keys){$idx=0;foreach($col in $actions[$action]){$cell=Cell $sheet $col $row 8 3;$bounds=Bounds $cell;$path=Join-Path $root "frames/knight-$action-$($dirs[$row])-$idx.png";Save-Frame $cell $bounds $factor 64 58 $path;$cell.Dispose();$idx++}}
}
$sheet.Dispose()
$sheet=[Drawing.Bitmap]::new((Join-Path $root 'sources/boss-sheet.png'))
foreach($row in 0..1){$actor=@('golem','dragon')[$row];$idle=Cell $sheet 0 $row 3 2;$factor=330.0/(Bounds $idle).Height;$idle.Dispose()
 foreach($col in 0..2){$cell=Cell $sheet $col $row 3 2;$bounds=Bounds $cell;$fit=[Math]::Min($factor,370.0/$bounds.Width);Save-Frame $cell $bounds $fit 384 360 (Join-Path $root "frames/boss-$actor-$col.png");$cell.Dispose()}
}
$sheet.Dispose()
# New ArtPack-derived magnet artwork, alpha-preserving nearest-neighbour import.
$orb=[Drawing.Bitmap]::new((Join-Path $root 'sources/magnet-orb.png'))
$bounds=Bounds $orb
Save-Frame $orb $bounds (36.0/$bounds.Height) 40 38 (Join-Path $root 'frames/magnet-orb.png')
$orb.Dispose()
$sheet=[Drawing.Bitmap]::new((Join-Path $root 'sources/knight-death-sheet.png'))
foreach($row in 0..2){foreach($col in 0..1){$cell=Cell $sheet $col $row 2 3;$bounds=Bounds $cell;Save-Frame $cell $bounds 0.15 64 58 (Join-Path $root "frames/knight-death-$($dirs[$row])-$col.png");$cell.Dispose()}}
$sheet.Dispose()
