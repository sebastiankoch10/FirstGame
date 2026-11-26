"""Development Review Center: project registry, approval sync and game data generation (Claude Code and Codex).

The single source of truth for review scenarios is review/registry.json in the project. The game cannot write into the
project folder (GameMaker file sandbox): it reads the registry from the generated script review_registry_data and writes
the user's approvals into its save folder, %LOCALAPPDATA%\\FirstGame\\review_approvals.json plus the append-only log
review_approvals.log. This tool imports those approvals into the registry.

  python tests/tools/review/review.py status            open / approved / processed entries and unread approvals
  python tests/tools/review/review.py sync              import approvals (idempotent), mark them processed, regenerate
  python tests/tools/review/review.py build             validate the registry and regenerate the GML data script
  python tests/tools/review/review.py bump ID --reason "..."   new revision after a substantial change (re-review)
  python tests/tools/review/review.py check             validation only (exit 1 on errors)

Options: --registry PATH, --save-dir PATH, --out PATH (GML), --include-test (only for technical tests on a registry copy).
Personal approvals come exclusively from the user's click in the game. Agents never write approvals.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REGISTRY = ROOT / 'review' / 'registry.json'
OUT = ROOT / 'scripts' / 'review_registry_data' / 'review_registry_data.gml'
SAVE_DIR = Path(os.environ.get('LOCALAPPDATA', '')) / 'FirstGame'
STATUSES = ('pending', 'approved', 'processed', 'superseded', 'rejected')
DECISION_TEXT = {'keep': 'so behalten', 'remove': 'KOMPLETT WEG', 'change': 'ANDERS UMSETZEN'}
TYPES = ('boss', 'scene', 'showroom')
REQUIRED = ('id', 'title', 'category', 'content', 'goal', 'task', 'revision', 'status', 'created', 'scenario')


def now() -> str:
    return dt.datetime.now().replace(microsecond=0).isoformat()


def load_registry(path: Path) -> dict:
    return json.loads(path.read_text(encoding='utf-8'))


def save_atomic(path: Path, text: str, backup: bool = True) -> None:
    """Write via a temp file and os.replace; the previous version stays as .bak (no partial files, no silent loss)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if backup and path.exists():
        shutil.copy2(path, path.with_suffix(path.suffix + '.bak'))
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(text, encoding='utf-8', newline='\n')
    os.replace(tmp, path)


def validate(reg: dict) -> list[str]:
    errors, seen = [], set()
    for i, e in enumerate(reg.get('entries', [])):
        where = e.get('id', f'#{i}')
        for k in REQUIRED:
            if k not in e:
                errors.append(f'{where}: field "{k}" missing')
        if e.get('id') in seen:
            errors.append(f'{where}: duplicate id')
        seen.add(e.get('id'))
        if e.get('status') not in STATUSES:
            errors.append(f'{where}: status must be one of {STATUSES}')
        s = e.get('scenario', {})
        if s.get('type') not in TYPES:
            errors.append(f'{where}: scenario.type must be one of {TYPES}')
        if s.get('type') == 'boss' and not s.get('boss'):
            errors.append(f'{where}: boss scenario needs "boss"')
        if not isinstance(e.get('revision'), int) or e['revision'] < 1:
            errors.append(f'{where}: revision must be an integer >= 1')
        if "'" in json.dumps(game_entry(e), ensure_ascii=False):
            errors.append(f"{where}: no apostrophes (') allowed outside the history; the GML data uses a verbatim '...' string")
    return errors


def read_approvals(save_dir: Path) -> list[dict]:
    """Union of review_approvals.json and the append-only review_approvals.log, keyed by uid."""
    found: dict[str, dict] = {}
    j = save_dir / 'review_approvals.json'
    if j.exists():
        try:
            for a in json.loads(j.read_text(encoding='utf-8', errors='replace')).get('approvals', []):
                found[a.get('uid', '')] = a
        except json.JSONDecodeError:
            print(f'WARNUNG: {j} ist beschaedigt; es zaehlt das Protokoll review_approvals.log.')
    log = save_dir / 'review_approvals.log'
    if log.exists():
        for line in log.read_text(encoding='utf-8', errors='replace').splitlines():
            line = line.strip()
            if line:
                try:
                    a = json.loads(line)
                    found.setdefault(a.get('uid', ''), a)
                except json.JSONDecodeError:
                    pass
    return [a for uid, a in found.items() if uid]


HISTORY_KEYS = ('approvals', 'revisions', 'feedback')


def game_entry(e: dict) -> dict:
    """The part of an entry the game needs. History and the user's comments stay in the registry only: the game reads
    verdicts and comments from its own save file, and free text may contain apostrophes, which a GML verbatim string
    cannot hold."""
    return {k: v for k, v in e.items() if k not in HISTORY_KEYS}


def gml_data(reg: dict) -> str:
    # Compact JSON inside a GML verbatim string; parsed once per run (review_entries caches it).
    payload = json.dumps([game_entry(e) for e in reg['entries']], ensure_ascii=True, separators=(',', ':'))
    return ('/// GENERATED by tests/tools/review/review.py from review/registry.json - do not edit by hand.\n'
            '/// Agents register scenarios in review/registry.json and run: python tests/tools/review/review.py build\n'
            'function review_registry_data() {\n'
            f"    return json_parse(@'{payload}');\n"
            '}\n')


def build(reg: dict, out: Path) -> None:
    errors = validate(reg)
    if errors:
        print('\n'.join('FEHLER ' + e for e in errors))
        raise SystemExit(1)
    save_atomic(out, gml_data(reg), backup=False)  # generated: no backup next to the GameMaker script


def sync(reg: dict, save_dir: Path, include_test: bool) -> tuple[list[str], list[str], list[str]]:
    """Import the user's verdicts from the game (since 26.11.: "Gut" or "Nicht gut", each with an optional comment):
    - good (or an old record without verdict): current revision -> approved -> processed; the comment is kept and shown.
    - bad: current revision -> status rejected, with decision (remove = take it out, change = do it differently) and comment.
    The latest verdict for a revision wins (the user may change their mind). Older revisions are recorded as superseded.
    Every record uid is processed exactly once (stored in the entry's approvals list)."""
    by_id = {e['id']: e for e in reg['entries']}
    processed, rejected, notes = [], [], []
    for a in sorted(read_approvals(save_dir), key=lambda x: x.get('at') or x.get('approved_at', '')):
        if a.get('test') and not include_test:
            notes.append(f"Testfreigabe ignoriert: {a.get('id')} ({a.get('uid')})")
            continue
        e = by_id.get(a.get('id'))
        if e is None:
            notes.append(f"Freigabe fuer unbekannte ID {a.get('id')} ({a.get('uid')}) - nicht verarbeitet, bleibt in der Datei")
            continue
        history = e.setdefault('approvals', [])
        if any(h.get('uid') == a['uid'] for h in history):
            continue  # already processed in an earlier sync
        verdict, decision, comment = a.get('verdict', 'good'), a.get('decision', 'keep'), (a.get('comment') or '').strip()
        at = a.get('at') or a.get('approved_at')
        rec = {'uid': a['uid'], 'revision': a.get('revision'), 'approved_at': at, 'source': a.get('source'),
               'test': bool(a.get('test')), 'imported_at': now(), 'verdict': verdict, 'decision': decision, 'comment': comment}
        if a.get('revision') == e['revision'] and e['status'] in ('pending', 'approved', 'processed', 'rejected'):
            say = f' | Kommentar: "{comment}"' if comment else ''
            if verdict == 'bad':
                e['status'] = 'rejected'
                e['rejected_at'] = at
                e['feedback'] = {'verdict': 'bad', 'decision': decision, 'comment': comment, 'revision': e['revision'], 'at': at}
                e.pop('processed_at', None)
                rec['result'] = 'rejected'
                history.append(rec)
                rejected.append(f"{e['id']} Rev. {e['revision']}: {e['title']} -> NICHT GUT, {DECISION_TEXT.get(decision, decision)}{say}")
            else:
                e['status'] = 'approved'
                e['approved_at'] = at
                rec['result'] = 'approved'
                history.append(rec)
                # Processing = the approval is now the binding quality reference for this revision (AGENTS.md, Review-Workflow).
                e['status'] = 'processed'
                e['processed_at'] = now()
                e['feedback'] = {'verdict': 'good', 'decision': 'keep', 'comment': comment, 'revision': e['revision'], 'at': at}
                rec['result'] = 'processed'
                processed.append(f"{e['id']} Rev. {e['revision']}: {e['title']} (freigegeben {at}){say}")
        else:
            rec['result'] = 'superseded' if a.get('revision') != e['revision'] else 'duplicate'
            history.append(rec)
            notes.append(f"{e['id']}: Urteil fuer Rev. {a.get('revision')}, aktuell Rev. {e['revision']} -> {rec['result']}, nicht uebertragen")
    return processed, rejected, notes


def bump(reg: dict, rid: str, reason: str) -> str:
    e = next((x for x in reg['entries'] if x['id'] == rid), None)
    if e is None:
        raise SystemExit(f'Unbekannte ID {rid}')
    for h in e.get('approvals', []):
        if h.get('revision') == e['revision'] and h.get('result') in ('approved', 'processed'):
            h['superseded_by'] = e['revision'] + 1
    e.setdefault('revisions', []).append({'revision': e['revision'], 'status': e['status'], 'until': now(), 'reason': reason})
    if e.get('feedback'):
        e['revisions'][-1]['feedback'] = e.pop('feedback')  # the user's verdict and comment belong to the old revision
    if e['status'] in ('approved', 'processed'):
        e['revisions'][-1]['status'] = 'superseded'
    e['revision'] += 1
    e['status'] = 'pending'
    e['approved_at'] = None
    e.pop('processed_at', None)
    return f"{rid}: jetzt Rev. {e['revision']} (offen). Grund: {reason}"


def status(reg: dict, save_dir: Path) -> None:
    approvals = read_approvals(save_dir)
    seen = {h['uid'] for e in reg['entries'] for h in e.get('approvals', [])}
    unread = [a for a in approvals if a.get('uid') not in seen and not a.get('test')]
    groups = {s: [e for e in reg['entries'] if e['status'] == s] for s in STATUSES}
    print(f"Review-Registry: {len(reg['entries'])} Eintraege | offen {len(groups['pending'])} | freigegeben {len(groups['approved'])} | "
          f"verarbeitet {len(groups['processed'])} | nicht gut {len(groups['rejected'])} | ersetzt {len(groups['superseded'])}")
    print(f"Speicherort der Urteile: {save_dir} | neue, noch nicht synchronisierte Urteile: {len(unread)}")
    for a in unread:
        print(f"  NEU: {a.get('id')} Rev. {a.get('revision')} ({'nicht gut' if a.get('verdict') == 'bad' else 'gut'}) am {a.get('at') or a.get('approved_at')}  -> python tests/tools/review/review.py sync")
    # The user's comments are work orders: "Nicht gut" always, "Gut" when a wish is attached (e.g. "genau so, nur schneller").
    for e in groups['rejected']:
        fb = e.get('feedback') or {}
        print(f"  NICHT GUT: {e['id']} Rev. {e['revision']} - {DECISION_TEXT.get(fb.get('decision'), fb.get('decision'))}: \"{fb.get('comment', '')}\"")
    for e in groups['processed']:
        fb = e.get('feedback') or {}
        if fb.get('comment'):
            print(f"  GUT MIT WUNSCH: {e['id']} Rev. {e['revision']}: \"{fb['comment']}\"")
    for e in groups['pending']:
        print(f"  offen: {e['id']} Rev. {e['revision']} - {e['title']}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('cmd', choices=['status', 'sync', 'build', 'bump', 'check'])
    ap.add_argument('id', nargs='?')
    ap.add_argument('--reason', default='')
    ap.add_argument('--registry', type=Path, default=REGISTRY)
    ap.add_argument('--save-dir', type=Path, default=SAVE_DIR)
    ap.add_argument('--out', type=Path, default=OUT)
    ap.add_argument('--include-test', action='store_true', help='only for technical tests on a registry copy')
    ap.add_argument('--brief', action='store_true')
    args = ap.parse_args()
    if args.include_test and args.registry.resolve() == REGISTRY.resolve():
        raise SystemExit('--include-test ist nur mit einer Registry-Kopie (--registry) erlaubt; Testfreigaben duerfen das Projekt nie erreichen.')
    reg = load_registry(args.registry)
    if args.cmd == 'check':
        errors = validate(reg)
        print('\n'.join('FEHLER ' + e for e in errors) or f'OK: {len(reg["entries"])} Eintraege gueltig')
        raise SystemExit(1 if errors else 0)
    if args.cmd == 'status':
        status(reg, args.save_dir)
        return
    if args.cmd == 'build':
        build(reg, args.out)
        print(f'OK: {args.out} aus {len(reg["entries"])} Eintraegen erzeugt')
        return
    if args.cmd == 'bump':
        if not args.id or not args.reason:
            raise SystemExit('bump braucht ID und --reason')
        msg = bump(reg, args.id, args.reason)
        save_atomic(args.registry, json.dumps(reg, indent=2, ensure_ascii=False) + '\n')
        build(reg, args.out)
        print(msg)
        return
    before = json.dumps(reg, sort_keys=True)
    processed, rejected, notes = sync(reg, args.save_dir, args.include_test)
    if json.dumps(reg, sort_keys=True) != before:  # something was imported (processed, rejected or recorded as superseded)
        save_atomic(args.registry, json.dumps(reg, indent=2, ensure_ascii=False) + '\n')
        build(reg, args.out)
    if processed:
        print('Neu verarbeitete persoenliche Freigaben (jetzt verbindliche Qualitaetsreferenz; Kommentare sind Wuensche, siehe AGENTS.md):')
        print('\n'.join('  ' + p for p in processed))
    if rejected:
        print('Neu als NICHT GUT bewertet (Arbeitsauftrag: komplett weg oder anders umsetzen, siehe AGENTS.md):')
        print('\n'.join('  ' + p for p in rejected))
    if not processed and not rejected and not args.brief:
        print('Keine neuen persoenlichen Urteile.')
    for n in notes:
        if not args.brief or 'Testfreigabe' not in n:
            print('  Hinweis: ' + n)
    if not args.brief:
        status(reg, args.save_dir)
    else:
        open_n = sum(1 for e in reg['entries'] if e['status'] == 'pending')
        print(f"Review-Center: {open_n} offen, {sum(1 for e in reg['entries'] if e['status'] == 'processed')} freigegeben und verarbeitet, "
              f"{sum(1 for e in reg['entries'] if e['status'] == 'rejected')} nicht gut"
              f"{' | NEU verarbeitet: ' + str(len(processed)) if processed else ''}{' | NEU nicht gut: ' + str(len(rejected)) if rejected else ''}"
              f" (Details und Kommentare: python tests/tools/review/review.py status)")


if __name__ == '__main__':
    main()
