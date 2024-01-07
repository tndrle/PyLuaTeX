"""
MIT License

Copyright (c) 2021-2024 Tobias Enderle

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
import uuid
from pathlib import Path
import yaml
from pdfminer.high_level import extract_text
from pdfminer.layout import LAParams

test_cases_folder = Path('test-cases')

template_cache = {}

def get_cached_template(filename):
  if filename not in template_cache:
    template_cache[filename] = (test_cases_folder / filename).read_text(encoding='utf-8')
  return template_cache[filename]

def read_pdf(filename):
    try:
      return extract_text(filename, laparams=LAParams(char_margin=100)).strip('\n\x0c')
    except FileNotFoundError:
      return None

def read_pdf_raw(filename):
    try:
      return Path(filename).read_bytes()
    except FileNotFoundError:
      return None

def stripped(value):
  """
  Converts a non-None value to its string representation and strips whitespace
  >>> stripped(None)
  >>> stripped('test')
  'test'
  >>> stripped(' test ')
  'test'
  >>> stripped(5)
  '5'
  """
  return None if value is None else str(value).strip()

class Test:
  file_stem = '__temp'
  is_windows = platform.system() == 'Windows'
  lualatex = 'lualatex.exe' if is_windows else 'lualatex'
  base_cmds = [lualatex, '--shell-escape', '--interaction=nonstopmode']

  def __init__(self, file_data, data):
    def get_prop(name, default=None):
      # test-scoped properties have priority over file-scoped properties
      return data.get(name, file_data.get(name, default))

    self.template = stripped(get_prop('template', 'article_template.tex'))
    self.code = get_prop('code')
    assert self.code is not None
    self.expect_success = get_prop('success', True)
    assert isinstance(self.expect_success, bool)
    self.expected_pdf = stripped(get_prop('pdf'))
    self.expected_log = stripped(get_prop('log'))
    self.unexpected_log = stripped(get_prop('log_not'))
    self.args = stripped(get_prop('args', ''))
    self.absolute_path = get_prop('absolute_path', False)
    assert isinstance(self.absolute_path, bool)
    self.folder = stripped(get_prop('folder', ''))

    self.test_id = str(uuid.uuid4())

  def run(self):
    # remove existing files from previous test runs
    folder = Path(self.folder)
    for f in [Path(), folder]:  # local and specified folder (can be the same)
      for file in f.glob(f'{self.file_stem}.*'):
        file.unlink()

    if not folder.is_dir():
      folder.mkdir()
    tex_file = folder / f'{self.file_stem}.tex'
    template = get_cached_template(self.template)
    tex_file.write_text(template % (self.args, self.test_id, self.code))
    # as_posix(): LaTeX wants forward slashes even on Windows
    filename = (tex_file.resolve() if self.absolute_path else tex_file).as_posix()
    self.command = [*self.base_cmds, filename]
    result = subprocess.run(self.command, capture_output=True)

    self.success = result.returncode == 0
    self.log = Path(f'{self.file_stem}.log').read_text(encoding='utf-8')
    self.pdf = read_pdf(f'{self.file_stem}.pdf')
    self.pdf_raw = read_pdf_raw(f'{self.file_stem}.pdf')
    assert (self.pdf is None and self.pdf_raw is None) or \
      (self.pdf is not None and self.pdf_raw is not None)

  def check(self):
    passed = True
    messages = []

    def fail(message):
      nonlocal passed
      passed = False
      messages.append(message)

    def result():
      if passed:
        return True, None
      else:
        data = {
          'MESSAGE': '\n'.join(messages),
          'ARGS': self.args,
          'FOLDER': self.folder,
          'ABSOLUTE PATH': self.absolute_path,
          'COMMAND': ' '.join(self.command),
          'CODE': self.code,
          'SUCCESS': self.success,
          'PDF': self.pdf,
          'LOG': self.log
        }
        message = '\n'.join(f'### {t}\n{v}' for t, v in data.items()
                                            if v is not None and v != '')
        return False, message

    if f'TestID: {self.test_id}' not in self.log:
      fail('Test ID not found in log file. Output files from previous test?')
      return result()

    if self.pdf_raw is not None:
      if f'/TestID ({self.test_id})'.encode('utf-8') not in self.pdf_raw:
        fail('Test ID not in PDF. Output files from previous test?')
        return result()

    if self.success != self.expect_success:
      fail(
        f'Test was expected to {"succeed" if self.expect_success else "fail"}' + \
        f' but {"succeeded" if self.success else "failed"}'
      )

    if self.expected_pdf is not None:
      if self.pdf is None:
        fail('No PDF was generated')
      elif self.pdf != self.expected_pdf:
        fail('PDF content not as expected')

    if self.expected_log is not None and self.expected_log not in self.log:
      fail('Expected log output not found in log file')
    if self.unexpected_log is not None and self.unexpected_log in self.log:
      fail('Unexpected log output found in log file')

    return result()

def load_tests(file):
  data = yaml.load(file.read_text(encoding='utf-8'), Loader=yaml.FullLoader)
  return [Test(data, t) for t in data['tests']]


if __name__ == '__main__':
  overall_result = True
  for file in test_cases_folder.glob('*.yaml'):
    for test in load_tests(file):
      test.run()
      passed, message = test.check()
      if not passed:
        overall_result = False
        print('#######################', file)
        print(message)

  sys.exit(0 if overall_result else 1)
