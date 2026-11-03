"""Small structural check; deliberately does not claim to compile Swift."""
from pathlib import Path
import json
import re
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
project = root / 'TaskManager.xcodeproj/project.pbxproj'
before = project.read_bytes()
subprocess.run(['python', str(root / 'scripts/generate_project.py')], cwd=root, check=True)
assert before == project.read_bytes(), 'Project is out of date; inspect and commit regenerated output'
text = before.decode('utf-8')
ids = re.findall(r'^([A-F0-9]{24}) = ', text, re.M)
assert len(ids) == len(set(ids)), 'Duplicate Xcode object IDs'
refs = set(re.findall(r'\b[A-F0-9]{24}\b', text))
assert refs == set(ids), 'Unresolved Xcode object reference'
for file in (root / 'TaskManager').glob('*.swift'):
    assert f'path = "{file.name}";' in text, f'Missing source: {file.name}'
assert 'lastKnownFileType = folder; path = FirebaseConfig;' in text
assert 'version = 12.19.3;' in text
ET.parse(root / 'TaskManager.xcodeproj/xcshareddata/xcschemes/TaskManager.xcscheme')
for file in ['firebase.json', 'firestore.indexes.json', 'package.json']:
    json.loads((root / file).read_text(encoding='utf-8-sig'))
assert 'FirebaseConfig/*.plist' in (root / '.gitignore').read_text(encoding='utf-8-sig')
tracked = subprocess.check_output(['git', 'ls-files'], cwd=root, text=True)
assert not any(p.endswith('.plist') for p in tracked.splitlines()), 'Firebase config should transfer separately'
print('PASS: deterministic project, source membership, object references, scheme XML, JSON, config exclusion')
