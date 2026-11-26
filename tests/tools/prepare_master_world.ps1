# Reproducible mechanical atlas slicing. Original generated RGBA files stay unchanged.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Collections.Generic;
public static class MasterAtlas {
 static Dictionary<Bitmap,int[]> rowCache=new Dictionary<Bitmap,int[]>();
 static int[] Rows(Bitmap source,int count) {
  if(rowCache.ContainsKey(source))return rowCache[source];
  int[] density=new int[source.Height];
  for(int y=0;y<source.Height;y++)for(int x=0;x<source.Width;x++)if(source.GetPixel(x,y).A>=128)density[y]++;
  int[] cuts=new int[count+1];cuts[count]=source.Height;
  for(int i=1;i<count;i++) {
   int centre=(int)Math.Round(i*source.Height/(double)count),radius=(int)(source.Height/(double)count*.36);
   int from=Math.Max(1,centre-radius),to=Math.Min(source.Height-2,centre+radius),min=int.MaxValue;
   for(int y=from;y<=to;y++)min=Math.Min(min,density[y]);
   int bestStart=centre,bestLength=0,start=from,length=0;
   for(int y=from;y<=to+1;y++){
    if(y<=to&&density[y]<=min+2){if(length==0)start=y;length++;}
    else{if(length>bestLength){bestLength=length;bestStart=start;}length=0;}
   }
   cuts[i]=bestLength>0 ? bestStart+bestLength/2 : centre;
  }
  rowCache[source]=cuts;return cuts;
 }
 public static Bitmap Cell(Bitmap source,int column,int row,int columns,int rows,bool scenery=false) {
  int l=(int)Math.Round(column*source.Width/(double)columns),r=(int)Math.Round((column+1)*source.Width/(double)columns);
  var cuts=Rows(source,rows);int t=cuts[row],b=cuts[row+1];
  var result=source.Clone(Rectangle.FromLTRB(l,t,r,b),PixelFormat.Format32bppArgb);
  for(int j=0;j<result.Height;j++)for(int i=0;i<result.Width;i++) {
   var c=result.GetPixel(i,j);result.SetPixel(i,j,c.A<128 ? Color.Transparent : Color.FromArgb(255,c.R,c.G,c.B));
  }
  return result;
 }
 public static Rectangle Bounds(Bitmap b) {
  int l=b.Width,t=b.Height,r=-1,d=-1;
  for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++)if(b.GetPixel(x,y).A>0){l=Math.Min(l,x);t=Math.Min(t,y);r=Math.Max(r,x);d=Math.Max(d,y);}
  if(r<0)throw new Exception("Empty atlas cell");return Rectangle.FromLTRB(l,t,r+1,d+1);
 }
 public static void Clean(Bitmap cell,int minimum,bool largestOnly) {
  bool[,] seen=new bool[cell.Width,cell.Height];var components=new List<List<Point>>();int largest=0;
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++)if(!seen[i,j]&&cell.GetPixel(i,j).A>0){
   var component=new List<Point>();var queue=new Queue<Point>();queue.Enqueue(new Point(i,j));seen[i,j]=true;
   while(queue.Count>0){var p=queue.Dequeue();component.Add(p);
    for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){
     int nx=p.X+dx,ny=p.Y+dy;if(nx>=0&&nx<cell.Width&&ny>=0&&ny<cell.Height&&!seen[nx,ny]&&cell.GetPixel(nx,ny).A>0){seen[nx,ny]=true;queue.Enqueue(new Point(nx,ny));}
    }
   }
   if(components.Count==0||component.Count>components[largest].Count)largest=components.Count;
   components.Add(component);
  }
  bool[,] keep=new bool[cell.Width,cell.Height];
  for(int i=0;i<components.Count;i++)if((!largestOnly&&components[i].Count>=minimum)||(largestOnly&&i==largest))foreach(var p in components[i])keep[p.X,p.Y]=true;
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++)if(!keep[i,j])cell.SetPixel(i,j,Color.Transparent);
 }
 public static void Save(Bitmap source,Rectangle bounds,double factor,int width,int height,int originY,string path,bool fixedX=false) {
  using(var result=new Bitmap(width,height,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(result)) {
   g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
   int w=(int)Math.Round(bounds.Width*factor),h=(int)Math.Round(bounds.Height*factor);
   int x=fixedX ? width/2+(int)Math.Round((bounds.Left-source.Width/2.0)*factor) : (width-w)/2;
   if(w>width-2||h>originY||x<0||x+w>width)throw new Exception("Clipping frame "+path);
   g.DrawImage(source,new Rectangle(x,originY-h,w,h),bounds,GraphicsUnit.Pixel);result.Save(path,ImageFormat.Png);
  }
 }
 public static void Resize(Bitmap source,int width,int height,string path) {
  using(var result=new Bitmap(width,height,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(result)) {
   g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
   g.DrawImage(source,new Rectangle(0,0,width,height),new Rectangle(0,0,source.Width,source.Height),GraphicsUnit.Pixel);result.Save(path,ImageFormat.Png);
  }
 }
}
'@
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/environment/master_world'))
$ground=[Drawing.Bitmap]::new((Join-Path $root 'sources/ground.png'));[MasterAtlas]::Resize($ground,512,512,(Join-Path $root 'frames/ground.png'));$ground.Dispose()
$props=@('oak','maple','pine','ancient','ferns','redshrub','blueflowers','goldbush','pillar','arch','wall','brazier','rocks','stump','paving','leaves')
$heights=@(230,224,245,238,64,74,60,72,148,212,132,122,64,72,64,54)
$sheet=[Drawing.Bitmap]::new((Join-Path $root 'sources/scenery.png'))
foreach($i in 0..15){
 $cell=[MasterAtlas]::Cell($sheet,($i%4),[int][Math]::Floor($i/4),4,4,$true)
 [MasterAtlas]::Clean($cell,20,$false);$bounds=[MasterAtlas]::Bounds($cell)
 $factor=[Math]::Min($heights[$i]/[double]$bounds.Height,246.0/$bounds.Width)
 [MasterAtlas]::Save($cell,$bounds,$factor,256,320,304,(Join-Path $root "frames/$($props[$i]).png"));$cell.Dispose()
};$sheet.Dispose()
$dirs=@('right','up_right','up','up_left','left','down_left','down','down_right')
$sets=@{'skeleton-motion'=@{idle=@(0,1);walk=@(2,3,4,5);attack=@(6,7)};'skeleton-reaction'=@{hurt=@(0,1,2);death=@(3,4,5,6,7)}}
foreach($source in $sets.Keys){
 $sheet=[Drawing.Bitmap]::new((Join-Path $root "sources/$source.png"))
 $ref=[MasterAtlas]::Cell($sheet,0,6,8,8);[MasterAtlas]::Clean($ref,0,$true);$factor=56.0/[MasterAtlas]::Bounds($ref).Height;$ref.Dispose()
 foreach($row in 0..7){foreach($action in $sets[$source].Keys){$index=0;foreach($column in $sets[$source][$action]){
  $cell=[MasterAtlas]::Cell($sheet,$column,$row,8,8);[MasterAtlas]::Clean($cell,0,$true);$bounds=[MasterAtlas]::Bounds($cell)
  [MasterAtlas]::Save($cell,$bounds,$factor,96,96,88,(Join-Path $root "frames/skeleton-$action-$($dirs[$row])-$index.png"),$true);$cell.Dispose();$index++
 }}};$sheet.Dispose()
}
$sheet=[Drawing.Bitmap]::new((Join-Path $root 'sources/slash.png'))
foreach($row in 0..2){foreach($column in 0..3){
 $cell=[MasterAtlas]::Cell($sheet,$column,$row,4,3);[MasterAtlas]::Clean($cell,3,$false)
 [MasterAtlas]::Resize($cell,256,256,(Join-Path $root "frames/slash-$($row+1)-$column.png"));$cell.Dispose()
}};$sheet.Dispose()
Write-Output 'New master world, skeleton and slash PNG frames prepared.'
