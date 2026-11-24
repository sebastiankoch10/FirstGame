"""Which cells have a detected weapon? python coverage.py actor"""
import sys
from atlas import Atlas, SETS, DIRS
from segment import segment, WEAPON
actor = sys.argv[1]
miss = []; n = 0
for src in ['walk', 'combat', 'mobility', 'reaction']:
    a = Atlas(actor, src)
    cols = sorted({c for v in SETS[actor][src].values() for c in v})
    for row in range(8):
        for col in cols:
            sg = segment(actor, a.cell(col, row).rgba); n += 1
            if not (sg.labels == WEAPON).any(): miss.append(f'{src[:3]}{col}r{row}')
print(f'{actor}: weapon in {n - len(miss)}/{n} cells; none in:', ' '.join(miss))
