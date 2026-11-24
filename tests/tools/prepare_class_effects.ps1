# Mechanical extraction of newly generated production atlases; originals remain unchanged.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Drawing.Drawing2D;
public static class ClassEffectsAtlas {
 public static void Extract(string input,string output,int cols,int rows,int size,bool actor) {
  using(var sheet=new Bitmap(input)){
   for(int row=0;row<rows;row++)for(int col=0;col<cols;col++){
    var box=Rectangle.FromLTRB(col*sheet.Width/cols,row*sheet.Height/rows,(col+1)*sheet.Width/cols,(row+1)*sheet.Height/rows);
    using(var cell=sheet.Clone(box,PixelFormat.Format32bppArgb)){
     int l=cell.Width,t=cell.Height,r=-1,b=-1;
     for(int y=0;y<cell.Height;y++)for(int x=0;x<cell.Width;x++){
      var c=cell.GetPixel(x,y);if(c.A<96){cell.SetPixel(x,y,Color.Transparent);continue;}
      // Preserve genuine partial-alpha glow; transparent RGB is cleared.
      l=Math.Min(l,x);r=Math.Max(r,x);t=Math.Min(t,y);b=Math.Max(b,y);
     }
     if(r<0)throw new Exception("Empty VFX cell");
     using(var dst=new Bitmap(size,size,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(dst)){
      g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
      if(actor){var crop=Rectangle.FromLTRB(l,t,r+1,b+1);double scale=Math.Min(450.0/crop.Height,490.0/crop.Width);int w=(int)Math.Round(crop.Width*scale),h=(int)Math.Round(crop.Height*scale);g.DrawImage(cell,new Rectangle((size-w)/2,480-h,w,h),crop,GraphicsUnit.Pixel);}
      else {g.DrawImage(cell,new Rectangle(0,0,size,size),new Rectangle(0,0,cell.Width,cell.Height),GraphicsUnit.Pixel);}
      dst.Save(System.IO.Path.Combine(output,row+"-"+col+".png"),ImageFormat.Png);
     }
    }
   }
  }
 }
}
'@
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/class_overhaul'))
foreach($name in @('class_fx','dragon_fx','dragon_poses')){
 $dest=Join-Path $artRoot "frames/$name"
 New-Item -ItemType Directory -Force $dest | Out-Null
 $pose=$name -eq 'dragon_poses'
 [ClassEffectsAtlas]::Extract((Join-Path $artRoot "sources/$name.png"),$dest,$(if($pose){4}else{8}),$(if($pose){4}else{8}),$(if($pose){512}else{256}),$pose)
}
Write-Output 'Prepared 128 VFX frames and 16 supplementary blue-dragon poses.'
$orb=Join-Path $artRoot 'frames/mage_orb'
New-Item -ItemType Directory -Force $orb | Out-Null
[ClassEffectsAtlas]::Extract((Join-Path $artRoot 'sources/mage_orb.png'),$orb,4,2,256,$false)
Write-Output 'Prepared eight dedicated round star-orb / implosion frames.'
