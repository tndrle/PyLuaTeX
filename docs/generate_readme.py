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

import re
from pathlib import Path
import yaml
from collections import defaultdict
import textwrap

def ml_code(s):
  return f'```latex\n{s.strip()}\n```'

def code(s):
  return ml_code(s) if ('\n' in s) else f'`{s.strip()}`'

def prepare_test(s):
  lines = s.splitlines()
  lines = (l for l in lines if not 'hide line' in l)
  return code('\n'.join(lines).strip())

tests = yaml.load(
  Path('../test/test-cases/readme_examples.yaml').read_text(),
  Loader=yaml.FullLoader
)['tests']
tests = {t['id']: prepare_test(t['code']) for t in tests}

lua_content = Path('../pyluatex.lua').read_text()
sty_content = Path('../pyluatex.sty').read_text()

readme = Path('README_base.md').read_text()

def strip(s):
  return s.strip(' "\n[]')

def get_options(s, has_values=True):
  s = s.strip(' ,\n')
  if s:
    if has_values:
      return dict(
        tuple(strip(v) for v in o.split('=')) for o in s.split(',')
      )
    else:
      return {strip(o) for o in s.split(',')}
  return {}

# Read global options and defaults
m = re.search(r'local options = \{ \{(.*?)\} \}', lua_content, re.S)
global_options = get_options(m[1])

# Read valid options for commands and environments
m = re.search(r'local valid_cmd_keys =.*?\{(.*?)\}', lua_content, re.S)
valid_cmd_options = get_options(m[1], False)

# Read aliases
m = re.search(r'local key_aliases =.*?\{(.*?)\}', lua_content, re.S)
aliases = defaultdict(list)
for alias, key in get_options(m[1]).items():
  aliases[key].append(alias)

# Compute package options
# Assumption: global options - valid cmd options = package options
package_options = set(global_options) - valid_cmd_options

# Read presets for commands and environments
ms = re.finditer(
  r'^\\__pyluatex_cmd:.+?\\(\S+)\s*\{(.*?)\}', sty_content, re.S | re.M
)
presets = {m[1]: set(get_options(m[2])) for m in ms}
ms = re.finditer(
  r'^\\__pyluatex_env:.+?\{(.+?)\}\s*\{(.*?)\}', sty_content, re.S | re.M
)
presets |= {m[1].strip(): set(get_options(m[2])) for m in ms}

# Generate reference
def plural(base, items):
  if len(items) > 1:
    return base + ('es' if base.endswith('s') else 's')
  else:
    return base

def examples(item, r):
  ex = [code(e) for e in item.get('examples', [])]
  ex += [t for id, t in tests.items() if id.startswith(f'ex-{item['name']}-')]
  if len(ex) > 0:
    r.append(
      f'*{plural('Example', ex)}:*' + \
      ('\n' if ('\n' in ex[0]) else ' ') + ', '.join(ex)
    )

def equivalent(item, r):
  if 'equivalent' in item:
    r.append(f'This is equivalent to `{item['equivalent']}`.')

def itemize(r):
  s = textwrap.indent('<br>\n'.join(r), '  ')
  return '*' + s[1:]

ref_data = yaml.load(
  Path('reference.yaml').read_text(), Loader=yaml.FullLoader
)

# Example files
def example_file(f):
  content = f.read_text()
  desc = re.search('% DESCRIPTION(.*?)\n[^%]', content, flags=re.S)[1]
  desc = re.sub('^% ', '', desc.strip(), flags=re.M)
  return itemize([f'`{f.name}`', desc])

example_files = map(example_file, sorted(Path('../example').glob('*.tex')))
readme = readme.replace('%% EXAMPLE_FILES %%', '\n'.join(example_files))

# Commands
def build_command(command):
  r = [
    f'**`{command['call']}`**',
    command['desc'].strip()
  ]
  equivalent(command, r)
  if command.get('options', True):
    pre = presets.get(command['name'], set())
    opts = ', '.join(map(code, sorted(valid_cmd_options - pre)))
    r.append('*Allowed options:* ' + opts)
  examples(command, r)
  return itemize(r)

commands = map(build_command, ref_data['reference']['commands'])
readme = readme.replace('%% COMMANDS %%', '\n'.join(commands))

commands_compat = map(build_command, ref_data['reference']['commands_compat'])
readme = readme.replace('%% COMMANDS_COMPAT %%', '\n'.join(commands_compat))

# Environments
def build_environment(env):
  r = [
    f'**`{env['name']}`**',
    env['desc'].strip()
  ]
  equivalent(env, r)
  if env.get('options', True):
    pre = presets.get(env['name'], set())
    opts = ', '.join(map(code, sorted(valid_cmd_options - pre)))
    r.append('*Allowed options:* ' + opts)
  examples(env, r)
  return itemize(r)

envs = map(build_environment, ref_data['reference']['environments'])
readme = readme.replace('%% ENVIRONMENTS %%', '\n'.join(envs))

envs_compat = map(
  build_environment, ref_data['reference']['environments_compat']
)
readme = readme.replace('%% ENVIRONMENTS_COMPAT %%', '\n'.join(envs_compat))

# Options
def build_option(option):
  name = option['name']
  s = f'**`{name}`** &emsp; `{option['type']}` ' \
      f'&emsp; *default:* `{global_options[name]}`'
  if name in package_options:
    s += ' &emsp; *package option only*'
  r = [s, option['desc'].strip()]
  if name in aliases:
    r.append(
      f'*{plural('Alias', aliases[name])}:* ' + \
      ', '.join(map(code, aliases[name]))
    )
  examples(option, r)
  return itemize(r)

options = map(build_option, ref_data['reference']['options'])
readme = readme.replace('%% OPTIONS %%', '\n'.join(options))

# Insert examples from files and tests
def insert_example(m):
  content = (Path('../example') / m[2]).read_text()
  content = ml_code(
    re.sub(r'.*?(?=\\documentclass)', r'', content, flags=re.S).strip()
  )
  return textwrap.indent(content, m[1])

readme = re.sub(
  r'^(\s*)%% EXAMPLE:(\S+) %%', insert_example, readme, flags=re.M
)
readme = re.sub(r'%% TEST:(\S+) %%', lambda m: tests[m[1]], readme)

Path('../README.md').write_text(readme, encoding='utf-8')
