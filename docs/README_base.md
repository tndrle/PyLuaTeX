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
   %% EXAMPLE:readme-example.tex %%
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
%% EXAMPLE_FILES %%

## Reference
### Commands
Most of the following commands accept key-value options.
See [Options](#options) for more details.

%% COMMANDS %%

The following commands exist as shortcuts and for backward compatibility with
previous versions of PyLuaTeX:

%% COMMANDS_COMPAT %%

### Environments
%% ENVIRONMENTS %%

Like commands, environments accept key-value options, e.g.
%% TEST:options2 %%
The opening tag `[` must **directly follow** the `\begin{python}`.
Spaces or line breaks between `\begin{python}` and `[` are not allowed.

The following environments exist as shortcuts and for backward
compatibility with previous versions of PyLuaTeX:

%% ENVIRONMENTS_COMPAT %%

### Custom Environments
You can create your own environments based on the `python`, `pythonq` and
`pythonrepl` environments.
However, since those are verbatim environments, you have to use the command
`\PyLTVerbatimEnv` in your environment definition, e.g.
%% TEST:custom-env %%

### Options
Options marked with *package option only* are only valid as package
options in `\usepackage[...]{pyluatex}`.
All other options can be used as package options and throughout the
document.
Options can be set globally using `\pyoptions` or locally for the
various environments and commands.
If a value contains commas, the entire value must be enclosed in
quotation marks.

%% OPTIONS %%

### Logging from Python
```python
tex.log(*objects, sep=' ', end='\n')
```
Writes `objects` to the LaTeX log, separated by `sep` and followed by `end`.
All elements in `objects` are converted to strings using `str()`.
Both `sep` and `end` must be strings.

*Example:*
%% TEST:logging %%

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
%% EXAMPLE:typesetting-example.tex %%

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
