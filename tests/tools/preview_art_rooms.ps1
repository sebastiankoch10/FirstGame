$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=[IO.Path]::GetFullPath("$PSScriptRoot/../..")
$tiles=[Drawing.Bitmap]::FromFile("$root/FirstGame_ArtPack/environment/environment/ground_tiles_v2.png")
$frames=@()
for($i=0;$i-lt 13;$i++) {$frames += [Drawing.Bitmap]::FromFile(("$root/FirstGame_ArtPack/environment/environment/detail_{0:00}.png" -f $i))}
foreach($name in @('Room1','RoomCrypt','RoomRuins')) {
    $room=(Get-Content -LiteralPath "$root/rooms/$name/$name.yy" -Raw) -replace ',\s*([}\]])','$1' | ConvertFrom-Json
    $bitmap=[Drawing.Bitmap]::new(800,600)
    $g=[Drawing.Graphics]::FromImage($bitmap)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::Half
    $ox=1712; $oy=1652
    foreach($layer in ($room.layers | Where-Object resourceType -eq GMRTileLayer | Sort-Object depth -Descending)) {
        for($y=51;$y-lt 71;$y++) {for($x=53;$x-lt 79;$x++) {
            $tile=$layer.tiles.TileSerialiseData[($y*128+$x)]
            if($tile-eq 0){continue}
            $src=[Drawing.Rectangle]::new(($tile%8)*32,[int][math]::Floor($tile/8)*32,32,32)
            $dst=[Drawing.Rectangle]::new($x*32-$ox,$y*32-$oy,32,32)
            $g.DrawImage($tiles,$dst,$src,[Drawing.GraphicsUnit]::Pixel)
        }}
    }
    $instances=$room.layers | ForEach-Object {$_.instances} | Where-Object {$_.objectId.name -eq 'ObjectEnvironmentDecoration'} | Sort-Object y
    foreach($inst in $instances) {
        $w=[int](64*$inst.scaleX);$h=[int](64*$inst.scaleY)
        $dst=[Drawing.Rectangle]::new([int]($inst.x-32*$inst.scaleX-$ox),[int]($inst.y-52*$inst.scaleY-$oy),$w,$h)
        $g.DrawImage($frames[[int]$inst.imageIndex],$dst)
    }
    $g.Dispose()
    $bitmap.Save("$root/tests/reports/$name-art-preview.png",[Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}
$tiles.Dispose()
$frames | ForEach-Object {$_.Dispose()}
