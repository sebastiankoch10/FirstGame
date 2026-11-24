# Mechanical extraction of the newly generated atlases. Concept boards and old sprites remain untouched.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Drawing.Drawing2D;using System.Collections.Generic;
public static class BossV2Atlas {
 public static int[] Cuts(Bitmap b,int count,bool vertical,int threshold){
  int length=vertical?b.Height:b.Width,other=vertical?b.Width:b.Height;var density=new int[length];var cuts=new int[count+1];cuts[count]=length;
  for(int p=0;p<length;p++)for(int q=0;q<other;q++)if(b.GetPixel(vertical?q:p,vertical?p:q).A>=threshold)density[p]++;
  for(int i=1;i<count;i++){int centre=(int)Math.Round(i*length/(double)count),rad=(int)(length/(double)count*.18),lo=Math.Max(cuts[i-1]+1,centre-rad),hi=Math.Min(length-2,centre+rad),best=centre,min=int.MaxValue;
   for(int p=lo;p<=hi;p++)if(density[p]<min || (density[p]==min&&Math.Abs(p-centre)<Math.Abs(best-centre))){best=p;min=density[p];}cuts[i]=best;
  }return cuts;
 }
 public static Bitmap Cell(Bitmap sheet,int[] xs,int[] ys,int col,int row,bool actor){
  var cell=sheet.Clone(Rectangle.FromLTRB(xs[col],ys[row],xs[col+1],ys[row+1]),PixelFormat.Format32bppArgb);int cutoff=actor?180:96;
  for(int y=0;y<cell.Height;y++)for(int x=0;x<cell.Width;x++){var c=cell.GetPixel(x,y);if(c.A<cutoff)cell.SetPixel(x,y,Color.Transparent);else if(actor)cell.SetPixel(x,y,Color.FromArgb(255,c.R,c.G,c.B));}
  if(actor){var visited=new bool[cell.Width,cell.Height];var components=new List<List<Point>>();int largest=0;
   for(int y=0;y<cell.Height;y++)for(int x=0;x<cell.Width;x++)if(!visited[x,y]&&cell.GetPixel(x,y).A>0){var component=new List<Point>();var queue=new Queue<Point>();queue.Enqueue(new Point(x,y));visited[x,y]=true;
    while(queue.Count>0){var p=queue.Dequeue();component.Add(p);for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int nx=p.X+dx,ny=p.Y+dy;if(nx>=0&&nx<cell.Width&&ny>=0&&ny<cell.Height&&!visited[nx,ny]&&cell.GetPixel(nx,ny).A>0){visited[nx,ny]=true;queue.Enqueue(new Point(nx,ny));}}}
    largest=Math.Max(largest,component.Count);components.Add(component);
   }
   foreach(var component in components)if(component.Count<Math.Max(4,largest*.008))foreach(var p in component)cell.SetPixel(p.X,p.Y,Color.Transparent);
  }return cell;
 }
 public static Rectangle Bounds(Bitmap b){int l=b.Width,t=b.Height,r=-1,d=-1;for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++)if(b.GetPixel(x,y).A>0){l=Math.Min(l,x);r=Math.Max(r,x);t=Math.Min(t,y);d=Math.Max(d,y);}if(r<0)throw new Exception("Empty atlas frame");return Rectangle.FromLTRB(l,t,r+1,d+1);}
 public static string Extract(string input,string output,int cols,int rows,int size,int foot,int figureHeight,bool actor){
  using(var sheet=new Bitmap(input)){var xs=Cuts(sheet,cols,false,actor?180:96);var ys=Cuts(sheet,rows,true,actor?180:96);var cells=new List<Bitmap>();var heights=new List<int>();
   for(int row=0;row<rows;row++)for(int col=0;col<cols;col++){var cell=Cell(sheet,xs,ys,col,row,actor);cells.Add(cell);if(actor&&(rows==1||row<rows-1))heights.Add(Bounds(cell).Height);}
   double factor=1;if(actor){heights.Sort();factor=figureHeight/(double)heights[heights.Count/2];foreach(var cell in cells){var bounds=Bounds(cell);factor=Math.Min(factor,Math.Min((size-6)/(double)bounds.Width,(foot-3)/(double)bounds.Height));}}
   for(int row=0;row<rows;row++)for(int col=0;col<cols;col++){var cell=cells[row*cols+col];using(var dst=new Bitmap(size,size,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(dst)){
    g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
    if(actor){var bounds=Bounds(cell);int w=(int)Math.Round(bounds.Width*factor),h=(int)Math.Round(bounds.Height*factor);g.DrawImage(cell,new Rectangle((size-w)/2,foot-h,w,h),bounds,GraphicsUnit.Pixel);}
    else g.DrawImage(cell,new Rectangle(0,0,size,size),new Rectangle(0,0,cell.Width,cell.Height),GraphicsUnit.Pixel);
    dst.Save(System.IO.Path.Combine(output,row+"-"+col+".png"),ImageFormat.Png);
   }cell.Dispose();}
   return "source="+sheet.Width+"x"+sheet.Height+";columns="+String.Join(",",xs)+";rows="+String.Join(",",ys)+";scale="+factor;
  }
 }
}
'@
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/boss_v2'))
$definitions=@(
 @{name='fire';cols=4;rows=8;size=128;foot=116;height=90;actor=$true},
 @{name='ice';cols=4;rows=8;size=128;foot=116;height=90;actor=$true},
 @{name='behemoth_life';cols=4;rows=4;size=512;foot=480;height=430;actor=$true},
 @{name='behemoth_attacks';cols=4;rows=8;size=512;foot=480;height=430;actor=$true},
 @{name='twins_fx';cols=4;rows=9;size=256;foot=128;height=0;actor=$false},
 @{name='swamp_fx';cols=4;rows=9;size=256;foot=128;height=0;actor=$false},
 @{name='brood';cols=4;rows=1;size=96;foot=88;height=50;actor=$true},
 @{name='projectiles';cols=4;rows=2;size=128;foot=64;height=0;actor=$false}
)
$report=@()
foreach($d in $definitions){
 $dest=Join-Path $artRoot "frames/$($d.name)";New-Item -ItemType Directory -Force $dest | Out-Null
 $result=[BossV2Atlas]::Extract((Join-Path $artRoot "sources/$($d.name).png"),$dest,$d.cols,$d.rows,$d.size,$d.foot,$d.height,$d.actor)
 $report+=@{source=$d.name;columns=$d.cols;rows=$d.rows;frames=$d.cols*$d.rows;canvas=$d.size;actor=$d.actor;extraction=$result}
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $artRoot 'extraction.json')
Write-Output 'Prepared actual new boss, projectile and VFX frames; see extraction.json.'
