# PyLuaTeX
**Execute Python code on the fly in your LaTeX documents**

PyLuaTeX allows you to execute Python code and to include the resulting output in your LaTeX documents in a *single compilation run*.
LaTeX documents must be compiled with LuaLaTeX for this to work.

[![Tests workflow](https://github.com/tndrle/PyLuaTeX/actions/workflows/tests.yml/badge.svg)](https://github.com/tndrle/PyLuaTeX/actions)

## Example
1. LaTeX document `example.tex`  
**Note:** PyLuaTeX starts Python 3 using the command `python3` by default.
If `python3` does not start Python 3 on your system, find the correct command
and replace `\usepackage{pyluatex}` with `\usepackage[executable={your python command}]{pyluatex}`.
For example, `\usepackage[executable=python.exe]{pyluatex}`.
```latex
\documentclass{article}

\usepackage{pyluatex}

\begin{python}
import math
import random

random.seed(0)

greeting = 'Hello PyLuaTeX!'
\end{python}

\newcommand{\randint}[2]{\py{random.randint(#1, #2)}}

\begin{document}
\py{greeting}

$\sqrt{371} = \py{math.sqrt(371)}$

\randint{2}{5}
\end{document}
```

2. Compile using LuaLaTeX (shell escape is required)
```
lualatex -shell-escape example.tex
```

**Note:** Running LaTeX with the shell escape option enabled allows arbitrary code to be
executed. For this reason, it is recommended to compile trusted documents only.

### Further Examples
The folder `example` contains additional example documents:
* `readme-example.tex`  
  The example above
* `sessions.tex`  
  Demonstrates the use of different Python sessions in a document
* `data-visualization.tex`  
  Demonstrates the visualization of data using *pgfplots* and *pandas*
* `matplotlib-external.tex`  
  Demonstrates how *matplotlib* plots can be generated and included in a document
* `matplotlib-pgf.tex`  
  Demonstrates how *matplotlib* plots can be generated and included in a document using *PGF*

For more intricate use cases have a look at our tests in the folder `test`.

## Installation
PyLuaTeX is available on [CTAN](https://ctan.org/pkg/pyluatex) and in MiKTeX.
It will be available in TeX Live soon (when you read this it probably already is).

To install PyLuaTeX **manually**, do the following steps:
1. Locate your local *TEXMF* folder  
The location of this folder may vary. Typical defaults for TeX Live are `~/texmf` for Linux,
`~/Library/texmf` for macOS, and `C:\Users\<user name>\texmf` for Windows.
If you are lucky, the command `kpsewhich -var-value=TEXMFHOME` tells you the location.
For MiKTeX, the folder can be found and configured in the *MiKTeX Console*.
2. Download the [latest release](https://github.com/tndrle/PyLuaTeX/releases/latest) of PyLuaTeX
3. Put the downloaded files in the folder `TEXMF/tex/latex/pyluatex` (where `TEXMF` is the folder located in 1.)  
The final folder structure must be
```
TEXMF/tex/latex/pyluatex/
├── pyluatex-interpreter.py
├── pyluatex-json.lua
├── pyluatex.lua
├── pyluatex.sty
├── ...
```

## Reference
PyLuaTeX offers a simple set of options, macros and environments.

### Package Options
* `verbose`  
  If this option is enabled, Python input and output is written to the log file.  
  *Example:* `\usepackage[verbose]{pyluatex}`
* `executable`  
  Specifies the path to the Python executable. (default: `python3`)  
  *Example:* `\usepackage[executable=/usr/local/bin/python3]{pyluatex}`

### Macros
* `\py{code}`  
  Executes `code` and writes the output to the document.  
  *Example:* `\py{3 + 7}`
* `\pyc{code}`  
  Executes `code`  
  *Example:* `\pyc{x = 5}`
* `\pyfile{path}`  
  Executes the Python file specified by `path`.  
  *Example:* `\pyfile{main.py}`
* `\pysession{session}`  
  Selects `session` as Python session for subsequent Python code.  
  The session that is active at the beginning is `default`.  
  *Example:* `\pysession{main}`

### Environments
* `python`  
  Executes the provided block of Python code.  
  The environment handles characters like `_`, `#`, `%`, `\`, etc.  
  Code on the same line as `\begin{python}` is ignored, i.e., code must start on the next line.  
  If leading spaces are present they are gobbled automatically up to the first level of indentation.  
  *Example:*
  ```
  \begin{python}
      x = 'Hello PyLuaTeX'
      print(x)
  \end{python}
  ```

## Requirements
* LuaLaTeX
* Python 3
* Linux, macOS or Windows

Our automated tests currently use TeX Live 2021 and Python 3.7+ on
Ubuntu 20.04, macOS Catalina 10.15 and Windows Server 2019.

## How It Works
PyLuaTeX runs a Python [`InteractiveInterpreter`](https://docs.python.org/3/library/code.html#code.InteractiveInterpreter) (actually several if you use different sessions) in the background for on the fly code execution.
Python code from your LaTeX file is sent to the background interpreter through a TCP socket.
This approach allows your Python code to be executed and the output to be integrated in your LaTeX file in a single compilation run.
No additional processing steps are needed.
No intermediate files have to be written.
No placeholders have to be inserted.

## License
[LPPL 1.3c](http://www.latex-project.org/lppl.txt) for LaTeX code and
[MIT license](https://opensource.org/licenses/MIT) for Python and Lua code.

We use the great [json.lua](https://github.com/rxi/json.lua) library under the terms
of the [MIT license](https://opensource.org/licenses/MIT).
