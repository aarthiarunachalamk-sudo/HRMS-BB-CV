from pathlib import Path
import shutil

workspace = Path.cwd()
tools_dir = workspace / 'tools'
dest_root = Path('C:/HRMS-BB/Screenshots')
dest_root.mkdir(parents=True, exist_ok=True)

count = 0
for p in tools_dir.rglob('*.png'):
    try:
        rel = p.relative_to(tools_dir)
    except Exception:
        rel = p.name
    parts = rel.parts
    sub = parts[0] if len(parts) > 1 else p.parent.name
    outdir = dest_root / sub
    outdir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, outdir / p.name)
    count += 1

print(f'Copied {count} screenshots to {dest_root}')
