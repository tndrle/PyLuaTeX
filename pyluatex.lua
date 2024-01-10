--[[
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
--]]

require("lualibs")
local socket = require("socket")

pyluatex = pyluatex or {
    ignore_errors = false,
    verbose = false,
    session = "default"
}

-- status.filename: path to pyluatex.sty
local folder = file.pathpart(file.collapsepath(status.filename, true))
local tcp = nil

local env_end = nil
local env_lines = nil
local parent_env = nil

local last_code = nil
local last_output = nil

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

local function show_err(message)
    tex.sprint("\\PackageError{PyLuaTeX}{" .. message .. "}{}")
end

local function not_empty(str)
    return str ~= nil and str ~= ""
end

local function split_lines(str)
    local lines = str:splitlines()
    if lines[#lines] == "" then
        table.remove(lines, #lines)
    end
    return lines
end

function pyluatex.start(executable, local_imports)
    local script = file.join(folder, "pyluatex-interpreter.py")

    local cmd = ""
    if local_imports then
        local tex_file_folder = get_tex_file_folder()
        if tex_file_folder ~= nil then
            cmd = ' "' .. tex_file_folder .. '"'
        end
    end
    cmd = executable .. ' "' .. script .. '"' .. cmd
    if os.type == "windows" then
        cmd = "start /B " .. cmd
    else
        cmd = cmd .. " &"
    end
    local f = io.popen(cmd, "r")
    local port = f:read("*l")
    f:close()

    local function err(message)
        show_err("Python backend could not be started (" .. message .. ")")
    end

    if port == nil then
        err("executable: " .. executable)
        return
    end
    port = port:fullstrip()
    if port:match("^%d+$") == nil then
        err("invalid TCP port: " .. port)
        return
    end
    tcp = socket.tcp()
    if tcp:connect("127.0.0.1", port) == nil then
        err("TCP connection failed")
    end
end

function pyluatex.shutdown()
    tcp:send("shutdown\n")
end

local function request(data)
    tcp:send(utilities.json.tostring(data) .. "\n")
    local output = tcp:receive("*l")
    return utilities.json.tolua(output)
end

function pyluatex.execute(code, auto_print, write, repl_mode, store)
    local full_code
    if auto_print then
        full_code = "print(str(" .. code .. "), end='')"
    else
        full_code = code
    end

    local resp = request({
        session = pyluatex.session,
        code = full_code,
        repl_mode = repl_mode,
        ignore_errors = pyluatex.ignore_errors
    })
    local code_lines = split_lines(code)
    local output_lines = split_lines(resp.output)
    if store then
        last_code = code_lines
        last_output = output_lines
    end

    if pyluatex.verbose or not resp.success then
        texio.write_nl('PyLuaTeX input for session "' .. pyluatex.session ..
            '": ' .. full_code)
        texio.write_nl("PyLuaTeX output: " .. resp.output)
    end

    if resp.success or pyluatex.ignore_errors then
        if write then tex.print(output_lines) end
    else
        show_err("Python error (see above)")
    end

    if not_empty(resp.log_msg) then texio.write(resp.log_msg) end
end

function pyluatex.execute_env(write, repl_mode)
    local code = table.concat(env_lines, "\n")
    pyluatex.execute(code, false, write, repl_mode, true)
end

local function record_line(line)
    local s = line:find(env_end)
    if s ~= nil then
        luatexbase.remove_from_callback("process_input_buffer", "pyluatex_record_line")
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
    luatexbase.add_to_callback("process_input_buffer", record_line, "pyluatex_record_line")
end

function pyluatex.set_parent_env(name)
    if parent_env == nil then
        parent_env = name
    end
end

function pyluatex.run_file(path, write, repl_mode)
    local f = io.open(path, "r")
    if f then
        local code = f:read("*a")
        f:close()
        -- ignore trailing new line if present
        if code:sub(-2) == "\r\n" then
            code = code:sub(1, -3)
        elseif code:sub(-1) == "\n" then
            code = code:sub(1, -2)
        end
        pyluatex.execute(code, false, write, repl_mode, true)
    else
        show_err("File not found: " .. path)
    end
end

function pyluatex.get_last_code()
    return last_code
end

function pyluatex.get_last_output()
    return last_output
end

local function parse_bool(name, value)
    value = value:fullstrip()
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    else
        show_err('Invalid value "' .. value .. '" for option "' .. name .. '"')
    end
end

function pyluatex.set_option(name, value)
    name = name:fullstrip()
    if name == "ignoreerrors" then
        pyluatex.ignore_errors = parse_bool(name, value)
    elseif name == "verbose" then
        pyluatex.verbose = parse_bool(name, value)
    else
        show_err('Unknown option "' .. name .. '"')
    end
end

return pyluatex
