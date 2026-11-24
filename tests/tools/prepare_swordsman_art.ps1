# Mechanical atlas import only: grid crop, alpha cutoff and nearest-neighbour scaling.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Collections.Generic;
public static class SwordsmanAtlas {
 public static Bitmap Cell(Bitmap source,int column,int row) {
  int x=(int)Math.Round(column*source.Width/8.0),y=(int)Math.Round(row*source.Height/8.0);
  int right=(int)Math.Round((column+1)*source.Width/8.0),bottom=(int)Math.Round((row+1)*source.Height/8.0);
  var cell=source.Clone(Rectangle.FromLTRB(x,y,right,bottom),PixelFormat.Format32bppArgb);
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++) {
   Color c=cell.GetPixel(i,j);cell.SetPixel(i,j,c.A<128 ? Color.Transparent : Color.FromArgb(255,c.R,c.G,c.B));
  }
  // Keep the connected figure; discard isolated alpha specks / neighbouring tile fragments.
  bool[,] seen=new bool[cell.Width,cell.Height];var largest=new List<Point>();
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++)if(!seen[i,j]&&cell.GetPixel(i,j).A>0){
   var component=new List<Point>();var queue=new Queue<Point>();queue.Enqueue(new Point(i,j));seen[i,j]=true;
   while(queue.Count>0){var p=queue.Dequeue();component.Add(p);
    for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){
     int nx=p.X+dx,ny=p.Y+dy;if(nx>=0&&nx<cell.Width&&ny>=0&&ny<cell.Height&&!seen[nx,ny]&&cell.GetPixel(nx,ny).A>0){seen[nx,ny]=true;queue.Enqueue(new Point(nx,ny));}
    }
   }
   if(component.Count>largest.Count)largest=component;
  }
  var keep=new bool[cell.Width,cell.Height];foreach(var p in largest)keep[p.X,p.Y]=true;
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++)if(!keep[i,j])cell.SetPixel(i,j,Color.Transparent);
  return cell;
 }
 public static Rectangle Bounds(Bitmap b) {
  int l=b.Width,t=b.Height,r=-1,d=-1;
  for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++)if(b.GetPixel(x,y).A>0){l=Math.Min(l,x);t=Math.Min(t,y);r=Math.Max(r,x);d=Math.Max(d,y);}
  if(r<0)throw new Exception("Empty atlas cell");return Rectangle.FromLTRB(l,t,r+1,d+1);
 }
 public static void Save(Bitmap cell,double factor,string path) {
  var bounds=Bounds(cell);
  using(var result=new Bitmap(96,96,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(result)) {
   g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
   int w=(int)Math.Round(bounds.Width*factor),h=(int)Math.Round(bounds.Height*factor);
   int x=48+(int)Math.Round((bounds.Left-cell.Width/2.0)*factor),y=88-h;
   if(w>94||h>86||x<0||x+w>96)throw new Exception("Sprite would clip: "+path);
   g.DrawImage(cell,new Rectangle(x,y,w,h),bounds,GraphicsUnit.Pixel);result.Save(path,ImageFormat.Png);
  }
 }
}
'@
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/swordsman_v3'))
$dirs=@('right','up_right','up','up_left','left','down_left','down','down_right')
$walk=[Drawing.Bitmap]::new((Join-Path $root 'sources/walk.png'))
$reference=[SwordsmanAtlas]::Cell($walk,0,6)
$factor=52.0/[SwordsmanAtlas]::Bounds($reference).Height
$reference.Dispose()
$referenceCell=$walk.Height/8.0
$walk.Dispose()
$sets=@{
 walk=@{walk=@(0,1,2,3,4,5,6,7);run=@(0,1,2,3,4,5,6,7)}
 combat=@{idle=@(0);turn=@(0);attack1=@(1,2);attack2=@(3,4);attack3=@(5,6,7)}
 mobility=@{dodge=@(0,1,2,3);slide=@(0,1,2,3);jump=@(4,5,6);fall=@(5,6);dive=@(6);landing=@(7)}
 reaction=@{hurt=@(0,1,2);death=@(3,4,5,6,7)}
}
foreach($source in $sets.Keys){
 $sheet=[Drawing.Bitmap]::new((Join-Path $root "sources/$source.png"))
 $referenceColumn=@{walk=0;combat=0;mobility=3;reaction=2}[$source]
 $pose=[SwordsmanAtlas]::Cell($sheet,$referenceColumn,6)
 $scale=52.0/[SwordsmanAtlas]::Bounds($pose).Height
 $pose.Dispose()
 foreach($row in 0..7){foreach($action in $sets[$source].Keys){
  $index=0
  foreach($column in $sets[$source][$action]){
   $cell=[SwordsmanAtlas]::Cell($sheet,$column,$row)
   [SwordsmanAtlas]::Save($cell,$scale,(Join-Path $root "frames/$action-$($dirs[$row])-$index.png"))
   $cell.Dispose();$index++
  }
 }}
 $sheet.Dispose()
}
Write-Output 'Swordsman frames prepared with alpha and consistent scale.'
