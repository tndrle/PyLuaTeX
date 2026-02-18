"""
MIT License

Copyright (c) 2021-2026 Tobias Enderle

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
"""

import os
import sys
from pathlib import Path
import subprocess
import filecmp
import shutil
import pymupdf

regen = '--regen' in sys.argv

def run(file):
  print('#', file)
  result = subprocess.run(
    f'latexmk -lualatex -shell-escape -interaction=nonstopmode {file}'.split(' '),
    capture_output=True
  )
  if result.returncode != 0:
    return False

  if os.path.isfile(f'{file.stem}_0_ref.png'):
    # reference image(s) present -> check equality
    print('Comparing images')
    with pymupdf.open(f'{file.stem}.pdf') as doc:
      for i, page in enumerate(doc):
        png = f'{file.stem}_{i}.png'
        png_ref = f'{file.stem}_{i}_ref.png'
        page.get_pixmap(dpi=200).save(png)
        if regen:
          shutil.copyfile(png, png_ref)
        r = filecmp.cmp(png_ref, png, shallow=False)
        if not r:
          return False
  return True

os.chdir('../example')

failures = []
for file in Path().glob('*.tex'):
  success = run(file)
  if not success:
    failures.append(str(file))
    print(Path(f'{file.stem}.log').read_text(encoding='utf-8'))

if failures:
  print('Failures:', failures)
  sys.exit(1)
else:
  print('Success')
  sys.exit(0)
