param([Parameter(Mandatory=$true)][string]$Manifest)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class VisualPixels {
 public static int[] Inspect(string path) {
  using(var original=new Bitmap(path))using(var b=new Bitmap(original.Width,original.Height,PixelFormat.Format32bppArgb)){
   using(var g=Graphics.FromImage(b)){g.DrawImageUnscaled(original,0,0);}
   var data=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
   byte[] p=new byte[Math.Abs(data.Stride)*b.Height];Marshal.Copy(data.Scan0,p,0,p.Length);b.UnlockBits(data);
   int nonzero=0,solid=0,partial=0,left=b.Width,top=b.Height,right=-1,bottom=-1,edge=0,whiteEdge=0,corner=0;
   for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){
    int i=y*Math.Abs(data.Stride)+x*4,a=p[i+3];if(a==0)continue;
    nonzero++;if(a==255)solid++;else partial++;
    left=Math.Min(left,x);top=Math.Min(top,y);right=Math.Max(right,x);bottom=Math.Max(bottom,y);
    if(x==0 || y==0 || x==b.Width-1 || y==b.Height-1){edge++;if(p[i]>225&&p[i+1]>225&&p[i+2]>225)whiteEdge++;}
    if((x==0||x==b.Width-1)&&(y==0||y==b.Height-1))corner++;
   }
   return new int[]{b.Width,b.Height,nonzero,solid,partial,left,top,right,bottom,edge,whiteEdge,corner};
  }
 }
 public static void Contact(string[] paths,string[] labels,string target,int columns,int cellWidth,int cellHeight,string heading) {
  int rows=(paths.Length+columns-1)/columns;
  using(var output=new Bitmap(columns*cellWidth,rows*cellHeight+36))using(var g=Graphics.FromImage(output))using(var font=new Font("Consolas",8))using(var title=new Font("Consolas",11)){
   g.Clear(Color.FromArgb(12,18,27));g.InterpolationMode=InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
   g.DrawString(heading,title,Brushes.Gainsboro,new PointF(8,8));
   for(int n=0;n<paths.Length;n++){
    int x=(n%columns)*cellWidth,y=(n/columns)*cellHeight+36,imageH=cellHeight-30;
    for(int yy=0;yy<imageH;yy+=12)for(int xx=0;xx<cellWidth;xx+=12)g.FillRectangle(((xx/12+yy/12)%2)==0?Brushes.DarkSlateGray:Brushes.Black,x+xx,y+yy,12,12);
    using(var b=new Bitmap(paths[n])){
     float scale=Math.Min((cellWidth-8f)/b.Width,(imageH-8f)/b.Height);
     g.DrawImage(b,new RectangleF(x+(cellWidth-b.Width*scale)/2,y+(imageH-b.Height*scale)/2,b.Width*scale,b.Height*scale),new RectangleF(0,0,b.Width,b.Height),GraphicsUnit.Pixel);
    }
    g.FillRectangle(Brushes.Black,x,y+imageH,cellWidth,30);
    g.DrawString(labels[n],font,Brushes.Gainsboro,new RectangleF(x+2,y+imageH+1,cellWidth-4,29));
   }
   output.Save(target,ImageFormat.Png);
  }
 }
}
'@
$data=Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
$measurements=foreach($frame in $data.frames){
 try{[PSCustomObject]@{key=$frame.key;metrics=[VisualPixels]::Inspect($frame.path);error=$null}}
 catch{[PSCustomObject]@{key=$frame.key;metrics=$null;error=$_.Exception.Message}}
}
$measurements | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $data.pixel_result -Encoding UTF8
foreach($sheet in $data.sheets){
 [VisualPixels]::Contact([string[]]$sheet.paths,[string[]]$sheet.labels,$sheet.target,8,144,154,$sheet.heading)
}
Write-Output "Inspected $(@($measurements).Count) registered PNG frames; wrote $(@($data.sheets).Count) contact sheets."
