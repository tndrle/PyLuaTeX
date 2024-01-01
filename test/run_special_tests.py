"""
MIT License

Copyright (c) 2021-2023 Tobias Enderle

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

import sys
import subprocess
import platform
from os.path import isfile
import re
from pathlib import Path

is_windows = platform.system() == 'Windows'
lualatex = 'lualatex.exe' if is_windows else 'lualatex'
base_cmds = [lualatex, '--shell-escape', '--interaction=nonstopmode']

def run(*args):
  return subprocess.run(args, capture_output=True)

def compile(*args):
  return run(*base_cmds, *args)

overall_success = True

############################################################
print('#### Checking version')
test_version = re.search(
  r'\\ProvidesPackage{pyluatex}\[\d{4}/\d{2}/\d{2}\s+(v[\d.]+)',
  (Path('..') / 'pyluatex.sty').read_text(encoding='utf-8')
).group(1)
output = compile(
  r'\listfiles\documentclass{article}\usepackage{pyluatex}\document A\enddocument'
).stdout.decode('utf-8')
used_version = re.search(
  r'pyluatex\.sty\s+\d{4}/\d{2}/\d{2}\s+(v[\d.]+)',
  output[output.index('*File List*'):]
).group(1)
if test_version != used_version:
  print('Test version != used version')
  print('Test version:', test_version)
  print('Version used by LuaLaTeX:', used_version)
  sys.exit(1)

############################################################
print('#### SyncTeX test')
configs = [
  ('', True, True),
  ('shutdown=off', False, True),
  ('shutdown=veryveryend', True, True),
  ('shutdown=veryenddocument', True, True),
]
for arg, win_success, other_success in configs:
  for f in Path().glob('texput.*'):
    f.unlink()
  result = compile(
    '--synctex=1',
    r'\documentclass{article}\usepackage[%s]{pyluatex}\document A\enddocument' % arg
  )
  assert result.returncode == 0

  success = not isfile('texput.synctex(busy)') and isfile('texput.synctex.gz')
  if (is_windows and success != win_success) or (not is_windows and success != other_success):
    overall_success = False
    system = '' if is_windows else 'non-' 
    print(f'Unexpected result for argument "{arg}" on {system}Windows system')

############################################################
print('#### Checking whether Python process is still running')
if is_windows:
  result = run(
    'wmic', 'process', 'where', "name like '%python%'", 'get', 'commandline'
  )
else:
  result = run('ps', 'ax')
stdout = result.stdout.decode('utf-8').lower()
# Heuristic to ensure that we see all relevant processes:
# Current script must be present in running processes
assert Path(__file__).name.lower() in stdout, stdout

if 'pyluatex-interpreter.py' in stdout:
  overall_success = False
  print('Python process still running')

sys.exit(0 if overall_success else 0)
