"""
MIT License

Copyright (c) 2021-2022 Tobias Enderle

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
import os

is_windows = platform.system() == 'Windows'

lualatex = 'lualatex.exe' if is_windows else 'lualatex'
failure = False

def _run(file, test, expect_success, abs_path):
    global failure
    name = file if test is None else f'{file} {test}'
    print(f'#### Running test "{name}" (abs path: {abs_path})')

    path = f'test-cases/{file}.tex'
    if abs_path:
        path = os.path.abspath(path)
    cmd = path if test is None else r'\def\Test' + test + r'{1}\input{' + path + '}'
    result = subprocess.run(
        [lualatex, '-shell-escape', '--interaction=nonstopmode', cmd],
        capture_output=True)
    success = result.returncode == 0

    if expect_success != success:
        failure = True
        if expect_success:
            print(f'#### Test "{name}" was expected to succeed but failed')
        else:
            print(f'#### Test "{name}" was expected to fail but succeeded')
        if len(result.stdout) > 0:
            print('#### Stdout:')
            print(result.stdout.decode('utf-8'))
        if len(result.stderr) > 0:
            print('#### Stderr:')
            print(result.stderr.decode('utf-8'))

def assert_succeeds(file, test, abs_path=False):
    _run(file, test, True, abs_path)

def assert_fails(file, test, abs_path=False):
    _run(file, test, False, abs_path)

assert_succeeds('local-imports-true', None, True)
assert_succeeds('local-imports-true', None)
assert_succeeds('local-imports-false', None)
assert_succeeds('succeeding', None)
assert_fails('failing', 'VariableNotDefined')
assert_fails('failing', 'CodeOnFirstLine')
assert_fails('failing', 'InvalidIndentation')
assert_fails('failing', 'WrongSession')
assert_fails('failing', 'NoMultiline')
assert_fails('failing', 'AllOnOneLine')
assert_fails('failing-beamer', 'FrameNotFragile')
assert_succeeds('succeeding-beamer', 'All')

print(f'#### Running SyncTeX test')
file = 'test-cases/synctex-simple.tex'
subprocess.run(
    [lualatex, '-shell-escape', '--interaction=nonstopmode', '-synctex=1', file],
    capture_output=True
)
if os.path.isfile('synctex-simple.synctex(busy)'):
    print('#### *.synctex(busy) file present')
    failure = True
if not os.path.isfile('synctex-simple.synctex.gz'):
    print('#### *.synctex.gz file not present')
    failure = True

if is_windows:
    result = subprocess.run(
        ['wmic', 'process', 'where', "name like '%python%'", 'get', 'commandline'],
        capture_output=True
    )
else:
    result = subprocess.run(['pgrep', '-ilf', 'python'], capture_output=True)
if 'pyluatex-interpreter.py' in result.stdout.decode('utf-8').lower():
    print('#### Python process still running')
    failure = True

sys.exit(1 if failure else 0)
