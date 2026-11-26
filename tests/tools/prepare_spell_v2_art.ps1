# Mechanical atlas extraction only. Character repair is a separate audited operation.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Drawing.Drawing2D;
public static class SpellAtlas {
 public static int[] Cuts(Bitmap b,int count,bool vertical) {
  int length=vertical?b.Height:b.Width,span=vertical?b.Width:b.Height;int[] density=new int[length],cuts=new int[count+1];cuts[count]=length;
  for(int p=0;p<length;p++)for(int q=0;q<span;q++){var c=b.GetPixel(vertical?q:p,vertical?p:q);if(c.R+c.G+c.B>150)density[p]++;}
  for(int i=1;i<count;i++){int centre=(int)Math.Round(i*length/(double)count),radius=(int)(length/(double)count*.35),lo=Math.Max(1,centre-radius),hi=Math.Min(length-2,centre+radius),min=int.MaxValue;
   for(int p=lo;p<=hi;p++)min=Math.Min(min,density[p]);int best=centre,bestLen=0,start=lo,len=0;
   for(int p=lo;p<=hi+1;p++){if(p<=hi&&density[p]<=min+2){if(len==0)start=p;len++;}else{if(len>bestLen){best=start+len/2;bestLen=len;}len=0;}}cuts[i]=best;
  }return cuts;
 }
 public static void Icon(Bitmap b,int left,int top,int right,int bottom,string path) {
  int l=right,t=bottom,r=left,d=top;
  for(int y=top;y<bottom;y++)for(int x=left;x<right;x++){var c=b.GetPixel(x,y);if(c.R+c.G+c.B>150){l=Math.Min(l,x);r=Math.Max(r,x);t=Math.Min(t,y);d=Math.Max(d,y);}}
  Save(b,Rectangle.FromLTRB(l,t,r+1,d+1),64,path);
 }
 public static void Save(Bitmap b,Rectangle crop,int size,string path) {
  using(var output=new Bitmap(size,size,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(output)){
   g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;g.DrawImage(b,new Rectangle(0,0,size,size),crop,GraphicsUnit.Pixel);output.Save(path,ImageFormat.Png);
  }
 }
 public static void Effect(Bitmap b,int col,int row,string path) {
  var crop=new Rectangle(col*b.Width/4,row*b.Height/6,b.Width/4,b.Height/6);
  using(var cell=b.Clone(crop,PixelFormat.Format32bppArgb)) {
   for(int y=0;y<cell.Height;y++)for(int x=0;x<cell.Width;x++){var c=cell.GetPixel(x,y);cell.SetPixel(x,y,c.A<96?Color.Transparent:Color.FromArgb(c.A,c.R,c.G,c.B));}
   Save(cell,new Rectangle(0,0,cell.Width,cell.Height),256,path);
  }
 }
}
'@
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/vfx/spell_v2'))
$icons=[Drawing.Bitmap]::new((Join-Path $root 'sources/icons.png'));$rows=[SpellAtlas]::Cuts($icons,6,$true);$cols=[SpellAtlas]::Cuts($icons,6,$false)
$ids=@(101..118)+@(201..218)
foreach($i in 0..35){$row=[int][Math]::Floor($i/6);$col=$i%6;[SpellAtlas]::Icon($icons,$cols[$col],$rows[$row],$cols[$col+1],$rows[$row+1],(Join-Path $root "frames/icon-$($ids[$i]).png"))};$icons.Dispose()
$fx=[Drawing.Bitmap]::new((Join-Path $root 'sources/effects.png'))
foreach($row in 0..5){foreach($col in 0..3){[SpellAtlas]::Effect($fx,$col,$row,(Join-Path $root "frames/fx-$row-$col.png"))}};$fx.Dispose()
Write-Output 'Prepared 36 distinct icons and 24 real RGBA effect frames.'
