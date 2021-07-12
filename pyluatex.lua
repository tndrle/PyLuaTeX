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

local json = require("json")
local socket = require("socket")

pyluatex = pyluatex or {
    verbose = false,
    session = "default"
}

-- status.filename: path to pyluatex.sty
local folder = file.pathpart(file.collapsepath(status.filename, true))
local script = file.join(folder, "interpreter.py")
local tcp = nil

local python_lines = {}

local env_end = "\\end{python}"

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

local function print_input(code)
    texio.write_nl("PyLuaTeX input for session \"" .. pyluatex.session .. "\": " .. code)
end

local function print_output(code)
    texio.write_nl("PyLuaTeX output: " .. code)
end

function pyluatex.execute(code, write)
    if pyluatex.verbose then print_input(code) end

    local success, output = request({ session = pyluatex.session, code = code })
    if success then
        if pyluatex.verbose then print_output(output) end
        if write then
            tex.sprint(output)
        else
            return output
        end
    else
        if not pyluatex.verbose then print_input(code) end
        print_output(output)
        if write then
            tex.sprint(err_cmd("Python error (see above)"))
        end
    end
    return nil
end

local function record_line(line)
    local s, e = line:find(env_end)
    if s ~= nil then
        luatexbase.remove_from_callback("process_input_buffer", "pyluatex_record_line")
        table.insert(python_lines, line:sub(1, s - 1))
        local code = table.concat(python_lines, "\n")
        local output = pyluatex.execute(code, false)
        if output ~= nil then
            return output .. line:sub(s)
        else
            return env_end .. err_cmd("Python error (see above)") .. line:sub(e + 1)
        end
    else
        table.insert(python_lines, line)
        return ""
    end
end

function pyluatex.record_env()
    python_lines = {}
    luatexbase.add_to_callback("process_input_buffer", record_line, "pyluatex_record_line")
end

function pyluatex.run_file(path)
    local f = io.open(path, "r")
    if f then
        local code = f:read("*a")
        f:close()
        pyluatex.execute(code, true)
    else
        tex.sprint(err_cmd("File not found: " .. path))
    end
end

return pyluatex
