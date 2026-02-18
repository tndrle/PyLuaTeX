# PyLuaTeX
**Execute Python code on the fly in your LaTeX documents**

PyLuaTeX allows you to execute Python code and to include the resulting output
in your LaTeX documents in a *single compilation run*.
LaTeX documents must be compiled with LuaLaTeX for this to work.

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/tndrle/pyluatex)](https://github.com/tndrle/PyLuaTeX/releases/latest)
[![CTAN](https://img.shields.io/ctan/v/pyluatex.svg)](https://ctan.org/pkg/pyluatex)
[![Tests workflow](https://github.com/tndrle/PyLuaTeX/actions/workflows/tests.yml/badge.svg)](https://github.com/tndrle/PyLuaTeX/actions)

## Example
1. LaTeX document `example.tex`
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
and extend `\usepackage{pyluatex}` to
`\usepackage[executable=<your python command>]{pyluatex}`.
For example, `\usepackage[executable=python.exe]{pyluatex}`.

**Security note:** Running LaTeX with the `--shell-escape` option
allows arbitrary code to be executed.
For this reason, it is recommended to **compile trusted documents only**.

### Further Examples
The folder `example` contains additional example documents:
* `beamer.tex`<br>
  Demonstrates the use of PyLuaTeX environments and typesetting in *BEAMER*
  presentations. In particular, the `fragile` option for frames is highlighted.
* `data-visualization.tex`<br>
  Demonstrates the visualization of data using *pgfplots* and *pandas*
* `matplotlib-external.tex`<br>
  Demonstrates how *matplotlib* plots can be generated and included in a
  document
* `matplotlib-pgf.tex`<br>
  Demonstrates how *matplotlib* plots can be generated and included in a
  document using *PGF*
* `readme-example.tex`<br>
  The example above
* `repl.tex`<br>
  Demonstrates how a Python console/REPL can be run and typeset
* `sessions.tex`<br>
  Demonstrates the use of different Python sessions in a document
* `typesetting-example.tex`<br>
  The code typesetting example below
* `typesetting-listings.tex`<br>
  A detailed example for typesetting code and output with the *listings*
  package
* `typesetting-minted.tex`<br>
  A detailed example for typesetting code and output with the *minted* package

## Reference
### Commands
Most of the following commands accept key-value options.
See [Options](#options) for more details.

* **`\py[<options>]{<code>}`**<br>
  Executes (object-like) `<code>` and writes its string representation to
  the document.<br>
  *Allowed options:* `ignoreerrors`, `quiet`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\py{3 + 7}`
* **`\pyc[<options>]{<code>}`**<br>
  Executes `<code>`. Output (e.g. from a call to `print()`) is written to
  the document.<br>
  *Allowed options:* `ignoreerrors`, `quiet`, `repl`, `session`, `store`, `verbose`<br>
  *Examples:* `\pyc{x = 5}`, `\pyc{print('hello')}`
* **`\pyfile[<options>]{<path>}`**<br>
  Executes the Python file specified by `<path>`.
  Output (e.g. from a call to `print()`) is written to the document.<br>
  *Allowed options:* `ignoreerrors`, `quiet`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\pyfile{main.py}`
* **`\pyif[<options>]{<test>}{<then clause>}{<else clause>}`**<br>
  Evaluates the Python boolean expression `<test>`, and then executes either
  the LaTeX code in `<then clause>` or the LaTeX code in `<else clause>`.<br>
  *Allowed options:* `session`, `verbose`<br>
  *Example:* `\pyif{a == 1}{$a = 1$}{$a \neq 1$}`
* **`\pyoptions{<options>}`**<br>
  Sets options globally.
  For more information see the [Options](#options) section.<br>
  *Allowed options:* `ignoreerrors`, `quiet`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\pyoptions{verbose,session=main}`

The following commands exist as shortcuts and for backward compatibility with
previous versions of PyLuaTeX:

* **`\pyq[<options>]{<code>}`**<br>
  Executes (object-like) `<code>`. Any output to the document is suppressed.<br>
  This is equivalent to `\py[quiet,<options>]{<code>}`.<br>
  *Allowed options:* `ignoreerrors`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\pyq{3 + 7}`
* **`\pycq[<options>]{<code>}`**<br>
  Executes `<code>`. Any output to the document is suppressed.<br>
  This is equivalent to `\pyc[quiet,<options>]{<code>}`.<br>
  *Allowed options:* `ignoreerrors`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\pycq{x = 5}`
* **`\pyfileq[<options>]{<path>}`**<br>
  Executes the Python file specified by `<path>`. Any output to the
  document is suppressed.<br>
  This is equivalent to `\pyfile[quiet,<options>]{<path>}`.<br>
  *Allowed options:* `ignoreerrors`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\pyfileq{main.py}`
* **`\pysession{<name>}`**<br>
  Sets `<name>` globally as Python session for subsequent Python code.
  The session that is active at the beginning is `default`.<br>
  This is equivalent to `\pyoptions{session=<name>}`.<br>
  *Example:* `\pysession{main}`
* **`\pyoption{<option>}{<value>}`**<br>
  Assigns `<value>` to the option `<option>` globally.
  For more information see the [Options](#options) section.<br>
  This is equivalent to `\pyoptions{<option>=<value>}`.<br>
  *Allowed options:* `ignoreerrors`, `quiet`, `repl`, `session`, `store`, `verbose`<br>
  *Example:* `\pyoption{verbose}{true}`

### Environments
* **`python`**<br>
  Executes the provided block of Python code.
  The environment handles characters like `_`, `#`, `%`, `\`, etc.
  Code on the same line as `\begin{python}` is ignored, i.e., code must
  start on the next line.
  If leading spaces are present, they are gobbled automatically up to the
  first level of indentation.<br>
  *Allowed options:* `ignoreerrors`, `quiet`, `repl`, `session`, `store`, `verbose`<br>
  *Example:*
  ```latex
  \begin{python}
    x = 'Hello PyLuaTeX'
    print(x)
  \end{python}
  ```

Like commands, environments accept key-value options, e.g.
```latex
\begin{python}[ignoreerrors]
  print(1 / 0)
\end{python}
```
The opening tag `[` must **directly follow** the `\begin{python}`.
Spaces or line breaks between `\begin{python}` and `[` are not allowed.

The following environments exist as shortcuts and for backward
compatibility with previous versions of PyLuaTeX:

* **`pythonq`**<br>
  Same as the `python` environment, but any output to the document is
  suppressed.<br>
  This is equivalent to `\begin{python}[quiet,<options>]`.<br>
  *Allowed options:* `ignoreerrors`, `repl`, `session`, `store`, `verbose`
* **`pythonrepl`**<br>
  Executes the provided block of Python code in an interactive console/REPL.
  Code and output are stored together in the output buffer and can be
  typeset as explained in the section [Typesetting Code](#typesetting-code)
  or as shown in the example `repl.tex` in the folder `example`.<br>
  This is equivalent to `\begin{python}[quiet,repl,<options>]`.<br>
  *Allowed options:* `ignoreerrors`, `session`, `store`, `verbose`

### Custom Environments
You can create your own environments based on the `python`, `pythonq` and
`pythonrepl` environments.
However, since those are verbatim environments, you have to use the command
`\PyLTVerbatimEnv` in your environment definition, e.g.
```latex
\NewDocumentEnvironment{custompy}{}
{\PyLTVerbatimEnv\begin{python}}
{\end{python}}
```

### Options
Options marked with *package option only* are only valid as package
options in `\usepackage[...]{pyluatex}`.
All other options can be used as package options and throughout the
document.
Options can be set globally using `\pyoptions` or locally for the
various environments and commands.
If a value contains commas, the entire value must be enclosed in
quotation marks.

* **`executable`** &emsp; `string` &emsp; *default:* `python3` &emsp; *package option only*<br>
  Specifies the path to the Python executable.<br>
  *Example:* `\usepackage[executable=/usr/local/bin/python3]{pyluatex}`
* **`ignoreerrors`** &emsp; `boolean` &emsp; *default:* `false`<br>
  By default, PyLuaTeX aborts the compilation process when Python reports an
  error. If the `ignoreerrors` option is set, the compilation process is not
  aborted.<br>
  *Alias:* `ignore errors`<br>
  *Examples:* `\usepackage[ignoreerrors]{pyluatex}`, `\py[ignore errors]{1 / 0}`
* **`localimports`** &emsp; `boolean` &emsp; *default:* `true` &emsp; *package option only*<br>
  If this option is set, the folder containing the LaTeX input file is added
  to the Python path. This allows local Python packages to be imported.<br>
  *Alias:* `local imports`<br>
  *Example:* `\usepackage[localimports=false]{pyluatex}`
* **`quiet`** &emsp; `boolean` &emsp; *default:* `false`<br>
  If this option is set, any output to the document is suppressed, even if
  the Python code explicitly calls `print()`. This is helpful if you want
  to process code or output further and do your own typesetting. For an
  example, see the [Typesetting Code](#typesetting-code) section.<br>
  *Alias:* `q`<br>
  *Examples:* `\py[quiet]{7 + 4}`, `\py[q]{'Hello'}`
* **`repl`** &emsp; `boolean` &emsp; *default:* `false`<br>
  If this option is set, Python code is executed in an interactive
  console/REPL. Code and output are stored together in the output buffer
  and can be typeset as explained in the section
  [Typesetting Code](#typesetting-code) or as shown in the example
  `repl.tex` in the folder `example`. The use of `quiet` together with
  `repl` is recommended.
* **`session`** &emsp; `boolean` &emsp; *default:* `default`<br>
  Sessions provide a way to structure and separate code.
  Variables, function definitions, etc. of one session are only accessible
  by that session. This can be helpful in long documents
  with a lot of code.<br>
  *Alias:* `s`<br>
  *Examples:* `\pyc[session=main]{x = 5}`, `\py[s=main]{x}`
* **`shutdown`** &emsp; `choice` &emsp; *default:* `veryveryend` &emsp; *package option only*<br>
  Specifies when the Python process is shut down.<br>
  *Possible values:* `veryveryend`, `veryenddocument`, `off`<br>
  PyLuaTeX shuts down the Python interpreter when the compilation is done.
  With the option `veryveryend`, Python is shut down in the
  `enddocument/end` hook. With the option `veryenddocument`, Python is shut
  down in the `enddocument/afteraux` hook. With the option `off`, Python is
  not shut down explicitly. However, the Python process will shut down when
  the LuaTeX process finishes even if `off` is selected. Using `off` on
  Windows might lead to problems with SyncTeX, though
  (https://github.com/tndrle/PyLuaTeX/issues/8).<br>
  Before v0.6.2, PyLuaTeX used the hooks `\AtVeryVeryEnd` and
  `\AtVeryEndDocument` of the package *atveryend*. The new hooks
  `enddocument/end` and `enddocument/afteraux` are equivalent to those of
  the *atveryend* package.<br>
  *Example:* `\usepackage[shutdown=veryenddocument]{pyluatex}`
* **`store`** &emsp; `boolean` &emsp; *default:* `true`<br>
  If this option is set, code and output are stored in buffers.
  See [Typesetting Code](#typesetting-code) for more details.<br>
  *Example:* `\pyc[store=false]{x = 5}`
* **`verbose`** &emsp; `boolean` &emsp; *default:* `false`<br>
  If this option is set, Python input and output is written to the LaTeX log
  file.<br>
  *Examples:* `\usepackage[verbose]{pyluatex}`, `\py[verbose]{7 + 4}`

### Logging from Python
```python
tex.log(*objects, sep=' ', end='\n')
```
Writes `objects` to the LaTeX log, separated by `sep` and followed by `end`.
All elements in `objects` are converted to strings using `str()`.
Both `sep` and `end` must be strings.

*Example:*
```latex
\begin{python}
  tex.log('This text goes to the LaTeX log.')
\end{python}
```

## Requirements
* LuaLaTeX
* Python 3
* Linux, macOS or Windows

## Typesetting Code
Sometimes, in addition to having Python code executed and the output written
to your document, you also want to show the code itself in your document.
PyLuaTeX does not offer any commands or environments that directly typeset code.
However, PyLuaTeX has a **code and output buffer** which you can use to create
your own typesetting functionality.
This provides a lot of flexibility for your typesetting.

After a PyLuaTeX command or environment has been executed, the corresponding
Python code and output can be accessed via the Lua functions
`pyluatex.get_last_code()` and `pyluatex.get_last_output()`, respectively.
Both functions return a Lua [table](https://www.lua.org/pil/2.5.html)
(basically an array) where each table item corresponds to a line of code
or output.

A simple example for typesetting code and output using the *listings* package
would be:
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

\begin{python}[quiet]
  greeting = 'Hello PyLuaTeX!'
  print(greeting)
\end{python}
\pytypeset

\end{document}
```

Notice that we use the `python` environment with the `quiet` option,
which suppresses any output.
After that, the custom command `\pytypeset` is responsible for typesetting
the code and its output.

Using a different code listings package like *minted*, or typesetting inline
code is very easy.
You can also define your own environments that combine Python code and
typesetting. See the `typesetting-*.tex` examples in the `example` folder.

Use the option `repl`, to emulate an interactive Python console/REPL.

## How It Works
PyLuaTeX runs a Python [`InteractiveInterpreter`](https://docs.python.org/3/library/code.html#code.InteractiveInterpreter)
(actually several if you use different sessions) in the background for
on-the-fly code execution. Python code from your LaTeX file is sent to the
background interpreter through a TCP socket. This approach allows your
Python code to be executed and the output to be integrated in your LaTeX
file in a single compilation run. No additional processing steps are needed.
No intermediate files have to be written. No placeholders have to be inserted.

## License
[LPPL 1.3c](http://www.latex-project.org/lppl.txt) for LaTeX code and
[MIT license](https://opensource.org/licenses/MIT) for Python and Lua code
and other files.
