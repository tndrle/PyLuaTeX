--[[
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
--]]

local json = require("pyluatex-json")
local socket = require("socket")

pyluatex = pyluatex or {
    verbose = false,
    session = "default"
}

-- status.filename: path to pyluatex.sty
local folder = file.pathpart(file.collapsepath(status.filename, true))
local script = file.join(folder, "pyluatex-interpreter.py")
local tcp = nil

local env_end = nil
local env_lines = nil
local parent_env = nil

local last_code = nil
local last_output = nil

local function err_cmd(message)
    return "\\PackageError{PyLuaTeX}{" .. message .. "}{}"
end

function pyluatex.start(executable)
    local is_windows = package.config:sub(1,1) ~= "/"
    local cmd
    if is_windows then
        cmd = "start /B " .. executable .. " \"" .. script .. "\""
    else
        cmd = executable .. " \"" .. script .. "\" &"
    end
    local f = io.popen(cmd, "r")
    local port = f:read("*l"):gsub("\r", ""):gsub("\n", "")
    f:close()

    if port then
        tcp = socket.tcp()
        tcp:connect("127.0.0.1", port)
    else
        tex.sprint(err_cmd("Python backend (executable: " .. executable ..
                           ") could not be started"))
    end
end

local function request(data)
    tcp:send(json.encode(data) .. "\n")
    local output = tcp:receive("*l")
    local response = json.decode(output)
    return response.success, response.output
end

local function log_input(code)
    texio.write_nl("PyLuaTeX input for session \"" .. pyluatex.session .. "\": " .. code)
end

local function log_output(code)
    texio.write_nl("PyLuaTeX output: " .. code)
end

local function split_lines(str)
    if str:sub(-1) ~= "\n" then
        str = str .. "\n"
    end

    local t = {}
    for s in str:gmatch("(.-)\r?\n") do
        table.insert(t, s)
    end
    return t
end

function pyluatex.execute(code, auto_print, write)
    local full_code
    if auto_print then
        full_code = "print(str(" .. code .. "), end='')"
    else
        full_code = code
    end

    if pyluatex.verbose then log_input(full_code) end

    local success, output = request({ session = pyluatex.session, code = full_code })
    last_code = split_lines(code)
    last_output = split_lines(output)

    if success then
        if pyluatex.verbose then log_output(output) end

        if write then
            tex.print(last_output)
        end
    else
        if not pyluatex.verbose then log_input(full_code) end
        log_output(output)
        if write then
            tex.sprint(err_cmd("Python error (see above)"))
        end
    end

    return success
end

function pyluatex.print_env()
    if last_output ~= nil then
        tex.print(last_output)
    end
end

local function record_line(line)
    local s, e = line:find(env_end, 1, true)
    if s ~= nil then
        luatexbase.remove_from_callback("process_input_buffer", "pyluatex_record_line")
        table.insert(env_lines, line:sub(1, s - 1))
        local code = table.concat(env_lines, "\n")
        local success = pyluatex.execute(code, false, false)
        if success then
            return line:sub(s)
        else
            return env_end .. err_cmd("Python error (see above)") .. line:sub(e + 1)
        end
    else
        table.insert(env_lines, line)
        return ""
    end
end

function pyluatex.record_env(quiet)
    local name
    if parent_env ~= nil then
        name = parent_env
        parent_env = nil
    else
        if quiet then
            name = "pythonq"
        else
            name = "python"
        end
    end
    env_end = "\\end{" .. name .. "}"
    env_lines = {}
    luatexbase.add_to_callback("process_input_buffer", record_line, "pyluatex_record_line")
end

function pyluatex.set_parent_env(name)
    if parent_env == nil then
        parent_env = name
    end
end

function pyluatex.run_file(path, write)
    local f = io.open(path, "r")
    if f then
        local code = f:read("*a")
        f:close()
        pyluatex.execute(code, false, write)
    else
        tex.sprint(err_cmd("File not found: " .. path))
    end
end

function pyluatex.get_last_code()
    return last_code
end

function pyluatex.get_last_output()
    return last_output
end

return pyluatex
