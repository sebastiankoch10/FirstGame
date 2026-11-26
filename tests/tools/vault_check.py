"""Fast static documentation and project-hygiene checks (seconds, no build, no AI): suite "docs" of tests/tools/qa.py.

  python tests/tools/vault_check.py            all checks, exit 1 on a failure
  python tests/tools/vault_check.py --since REF also warn about changed scripts whose system notes were not touched

Checks:
  1. Every note under docs/ (except .obsidian) has frontmatter with tags and updated.
  2. No broken [[wiki links]]; every note is reachable from docs/00_Index.md.
  3. Every script, object and room is mentioned in at least one note in docs/Systeme/.
  4. review/registry.json is valid (review.py check).
  5. IDE resource tree is sorted (ide_folders.py --check: nothing to move, nothing unmatched).
  6. Source art paths only come from the table (art_paths.py --check).
Warnings (never fail): changed scripts whose system notes are unchanged in the same diff.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / 'docs'
LINK = re.compile(r'\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]')


def notes() -> dict[str, Path]:
    return {p.stem: p for p in DOCS.rglob('*.md') if '.obsidian' not in p.parts}


def run(args: list[str]) -> tuple[int, str]:
    r = subprocess.run([sys.executable, *args], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
    return r.returncode, (r.stdout + r.stderr).strip()


def main() -> int:
    fails, warns = [], []
    ns = notes(); text = {k: p.read_text(encoding='utf-8-sig') for k, p in ns.items()}
    index_links: set[str] = set()
    for name, t in text.items():
        fm = t.split('---', 2)[1] if t.startswith('---') else ''
        if 'tags:' not in fm or not re.search(r'updated:\s*\S+', fm):
            fails.append(f'Frontmatter (tags, updated) fehlt: {ns[name].relative_to(ROOT)}')
        links = {l.strip() for l in LINK.findall(t)}
        for l in sorted(links):
            if l not in ns:
                fails.append(f'Kaputter Link [[{l}]] in {ns[name].relative_to(ROOT)}')
        if name == '00_Index':
            index_links = links
    for name in sorted(ns):
        if name != '00_Index' and name not in index_links and '_export' not in ns[name].parts:  # only the newest snapshot is linked
            fails.append(f'Nicht im Index verlinkt: {ns[name].relative_to(ROOT)}')
    sysdir = DOCS / 'Systeme'
    systext = '\n'.join(p.read_text(encoding='utf-8-sig') for p in sysdir.glob('*.md'))
    for kind in ('scripts', 'objects', 'rooms'):
        for d in sorted(p.name for p in (ROOT / kind).iterdir() if p.is_dir()):
            if not re.search(r'(?<![A-Za-z0-9_])' + re.escape(d) + r'(?![A-Za-z0-9_])', systext):
                fails.append(f'{kind}/{d} steht in keiner Systemnotiz (docs/Systeme)')
    code, out = run(['tests/tools/review/review.py', 'check'])
    if code:
        fails.append('review.py check: ' + out[-300:])
    code, out = run(['tests/tools/assets/ide_folders.py', '--check'])
    m = re.search(r'would move (\d+); unmatched (\d+)', out)
    if code or not m or int(m.group(1)) or int(m.group(2)):
        fails.append('ide_folders.py --check: ' + (m.group(0) if m else out[-200:]) + '  (einsortieren: ide_folders.py --apply; neue Praefixe als Regel ergaenzen)')
    code, out = run(['tests/tools/assets/art_paths.py', '--check'])
    if code:
        fails.append('art_paths.py --check: ' + out[-300:])
    if '--since' in sys.argv:
        ref = sys.argv[sys.argv.index('--since') + 1]
        diff = subprocess.run(['git', '-c', 'core.quotepath=false', 'diff', '--name-only', ref], cwd=ROOT, capture_output=True, text=True, encoding='utf-8').stdout.splitlines()
        changed_notes = {Path(p).stem for p in diff if p.startswith('docs/')}
        for p in diff:
            m2 = re.match(r'^scripts/([^/]+)/', p)
            if not m2:
                continue
            owners = [f.stem for f in sysdir.glob('*.md') if re.search(r'(?<![A-Za-z0-9_])' + re.escape(m2.group(1)) + r'(?![A-Za-z0-9_])', f.read_text(encoding='utf-8-sig'))]
            if owners and not (set(owners) & changed_notes):
                warns.append(f'scripts/{m2.group(1)} geaendert, Notiz unveraendert: {", ".join(owners[:3])} (nur aendern, wenn Dateien, Funktionen, Abhaengigkeiten oder Probleme betroffen sind)')
    for w in sorted(set(warns)):
        print('WARN ' + w)
    for f in fails:
        print('FAIL ' + f)
    print(f'DOCS {"FAIL" if fails else "PASS"}: {len(ns)} Notizen, {len(fails)} Fehler, {len(set(warns))} Hinweise')
    return 1 if fails else 0


if __name__ == '__main__':
    raise SystemExit(main())
