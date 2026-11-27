"""End-to-end test of the Review Center workflow with TECHNICAL TEST approvals only.

  python tests/tools/review/review_e2e.py

Everything runs in an isolated copy named FirstGameReviewE2E (save folder %LOCALAPPDATA%\\FirstGameReviewE2E) with a
copy of review/registry.json plus three test entries (one, two: verdicts; three: withdrawn by the agent). The real save folder %LOCALAPPDATA%\\FirstGame and the project
registry are hashed before and after and must stay unchanged. Evidence (screenshots, logs, result JSON) stays in
%LOCALAPPDATA%\\FirstGame-Tests\\review-e2e\\<stamp>\\ ; the summary goes to tests/reports/review-e2e-result.json.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests' / 'tools'))
import run_native_harness as rn  # noqa: E402

NAME, PX, TAG = 'FirstGameReviewE2E', 'rv', 'REVIEW'
LOCAL = Path(os.environ['LOCALAPPDATA'])
TEST_SAVE = LOCAL / NAME
REAL_SAVE = LOCAL / 'FirstGame'
REVIEW = [sys.executable, str(ROOT / 'tests/tools/review/review.py')]


def tree_hash(path: Path) -> str:
    h = hashlib.sha256()
    if path.is_dir():
        for p in sorted(path.rglob('*')):
            if p.is_file():
                h.update(p.relative_to(path).as_posix().encode()); h.update(p.read_bytes())
    elif path.is_file():
        h.update(path.read_bytes())
    return h.hexdigest()


def test_entry(eid: str, cls: str) -> dict:
    return {'id': eid, 'title': f'TEST {eid} (technisch)', 'category': 'TEST (technisch)', 'content': 'Technischer Test des Freigabe-Ablaufs',
            'goal': 'Nur fuer den automatischen End-to-End-Test.', 'task': 'review_e2e.py', 'revision': 1, 'status': 'pending',
            'created': time.strftime('%Y-%m-%d'), 'approved_at': None, 'requested': 'E2E-Test (technisch), kein Nutzerauftrag',
            'scenario': {'type': 'boss', 'boss': 'storm_warden', 'minute': 15, 'class': cls, 'ability': 1, 'seed': 1337, 'build': 'balanced', 'gear': 2}}


def review(*args) -> str:
    r = subprocess.run(REVIEW + list(args), capture_output=True, text=True, encoding='utf-8', errors='replace')
    print(r.stdout.strip()[-1500:], r.stderr.strip()[-800:])
    if r.returncode:
        raise RuntimeError(f'review.py {args[0]} failed')
    return r.stdout


def main() -> None:
    checks, failures = [], []

    def check(ok, msg):
        checks.append(msg)
        if not ok:
            failures.append(msg); print('E2E FAIL', msg)

    real_before, reg_before = tree_hash(REAL_SAVE), tree_hash(ROOT / 'review' / 'registry.json')
    shutil.rmtree(TEST_SAVE, ignore_errors=True)
    work = LOCAL / 'FirstGame-Tests' / 'review-e2e' / time.strftime('%Y%m%d-%H%M%S')
    extra = [(r'review_center_draw\(\);exit;', 'review_center_draw();rv_menu_capture();exit;')]
    work, project = rn.prepare_copy('review-e2e', 'tests/review_harness.gml', PX, TAG, NAME, extra, work=work)
    p = project / 'objects/ObjectMainMenu/Draw_64.gml'
    p.write_text(p.read_text(encoding='utf-8') + '\nrv_menu_capture();\n', encoding='utf-8')
    reg = json.loads((ROOT / 'review/registry.json').read_text(encoding='utf-8'))
    reg['entries'] += [test_entry('test.e2e.one', 'Sword'), test_entry('test.e2e.two', 'Ranger'), test_entry('test.e2e.three', 'Mage')]
    # since 27.11. a new entry needs the explicit request of the user: check rejects one without "requested"
    bad = json.loads(json.dumps(reg)); bad['entries'][-1].pop('requested')
    bad_reg = work / 'registry-no-request.json'; bad_reg.write_text(json.dumps(bad, indent=2), encoding='utf-8')
    r = subprocess.run(REVIEW + ['check', '--registry', str(bad_reg)], capture_output=True, text=True, encoding='utf-8', errors='replace')
    check(r.returncode == 1 and 'requested' in r.stdout, 'check rejects a new entry without the request of the user')
    tmp_reg = work / 'registry-copy.json'
    tmp_reg.write_text(json.dumps(reg, indent=2), encoding='utf-8')
    data = project / 'scripts/review_registry_data/review_registry_data.gml'
    review('build', '--registry', str(tmp_reg), '--out', str(data))
    results = {}
    try:
        exe = rn.build_copy('review-e2e', work, project, NAME)
        for phase in ('a', 'b'):
            code, texts, started = rn.run_exe(work, exe, TAG, 600, log_name=f'phase-{phase}')
            res, exc, fails = rn.parse_result(texts, TAG)
            rn.collect_captures(work, PX, started)
            results[phase] = res or {'passed': False, 'failures': fails, 'error': 'no result'}
            check(bool(res) and res.get('passed') and code == 0 and not exc, f'phase {phase}: {res and res.get("failures")} exc={exc[:2]} exit={code}')
            if phase == 'a':
                recs = json.loads((TEST_SAVE / 'review_approvals.json').read_text(encoding='utf-8'))['approvals'] if (TEST_SAVE / 'review_approvals.json').exists() else []
                check(len(recs) == 2 and all(r.get('test') is True for r in recs), f'two technical test verdicts stored ({len(recs)})')
                by = {r.get('id'): r for r in recs}
                check(by.get('test.e2e.one', {}).get('verdict') == 'good' and by['test.e2e.one'].get('comment') == 'Genau so, nur etwas schneller und härter',
                      'verdict file: entry one good with its comment (umlaut kept)')
                check(by.get('test.e2e.two', {}).get('verdict') == 'bad' and by['test.e2e.two'].get('decision') == 'remove',
                      'verdict file: entry two not good, komplett weg')
                check((TEST_SAVE / 'review_approvals.log').exists(), 'append-only log exists')
                check(not (TEST_SAVE / 'firstgame_talents.ini').exists(), 'review session wrote no talent save')
        # agent side: read status, process (test approvals only on the registry copy), idempotence, revision bump
        out = review('status', '--registry', str(tmp_reg), '--save-dir', str(TEST_SAVE))
        check('Testfreigabe' not in out, 'status lists no test approvals as personal')
        out = review('sync', '--registry', str(tmp_reg), '--save-dir', str(TEST_SAVE), '--include-test', '--out', str(data))
        check('test.e2e.one' in out and 'test.e2e.two' in out, 'sync processed both test verdicts')
        check('nur etwas schneller' in out and 'KOMPLETT WEG' in out and 'Bitte komplett entfernen' in out, 'sync shows the comments and the decision to the agent')
        out2 = review('sync', '--registry', str(tmp_reg), '--save-dir', str(TEST_SAVE), '--include-test', '--out', str(data))
        check('Keine neuen' in out2, 'second sync processes nothing twice')
        reg2 = json.loads(tmp_reg.read_text(encoding='utf-8'))
        e1 = next(e for e in reg2['entries'] if e['id'] == 'test.e2e.one')
        e2 = next(e for e in reg2['entries'] if e['id'] == 'test.e2e.two')
        check(e1['status'] == 'processed' and len(e1.get('approvals', [])) == 1, 'registry copy: entry one processed exactly once')
        check(e1.get('feedback', {}).get('comment') == 'Genau so, nur etwas schneller und härter', 'registry copy: the wish of the good verdict is kept')
        check(e2['status'] == 'rejected' and e2.get('feedback', {}).get('decision') == 'remove', 'registry copy: entry two rejected, komplett weg')
        st = review('status', '--registry', str(tmp_reg), '--save-dir', str(TEST_SAVE))
        check('NICHT GUT: test.e2e.two' in st and 'GUT MIT WUNSCH: test.e2e.one' in st, 'status lists the work orders from the comments')
        out3 = review('sync', '--registry', str(tmp_reg), '--save-dir', str(TEST_SAVE), '--out', str(data))
        review('bump', 'test.e2e.two', '--reason', 'E2E: wesentliche Aenderung simuliert', '--request', 'E2E: simulierter Pruefwunsch',
               '--registry', str(tmp_reg), '--out', str(data))
        out4 = review('withdraw', 'test.e2e.three', '--reason', 'E2E: vom Agenten nach Design-Kanon entschieden', '--registry', str(tmp_reg), '--out', str(data))
        check('test.e2e.three' in out4 and 'Zurueckgezogen' in out4, 'withdraw reports the entry')
        review('bump', 'test.e2e.three', '--reason', 'E2E: Aenderung ohne Pruefwunsch', '--registry', str(tmp_reg), '--out', str(data))
        reg3 = json.loads(tmp_reg.read_text(encoding='utf-8'))
        e2b = next(e for e in reg3['entries'] if e['id'] == 'test.e2e.two')
        e3 = next(e for e in reg3['entries'] if e['id'] == 'test.e2e.three')
        check(e2b['status'] == 'pending' and e2b['revision'] == 2 and e2b.get('requested') == 'E2E: simulierter Pruefwunsch',
              'bump with the request of the user: new revision open again')
        check(e3['status'] == 'withdrawn' and e3['revision'] == 2 and e3.get('withdrawn', {}).get('by') == 'agent' and not e3.get('approvals'),
              'bump without request: new revision withdrawn (agent decision), no verdict written')
        st2 = review('status', '--registry', str(tmp_reg), '--save-dir', str(TEST_SAVE))
        n_wd = sum(1 for e in reg3['entries'] if e['status'] == 'withdrawn')  # real withdrawn entries plus test.e2e.three
        check(f'zurueckgezogen {n_wd} ' in st2, f'status counts the withdrawn entries ({n_wd})')
        exe = rn.build_copy('review-e2e', work, project, NAME)
        code, texts, started = rn.run_exe(work, exe, TAG, 600, log_name='phase-c')
        res, exc, fails = rn.parse_result(texts, TAG)
        rn.collect_captures(work, PX, started)
        results['c'] = res or {'passed': False, 'failures': fails, 'error': 'no result'}
        check(bool(res) and res.get('passed') and code == 0 and not exc, f'phase c: {res and res.get("failures")} exc={exc[:2]} exit={code}')
    finally:
        rn.cleanup(work)
    check(tree_hash(REAL_SAVE) == real_before, 'real save folder %LOCALAPPDATA%\\FirstGame unchanged')
    check(tree_hash(ROOT / 'review' / 'registry.json') == reg_before, 'project registry unchanged (test approvals never reach it)')
    summary = {'passed': not failures, 'checks': len(checks), 'failures': failures, 'phases': results, 'evidence': str(work),
               'captures': sorted(p.name for p in work.glob('*.png')), 'test_type': 'native Windows build, scripted input, technical test approvals only'}
    (ROOT / 'tests/reports/review-e2e-result.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    shutil.rmtree(TEST_SAVE, ignore_errors=True)
    print(json.dumps({k: summary[k] for k in ('passed', 'checks', 'failures', 'captures', 'evidence')}, indent=2))
    raise SystemExit(0 if summary['passed'] else 1)


if __name__ == '__main__':
    main()
