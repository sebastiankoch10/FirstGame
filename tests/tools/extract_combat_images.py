"""Re-extract native framebuffer captures from an existing smoke log without rerunning the game."""
from pathlib import Path
import base64, re, struct, sys, zlib

def extract(folder):
 folder=Path(folder)
 def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
 for match in re.finditer(r'GAMEPLAY_IMAGE ([a-z-]+) ([A-Za-z0-9+/=]+)',(folder/'runtime.log').read_text(encoding='utf-8',errors='replace')):
  data=zlib.decompress(base64.b64decode(match.group(2)))
  assert len(data)==800*600*4
  scan=b''.join(b'\0'+data[y*800*4:(y+1)*800*4] for y in range(600))
  png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',800,600,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(scan))+chunk(b'IEND',b'')
  (folder/(match.group(1)+'-800.png')).write_bytes(png)

if __name__=='__main__':extract(sys.argv[1])
