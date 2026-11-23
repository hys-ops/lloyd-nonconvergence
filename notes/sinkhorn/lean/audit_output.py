"""Check that the audit covers every requested name and uses only standard axioms."""
import re
from pathlib import Path

expected = re.findall(r'^#print axioms (\S+)$', Path('Audit.lean').read_text(), re.M)
actual = dict(re.findall(r"'([^']+)' depends on axioms:\s*\[([^\]]*)\]", Path('logs/axioms.log').read_text()))
for name in re.findall(r"'([^']+)' does not depend on any axioms", Path('logs/axioms.log').read_text()):
    actual[name] = ''
if len(expected) != len(set(expected)) or set(actual) != set(expected):
    raise SystemExit(f'Audit coverage mismatch: {set(expected) ^ set(actual)}')
allowed = {'propext', 'Classical.choice', 'Quot.sound'}
used = {a.strip() for values in actual.values() for a in values.split(',') if a.strip()}
if extra := used - allowed:
    raise SystemExit(f'Unexpected axioms: {extra}')
print(f'{len(expected)} declarations checked, no placeholders or extra axioms.')
print('Axioms used: ' + ', '.join(sorted(used)))
