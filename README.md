# PyLuaTeX
**Execute Python code on the fly in your LaTeX documents**

PyLuaTeX allows you to execute Python code and to include the resulting output in your LaTeX documents in a *single compilation run*.
LaTeX documents must be compiled with LuaLaTeX for this to work.

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/tndrle/pyluatex)](https://github.com/tndrle/PyLuaTeX/releases/latest)
[![CTAN](https://img.shields.io/ctan/v/pyluatex.svg)](https://ctan.org/pkg/pyluatex)
[![Tests workflow](https://github.com/tndrle/PyLuaTeX/actions/workflows/tests.yml/badge.svg)](https://github.com/tndrle/PyLuaTeX/actions)

## Example
1. LaTeX document `example.tex`<br>
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
lualatex --shell-escape example.tex
```

**Note:** PyLuaTeX starts Python 3 using the command `python3` by default.
If `python3` does not start Python 3 on your system, find the correct command
and replace `\usepackage{pyluatex}` with `\usepackage[executable=<your python command>]{pyluatex}`.
For example, `\usepackage[executable=python.exe]{pyluatex}`.

**Note:** Running LaTeX with the shell escape option enabled allows arbitrary code to be
executed. For this reason, it is recommended to compile trusted documents only.

### Further Examples
The folder `example` contains additional example documents:
* `beamer.tex`<br>
  Demonstrates the use of PyLuaTeX environments and typesetting in *BEAMER* presentations. In particular, the `fragile` option for frames is highlighted.
* `data-visualization.tex`<br>
  Demonstrates the visualization of data using *pgfplots* and *pandas*
* `matplotlib-external.tex`<br>
  Demonstrates how *matplotlib* plots can be generated and included in a document
* `matplotlib-pgf.tex`<br>
  Demonstrates how *matplotlib* plots can be generated and included in a document using *PGF*
* `readme-example.tex`<br>
  The example above
* `repl.tex`<br>
  Demonstrates how a Python console/REPL can be run and typeset
* `sessions.tex`<br>
  Demonstrates the use of different Python sessions in a document
* `typesetting-example.tex`<br>
  The code typesetting example below
* `typesetting-listings.tex`<br>
  A detailed example for typesetting code and output with the *listings* package
* `typesetting-minted.tex`<br>
  A detailed example for typesetting code and output with the *minted* package

## Installation
PyLuaTeX is available in TeX Live, MiKTeX, and on [CTAN](https://ctan.org/pkg/pyluatex) as `pyluatex`.

To install PyLuaTeX in **TeX Live** run `tlmgr install pyluatex`.<br>
In **MiKTeX**, PyLuaTeX can be installed in the *MiKTeX Console*.

## Reference
PyLuaTeX offers a simple set of options, macros and environments.

Most macros and environments are available as *quiet* versions as well.
They have the suffix `q` in their name, e.g. `\pycq` or `\pyfileq`.
The quiet versions suppress any output, even if the Python code explicitly calls `print()`.
This is helpful if you want to process code or output further and do your own typesetting.
For an example, see the [Typesetting Code](#typesetting-code) section.

### Package Options
* `executable`<br>
  Specifies the path to the Python executable. (default: `python3`)<br>
  *Example:* `\usepackage[executable=/usr/local/bin/python3]{pyluatex}`
* `ignoreerrors`<br>
  By default, PyLuaTeX aborts the compilation process when Python reports an error.
  If the `ignoreerrors` option is set, the compilation process is not aborted.<br>
  *Example:* `\usepackage[ignoreerrors]{pyluatex}`
* `localimports`<br>
  If this option is set, the folder containing the TeX input file is added to the Python path. This allows local Python packages to be imported. (default: `true`)<br>
  *Example:* `\usepackage[localimports=false]{pyluatex}`
* `shutdown`<br>
  Specifies when the Python process is shut down. (default: `veryveryend`)<br>
  *Options:* `veryveryend`, `veryenddocument`, `off`<br>
  PyLuaTeX shuts down the Python interpreter when the compilation is done. With the option `veryveryend`, Python is shut down in the `enddocument/end` hook. With the option `veryenddocument`, Python is shut down in the `enddocument/afteraux` hook. With the option `off`, Python is not shut down explicitly. However, the Python process will shut down when the LuaTeX process finishes even if `off` is selected. Using `off` on Windows might lead to problems with SyncTeX, though.<br>
  Before v0.6.2, PyLuaTeX used the hooks `\AtVeryVeryEnd` and `\AtVeryEndDocument` of the package *atveryend*. The new hooks `enddocument/end` and `enddocument/afteraux` are equivalent to those of the *atveryend* package.<br>
  *Example:* `\usepackage[shutdown=veryenddocument]{pyluatex}`
* `verbose`<br>
  If this option is set, Python input and output is written to the LaTeX log file.<br>
  *Example:* `\usepackage[verbose]{pyluatex}`

The package options `verbose` and `ignoreerrors` can be changed in the document with the
`\pyoption` command, e.g. `\pyoption{verbose}{true}` or `\pyoption{ignoreerrors}{false}`.

### Macros
* `\py{<code>}`<br>
  Executes (object-like) `<code>` and writes its string representation to the document.<br>
  *Example:* `\py{3 + 7}`
* `\pyq{<code>}`<br>
  Executes (object-like) `<code>`. Any output is suppressed.<br>
  *Example:* `\pyq{3 + 7}`
* `\pyc{<code>}`<br>
  Executes `<code>`. Output (e.g. from a call to `print()`) is written to the document.<br>
  *Examples:* `\pyc{x = 5}`, `\pyc{print('hello')}`
* `\pycq{<code>}`<br>
  Executes `<code>`. Any output is suppressed.<br>
  *Example:* `\pycq{x = 5}`
* `\pyfile{<path>}`<br>
  Executes the Python file specified by `<path>`. Output (e.g. from a call to `print()`) is written to the document.<br>
  *Example:* `\pyfile{main.py}`
* `\pyfileq{<path>}`<br>
  Executes the Python file specified by `<path>`. Any output is suppressed.<br>
  *Example:* `\pyfileq{main.py}`
* `\pysession{<session>}`<br>
  Selects `<session>` as Python session for subsequent Python code.<br>
  The session that is active at the beginning is `default`.<br>
  *Example:* `\pysession{main}`
* `\pyoption{<option>}{<value>}`<br>
  Assigns `<value>` to the package option `<option>` anywhere in the document. For more information consider
  the [Package Options](#package-options) section.<br>
  *Example:* `\pyoption{verbose}{true}`
* `\pyif{<test>}{<then clause>}{<else clause>}`<br>
  Evaluates the Python boolean expression `<test>`, and then executes either the LaTeX code in `<then clause>` or the LaTeX code in `<else clause>`.<br>
  *Example:* `\pyif{a == 1}{$a = 1$}{$a \neq 1$}`

### Environments
* `python`<br>
  Executes the provided block of Python code.<br>
  The environment handles characters like `_`, `#`, `%`, `\`, etc.<br>
  Code on the same line as `\begin{python}` is ignored, i.e., code must start on the next line.<br>
  If leading spaces are present they are gobbled automatically up to the first level of indentation.<br>
  *Example:*
  ```
  \begin{python}
      x = 'Hello PyLuaTeX'
      print(x)
  \end{python}
  ```
* `pythonq`<br>
  Same as the `python` environment, but any output is suppressed.
* `pythonrepl`<br>
  Executes the provided block of Python code in an interactive console/REPL. Code and output are
  stored together in the output buffer and can be typeset as explained in section
  [Typesetting Code](#typesetting-code) or as shown in the example `repl.tex` in the folder
  `example`.

You can create your own environments based on the `python`, `pythonq` and `pythonrepl` environments.
However, since they are verbatim environments, you have to use the macro `\PyLTVerbatimEnv`
in your environment definition, e.g.
```latex
\newenvironment{custompy}
{\PyLTVerbatimEnv\begin{python}}
{\end{python}}
```

### Logging from Python
```python
tex.log(*objects, sep=' ', end='\n')
```
Writes `objects` to the TeX log, separated by `sep` and followed by `end`.
All elements in `objects` are converted to strings using `str()`.
Both `sep` and `end` must be strings.

*Example:*
```latex
\begin{python}
tex.log('This text goes to the TeX log.')
\end{python}
```

## Requirements
* LuaLaTeX
* Python 3
* Linux, macOS or Windows

## Typesetting Code
Sometimes, in addition to having Python code executed and the output written to your document, you also want to show the code itself in your document.
PyLuaTeX does not offer any macros or environments that directly typeset code.
However, PyLuaTeX has a **code and output buffer** which you can use to create your own typesetting functionality.
This provides a lot of flexibility for your typesetting.

After a PyLuaTeX macro or environment has been executed, the corresponding Python code and output can be accessed via the Lua functions `pyluatex.get_last_code()` and `pyluatex.get_last_output()`, respectively.
Both functions return a Lua [table](https://www.lua.org/pil/2.5.html) (basically an array) where each table item corresponds to a line of code or output.

A simple example for typesetting code and output using the *listings* package would be:
```latex
\documentclass{article}

\usepackage{pyluatex}
\usepackage{listings}
\usepackage{luacode}

\begin{luacode}
function pytypeset()
    tex.print("\\begin{lstlisting}[language=Python]")
    tex.print(pyluatex.get_last_code())
    tex.print("\\end{lstlisting}")
    tex.print("") -- ensure newline
end
\end{luacode}

\newcommand*{\pytypeset}{%
    \noindent\textbf{Input:}
    \directlua{pytypeset()}
    \textbf{Output:}
    \begin{center}
        \directlua{tex.print(pyluatex.get_last_output())}
    \end{center}
}

\begin{document}

\begin{pythonq}
greeting = 'Hello PyLuaTeX!'
print(greeting)
\end{pythonq}
\pytypeset

\end{document}
```

Notice that we use the `pythonq` environment, which suppresses any output.
After that, the custom macro `\pytypeset` is responsible for typesetting the code and its output.

Using a different code listings package like *minted*, or typesetting inline code is very easy.
You can also define your own environments that combine Python code and typesetting.
See the `typesetting-*.tex` examples in the `example` folder.

To emulate an interactive Python console/REPL, the `pythonrepl` environment can be used.

## How It Works
PyLuaTeX runs a Python [`InteractiveInterpreter`](https://docs.python.org/3/library/code.html#code.InteractiveInterpreter) (actually several if you use different sessions) in the background for on the fly code execution.
Python code from your LaTeX file is sent to the background interpreter through a TCP socket.
This approach allows your Python code to be executed and the output to be integrated in your LaTeX file in a single compilation run.
No additional processing steps are needed.
No intermediate files have to be written.
No placeholders have to be inserted.

## License
[LPPL 1.3c](http://www.latex-project.org/lppl.txt) for LaTeX code and
[MIT license](https://opensource.org/licenses/MIT) for Python and Lua code and other files.
