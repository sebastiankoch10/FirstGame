# Mechanical import of generated animation atlases. No interpolation or invented frames.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Collections.Generic;
public static class ClassAtlas {
 public static int Rows=8;
 static int[] rowCuts;
 public static void Prepare(Bitmap source,int rows) {
  Rows=rows;rowCuts=new int[rows+1];rowCuts[rows]=source.Height;
  int[] density=new int[source.Height];
  for(int y=0;y<source.Height;y++)for(int x=0;x<source.Width;x++) {var c=source.GetPixel(x,y);int max=Math.Max(c.R,Math.Max(c.G,c.B)),min=Math.Min(c.R,Math.Min(c.G,c.B));if(c.A>=180&&max-min>30)density[y]++;}
  for(int i=1;i<rows;i++) {
   int centre=(int)Math.Round(i*source.Height/(double)rows),radius=(int)(source.Height/(double)rows*.43),lo=Math.Max(rowCuts[i-1]+20,centre-radius),hi=Math.Min(source.Height-2,centre+radius),min=int.MaxValue;
   for(int p=lo;p<=hi;p++)min=Math.Min(min,density[p]);int best=centre,bestScore=int.MaxValue;
   for(int p=lo;p<=hi;p++) {int score=density[p]*30+Math.Abs(p-centre);if(density[p]<=min+3&&score<bestScore){best=p;bestScore=score;}}
   rowCuts[i]=best;
  }
 }
 public static Bitmap Cell(Bitmap source,int column,int row) {
  int x=(int)Math.Round(column*source.Width/8.0),y=rowCuts[row];
  int right=(int)Math.Round((column+1)*source.Width/8.0),bottom=rowCuts[row+1];
  var cell=source.Clone(Rectangle.FromLTRB(x,y,right,bottom),PixelFormat.Format32bppArgb);
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++) {
   Color c=cell.GetPixel(i,j);cell.SetPixel(i,j,c.A<180 ? Color.Transparent : Color.FromArgb(255,c.R,c.G,c.B));
  }
  bool[,] seen=new bool[cell.Width,cell.Height];var largest=new List<Point>();var components=new List<List<Point>>();
  for(int j=0;j<cell.Height;j++)for(int i=0;i<cell.Width;i++)if(!seen[i,j]&&cell.GetPixel(i,j).A>0){
   var component=new List<Point>();var queue=new Queue<Point>();queue.Enqueue(new Point(i,j));seen[i,j]=true;
   while(queue.Count>0){var p=queue.Dequeue();component.Add(p);
    for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){
     int nx=p.X+dx,ny=p.Y+dy;if(nx>=0&&nx<cell.Width&&ny>=0&&ny<cell.Height&&!seen[nx,ny]&&cell.GetPixel(nx,ny).A>0){seen[nx,ny]=true;queue.Enqueue(new Point(nx,ny));}
    }
   }
   components.Add(component);if(component.Count>largest.Count)largest=component;
  }
  // No global grey removal: legitimate hair, armor and staff colours remain intact.
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
   int x=48-w/2,y=88-h;
   if(w>94||h>86||x<0||x+w>96)throw new Exception("Sprite would clip: "+path);
   g.DrawImage(cell,new Rectangle(x,y,w,h),bounds,GraphicsUnit.Pixel);result.Save(path,ImageFormat.Png);
  }
 }
}
'@
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../FirstGame_ArtPack/characters/class_overhaul'))
$dirs=@('right','up_right','up','up_left','left','down_left','down','down_right')
$manifest=@()
foreach($actor in @('mage','ranger')) {
 $dest=Join-Path $root "frames/$($actor)v3"
 New-Item -ItemType Directory -Force $dest | Out-Null
 $sets=@{
  walk=@{walk=@(0,1,2,3,4,5,6,7);run=@(0,1,2,3,4,5,6,7)}
  combat=@{idle=@(0);turn=@(0);attack1=@(0,1,2);attack2=@(3,4,5);attack3=@(4,5,7)}
  mobility=@{jump=@(0,1,2);fall=@(2,3);landing=@(4,0);dodge=@(5,6,7);slide=@(5,6,7);dive=@(3,5,6)}
  reaction=@{hurt=@(0,1,2);death=@(3,4,5,6,7)}
 }
 if($actor -eq 'mage') { $sets.combat.attack3=@(0,5,7);$sets.combat.attack4=@(0,6,7) }
 else { $sets.combat.attack1=@(1,2,3,4);$sets.combat.attack2=@(2,3,4,5);$sets.combat.attack3=@(0,6,7) }
 foreach($source in @('walk','combat','mobility','reaction')) {
  $sheet=[Drawing.Bitmap]::new((Join-Path $root "sources/$($actor)_$source.png"))
  [ClassAtlas]::Prepare($sheet, $(if($actor -eq 'ranger' -and $source -eq 'combat'){9}else{8}))
  $referenceColumn=@{walk=0;combat=0;mobility=2;reaction=2}[$source]
  $heights=@();$maxW=0;$maxH=0
  foreach($row in 0..7) {
   $pose=[ClassAtlas]::Cell($sheet,$referenceColumn,$row);$heights+=[ClassAtlas]::Bounds($pose).Height;$pose.Dispose()
   foreach($col in 0..7) { $cell=[ClassAtlas]::Cell($sheet,$col,$row);$bounds=[ClassAtlas]::Bounds($cell);$maxW=[Math]::Max($maxW,$bounds.Width);$maxH=[Math]::Max($maxH,$bounds.Height);$cell.Dispose() }
  }
  $ordered=@($heights | Sort-Object);$median=($ordered[3]+$ordered[4])/2.0
  $scale=[Math]::Min(52.0/$median,[Math]::Min(92.0/$maxW,84.0/$maxH))
  foreach($row in 0..7) {foreach($action in $sets[$source].Keys) {
   $index=0
   foreach($column in $sets[$source][$action]) {
    $cell=[ClassAtlas]::Cell($sheet,$column,$row)
    [ClassAtlas]::Save($cell,$scale,(Join-Path $dest "$action-$($dirs[$row])-$index.png"))
    $cell.Dispose();$index++
   }
  }}
  $manifest+=@{actor="$($actor)v3";source=$source;median_reference_height=$median;scale=$scale;max_source_width=$maxW;max_source_height=$maxH;actions=$sets[$source]}
  $sheet.Dispose()
 }
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 (Join-Path $root 'character-extraction.json')
Write-Output 'Prepared both eight-direction character frame sets; source files preserved.'
