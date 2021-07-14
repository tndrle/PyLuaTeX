"""
MIT License

Copyright (c) 2021 Tobias Enderle

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

is_windows = platform.system() == 'Windows'

lualatex = 'lualatex.exe' if is_windows else 'lualatex'
failure = False

def _run(file, test, expectSuccess):
    global failure
    name = file if test is None else f'{file} {test}'
    print(f'#### Running test "{name}"')

    path = f'test-cases/{file}.tex'
    cmd = path if test is None else r'\def\Test' + test + r'{1}\input{' + path + '}'
    result = subprocess.run(
        [lualatex, '-shell-escape', '--interaction=nonstopmode', cmd],
        capture_output=True)
    success = result.returncode == 0

    if expectSuccess != success:
        failure = True
        if expectSuccess:
            print(f'#### Test "{name}" was expected to succeed but failed')
        else:
            print(f'#### Test "{name}" was expected to fail but succeeded')
        if len(result.stdout) > 0:
            print('#### Stdout:')
            print(result.stdout.decode('utf-8'))
        if len(result.stderr) > 0:
            print('#### Stderr:')
            print(result.stderr.decode('utf-8'))

def assertSucceeds(file, test):
    return _run(file, test, True)

def assertFails(file, test):
    return _run(file, test, False)

assertSucceeds('succeeding', 'All')
assertFails('failing', 'VariableNotDefined')
assertFails('failing', 'CodeOnFirstLine')
assertFails('failing', 'InvalidIndentation')
assertFails('failing', 'WrongSession')
assertFails('failing', 'NoMultiline')
assertFails('failing', 'AllOnOneLine')

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
