--[[
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
--]]

require("lualibs")
local socket = require("socket")
local pyluatex_parsers = require("pyluatex-parsers")

local cctab_latex = luatexbase.registernumber("catcodetable@latex")
local cctab_atletter = luatexbase.registernumber("catcodetable@atletter")

local pyluatex = {}

-- status.filename: path to pyluatex.sty
local folder = file.pathpart(file.collapsepath(status.filename, true))
local tcp

local env_end
local env_lines
local parent_env

local cmd_handlers = {}

local last_code
local last_output

local options = { {
  executable = "python3",
  localimports = true,
  shutdown = "veryveryend",
  quiet = false,
  repl = false,
  store = true,
  session = "default",
  ignoreerrors = false,
  verbose = false,
} }
local bool_options = set.create({
  "localimports", "quiet", "repl", "store", "ignoreerrors", "verbose"
})
local valid_cmd_keys = set.create({
  "quiet", "repl", "store", "session", "ignoreerrors", "verbose"
})
local key_aliases = {
  ["ignore errors"] = "ignoreerrors",
  ["local imports"] = "localimports",
  q = "quiet",
  s = "session",
}

local function fmt(...)
  return string.format(...)
end

local function show_err(message, ...)
  tex.sprint(
    cctab_latex,
    "\\PackageError{PyLuaTeX}{" .. fmt(message, ...) .. "}{}"
  )
end

local function not_empty(str)
  return str ~= nil and str ~= ""
end

local function parse_option_value(key, value)
  if bool_options[key] ~= nil then
    if value == true then return true end
    value = value:fullstrip()
    if value == "true" then return true
    elseif value == "false" then return false
    else
      return nil, fmt(
        'Option "%s" must be "true" or "false" but is "%s"', key, value
      )
    end
  elseif value ~= true then
    return value
  else
    return nil, fmt('Value missing for option "%s"', key)
  end
end

local function extract_options(str, valid_keys, presets)
  local presets_keys = set.create(table.keys(presets))
  local opts = presets
  local parsed_opts = pyluatex_parsers.parse_options(str)
  if parsed_opts == nil then
    return nil, fmt('Invalid option string: "%s"', str)
  end
  for key, val in pairs(parsed_opts) do
    if key_aliases[key] ~= nil then
      key = key_aliases[key]
    end
    if valid_keys[key] == nil then
      return nil, fmt('Invalid option: "%s"', key)
    elseif presets_keys[key] ~= nil then
      return nil, fmt('Option "%s" not allowed here', key)
    else
      local v, err = parse_option_value(key, val)
      if v == nil then return nil, err end
      opts[key] = v
    end
  end
  return opts
end

function pyluatex.set_options(str, presets, global)
  local opts, err = extract_options(str, valid_cmd_keys, presets)
  if opts == nil then
    show_err(err)
    return
  end
  if global then
    table.merge(options[1], opts)
  else
    for k in pairs(valid_cmd_keys) do
      if opts[k] == nil then opts[k] = options[#options][k] end
    end
    table.insert(options, opts)
  end
end

local function pop_options()
  return table.remove(options)
end

local function split_lines(str)
  local lines = str:splitlines()
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

function pyluatex.shutdown()
  tcp:send("shutdown\n")
end

local function request(data)
  tcp:send(utilities.json.tostring(data) .. "\n")
  local output = tcp:receive("*l")
  return utilities.json.tolua(output)
end

function pyluatex.execute(
  code,
  auto_print,
  catcode_table,
  write,
  repl_mode,
  store,
  session,
  ignore_errors,
  verbose
)
  local full_code
  if auto_print then
    full_code = "print(str(" .. code .. "), end='')"
  else
    full_code = code
  end

  local resp = request({
    session = session,
    code = full_code,
    repl_mode = repl_mode,
    ignore_errors = ignore_errors
  })
  local output_lines = split_lines(resp.output)
  if store then
    last_code = split_lines(code)
    last_output = output_lines
  end

  if verbose or not resp.success then
    texio.write_nl(
      fmt('PyLuaTeX input for session "%s": %s', session, full_code)
    )
    texio.write_nl("PyLuaTeX output: " .. resp.output)
  end

  if not_empty(resp.log_msg) then texio.write(resp.log_msg) end

  if resp.success or ignore_errors then
    if write then tex.print(catcode_table, output_lines) end
  else
    show_err("Python error (see above)")
  end
end

function pyluatex.execute_with_options(code, auto_print, catcode_table)
  local opts = pop_options()
  pyluatex.execute(
    code,
    auto_print,
    catcode_table,
    not opts.quiet,
    opts.repl,
    opts.store,
    opts.session,
    opts.ignoreerrors,
    opts.verbose
  )
end

function pyluatex.opt_arg()
  local t = token.get_next()
  if t.index ~= string.byte("[") then tex.sprint("[]") end
  token.put_next(t)
end

function pyluatex.prepare_cmd_handler(presets, func, ...)
  table.insert(cmd_handlers, {presets = presets, func = func, args = {...}})
end

-- The handler must remove the most recent options with pop_options()
function pyluatex.handle_cmd(opts, content)
  local handler = table.remove(cmd_handlers)
  pyluatex.set_options(opts, handler.presets)
  handler.func(content, table.unpack(handler.args))
end

function pyluatex.execute_env()
  pyluatex.execute_with_options(table.concat(env_lines, "\n"), false, -1)
end

local function record_line(line)
  local s = line:find(env_end)
  if s ~= nil then
    luatexbase.remove_from_callback(
      "process_input_buffer", "pyluatex_record_line"
    )
    local code = line:sub(1, s - 1)
    if code:strip():len() > 0 then
      -- only include this line if it contains non-whitespace characters
      table.insert(env_lines, code)
    end
    return line:sub(s)
  else
    table.insert(env_lines, line)
    return ""
  end
end

function pyluatex.record_env(name)
  if parent_env ~= nil then
    name = parent_env
    parent_env = nil
  end
  env_end = "\\end%s*{" .. name:escapedpattern() .. "}"
  env_lines = {}
  luatexbase.add_to_callback(
    "process_input_buffer", record_line, "pyluatex_record_line"
  )
end

function pyluatex.set_parent_env(name)
  if parent_env == nil then
    parent_env = name
  end
end

function pyluatex.run_file(path)
  local code = io.loaddata(path)
  if code then
    code = code:gsub("\r?\n$", "") -- ignore trailing new line if present
    pyluatex.execute_with_options(code, false, -1)
  else
    show_err('File "%s" not found', path)
  end
end

function pyluatex.py_if(code)
  pyluatex.execute_with_options(
    fmt([[r'\@firstoftwo' if (%s) else r'\@secondoftwo']], code),
    true,
    cctab_atletter
  )
end

function pyluatex.get_last_code()
  return last_code
end

function pyluatex.get_last_output()
  return last_output
end

local function process_package_options()
  local opts, err = extract_options(
    token.get_macro("@raw@opt@pyluatex.sty"),
    set.create(table.keys(options[1])),
    {}
  )
  if opts == nil then
    show_err(err)
    return
  end
  table.merge(options[1], opts)

  local function add_to_hook(hook)
    tex.print(fmt([[\AddToHook{%s}{\directlua{pyluatex.shutdown()}}]], hook))
  end

  if options[1].shutdown == "veryveryend" then
    add_to_hook("enddocument/end")
  elseif options[1].shutdown == "veryenddocument" then
    add_to_hook("enddocument/afteraux")
  elseif options[1].shutdown ~= "off" then
    show_err('Option "shutdown" must be "veryveryend", "veryenddocument", '
      .. 'or "off" but is "%s"', options[1].shutdown)
  end
end

local function get_tex_file_folder()
  for _, v in ipairs(arg) do
    if v:sub(1, 1) ~= "-" then
      local path = file.collapsepath(v, true)
      if lfs.isfile(path) then
        return file.pathpart(path)
      else
        path = file.addsuffix(path, "tex")
        if lfs.isfile(path) then
          return file.pathpart(path)
        end
      end
    end
  end
  return nil
end

function pyluatex.start()
  process_package_options()

  local script = file.join(folder, "pyluatex-interpreter.py")

  local cmd = fmt('%s "%s"', options[1].executable, script)
  if options[1].localimports then
    local tex_file_folder = get_tex_file_folder()
    if tex_file_folder then
      cmd = cmd .. fmt(' "%s"', tex_file_folder)
    end
  end
  if os.type == "windows" then
    cmd = "start /B " .. cmd
  else
    cmd = cmd .. " &"
  end

  local f = io.popen(cmd, "r")
  local port = f:read("*l")
  f:close()

  local function err(message)
    show_err("Python backend could not be started (%s)", message)
  end

  if port == nil then
    err("executable: " .. options[1].executable)
    return
  end
  port = port:fullstrip()
  if port:find("^%d+$") == nil then
    err("invalid TCP port: " .. port)
    return
  end
  tcp = socket.tcp()
  if tcp:connect("127.0.0.1", port) == nil then
    err("TCP connection failed")
  end
end

return pyluatex
