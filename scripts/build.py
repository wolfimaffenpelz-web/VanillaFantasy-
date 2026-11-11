"""Deterministic, directly installable shaderpack ZIP (stdlib only)."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import argparse
import hashlib
from common import ROOT

def build(destination):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    files = sorted(p for p in (ROOT / 'shaders').rglob('*') if p.is_file())
    files += [ROOT / 'LICENSE']
    with ZipFile(destination, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            entry = ZipInfo(path.relative_to(ROOT).as_posix(), (2026, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, path.read_bytes(), compresslevel=9)
    return hashlib.sha256(destination.read_bytes()).hexdigest()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default=str(ROOT / 'dist' /
        f'Warm-Fantasy-Vanilla-Plus-{(ROOT / "VERSION").read_text().strip()}.zip'))
    args = parser.parse_args()
    digest = build(args.output)
    Path(str(args.output) + '.sha256').write_text(f'{digest}  {Path(args.output).name}\n')
    print(f'{args.output}\nSHA256 {digest}')
