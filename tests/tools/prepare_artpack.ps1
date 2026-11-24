param(
    [string]$DetailSource = "$PSScriptRoot/../../FirstGame_ArtPack/environment/landscape_source.png",
    [string]$GroundSource = "$PSScriptRoot/../../FirstGame_ArtPack/environment/ground_source.png"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$artPath = [IO.Path]::GetFullPath("$PSScriptRoot/../../FirstGame_ArtPack/environment")
function Get-Cell($source, [int]$index, [int]$size) {
    $bitmap = [Drawing.Bitmap]::new($size,$size)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $column = $index % 4
    $row = [math]::Floor($index / 4)
    $sourceRect = [Drawing.Rectangle]::new([int]($column*$source.Width/4),[int]($row*$source.Height/4),[int]($source.Width/4),[int]($source.Height/4))
    $graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,$size,$size),$sourceRect,[Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    return ,$bitmap
}
$details = [Drawing.Bitmap]::FromFile([IO.Path]::GetFullPath($DetailSource))
for ($i=0; $i -lt 16; $i++) {
    $cell = Get-Cell $details $i 64
    $cell.Save((Join-Path $artPath ('detail_{0:00}.png' -f $i)),[Drawing.Imaging.ImageFormat]::Png)
    $cell.Dispose()
}
$details.Dispose()
$ground = [Drawing.Bitmap]::FromFile([IO.Path]::GetFullPath($GroundSource))
$sheet = [Drawing.Bitmap]::new(256,256)
$canvas = [Drawing.Graphics]::FromImage($sheet)
for ($i=0; $i -lt 16; $i++) {
    $cell = Get-Cell $ground $i 32
    # Match edge colors to avoid visible seams between generated variants.
    if ($i -lt 12) {
        $sr=0; $sg=0; $sb=0
        for ($py=0;$py-lt 32;$py++) {for ($px=0;$px-lt 32;$px++) {
            $c=$cell.GetPixel($px,$py);$sr+=$c.R;$sg+=$c.G;$sb+=$c.B
        }}
        for ($py=0;$py-lt 32;$py++) {for ($px=0;$px-lt 32;$px++) {
            $c=$cell.GetPixel($px,$py)
            if($i-ge 8) {
                # Detail layers contain flowers only, never a second opaque grass square.
                if(-not (($c.R-gt 175 -and $c.B-gt 120) -or ($c.B-gt $c.G*0.95) -or ($c.R-gt 205 -and $c.G-gt 180))) {
                    $cell.SetPixel($px,$py,[Drawing.Color]::Transparent)
                }
            } else {
                $weight=[math]::Min(1,[math]::Min([math]::Min($px,31-$px),[math]::Min($py,31-$py))/4.0)
                $r=[int][math]::Min(255,[math]::Max(0,150+($c.R-$sr/1024)*$weight))
                $g=[int][math]::Min(255,[math]::Max(0,196+($c.G-$sg/1024)*$weight))
                $b=[int][math]::Min(255,[math]::Max(0,75+($c.B-$sb/1024)*$weight))
                $cell.SetPixel($px,$py,[Drawing.Color]::FromArgb(255,$r,$g,$b))
            }
        }}
    }
    $idx=$i+1
    $canvas.DrawImageUnscaled($cell,($idx%8)*32,[int][math]::Floor($idx/8)*32)
    $cell.Dispose()
}
# Sixteen transparent path pieces: rounded center joined to N/E/S/W neighbors.
$dirt = Get-Cell $ground 12 32
for ($mask=0; $mask -lt 16; $mask++) {
    $piece = [Drawing.Bitmap]::new(32,32)
    for ($y=0; $y -lt 32; $y++) { for ($x=0; $x -lt 32; $x++) {
        $dx=$x-15.5; $dy=$y-15.5
        $inside = ($mask -eq 15) -or ($dx*$dx+$dy*$dy -lt 245)
        if (($mask-band 1) -and $y-lt 16) { $inside=$true }
        if (($mask-band 2) -and $x-ge 16) { $inside=$true }
        if (($mask-band 4) -and $y-ge 16) { $inside=$true }
        if (($mask-band 8) -and $x-lt 16) { $inside=$true }
        if ($inside) { $piece.SetPixel($x,$y,$dirt.GetPixel($x,$y)) }
    }}
    $idx=17+$mask
    $canvas.DrawImageUnscaled($piece,($idx%8)*32,[int][math]::Floor($idx/8)*32)
    $piece.Dispose()
}
$canvas.Dispose(); $ground.Dispose(); $dirt.Dispose()
$sheet.Save((Join-Path $artPath 'ground_tiles_v2.png'),[Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()

