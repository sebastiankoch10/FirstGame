"""Build one self-contained Markdown snapshot of the binding design canon (docs/Design/*).

  python tests/tools/export_design.py            -> docs/_export/Designphilosophie_<YYYY-MM-DD>.md

The export is a read-only snapshot for reading and discussing outside the project. It is NOT a
source of truth; edit docs/Design/* and regenerate. Obsidian links [[X]] become plain text.
"""
from __future__ import annotations

import datetime
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DESIGN = ROOT / 'docs' / 'Design'
ORDER = ['Leitbild', 'Kampf & Begegnungen', 'Boss-Design', 'Klassen', 'Progression & Builds', 'Visuelles Leitbild & Animation',
         'Fähigkeiten, VFX & Audio', 'Technische Architektur', 'Assets & Pipeline', 'Qualitätsstandard', 'Roadmap & Vertical Slice']


def body(name: str) -> str:
    text = (DESIGN / f'{name}.md').read_text(encoding='utf-8-sig')
    text = re.sub(r'\A---\n.*?\n---\n', '', text, flags=re.S)                     # frontmatter
    text = re.sub(r'\[\[([^\]|]+)\|([^\]]+)\]\]', r'\2', text)                       # [[a|b]] -> b
    text = re.sub(r'\[\[([^\]]+)\]\]', r'„\1“', text)                                # [[a]] -> „a“
    out, fence = [], False
    for line in text.splitlines():
        if line.lstrip().startswith('```'):
            fence = not fence
        if not fence and re.match(r'^#{1,5} ', line):
            line = '#' + line                                                      # each doc becomes a chapter
        out.append(line)
    return '\n'.join(out).strip() + '\n'


def main() -> int:
    missing = [n for n in ORDER if not (DESIGN / f'{n}.md').is_file()]
    extra = sorted(p.stem for p in DESIGN.glob('*.md') if p.stem not in ORDER)
    if missing:
        print('missing:', missing); return 1
    today = datetime.date.today().isoformat()
    # Frontmatter like every note in the vault (tags, updated); the title follows.
    front = f'---\ntags: [export, design, momentaufnahme]\nupdated: {today}\n---'
    parts = [front, f'# FirstGame – Designphilosophie (konsolidierter Export, Stand {today})\n',
             '> **Momentaufnahme, nicht verbindlich.** Maßgeblich sind die einzelnen Dateien unter `docs/Design/` '
             '(Vorrang: Leitbild). Dieser Text wurde mit `python tests/tools/export_design.py` erzeugt und wird bei Änderungen '
             'neu erzeugt, nicht von Hand bearbeitet. Verweise in „Anführungszeichen“ nennen Dokumente des Kanons '
             'bzw. Systemnotizen unter `docs/Systeme/`.\n',
             '## Inhalt\n' + '\n'.join(f'{i + 1}. {n}' for i, n in enumerate(ORDER)) + '\n']
    for i, n in enumerate(ORDER):
        b = body(n)
        b = re.sub(r'\A## ', f'## {i + 1}. ', b, count=1)
        parts.append('---\n\n' + b)
    out = ROOT / 'docs' / '_export' / f'Designphilosophie_{today}.md'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text('\n'.join(parts), encoding='utf-8')
    # keep the vault index pointing at the newest snapshot (older snapshots stay in _export/)
    idx = ROOT / 'docs' / '00_Index.md'
    it = idx.read_text(encoding='utf-8-sig')
    new = re.sub('Designphilosophie_[0-9]{4}-[0-9]{2}-[0-9]{2}', out.stem, it)
    if new != it:
        idx.write_text(new, encoding='utf-8')
    print(f'{out.relative_to(ROOT)}: {out.stat().st_size // 1024} KB, {len(ORDER)} Dokumente' + (f'; nicht im Export: {extra}' if extra else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
