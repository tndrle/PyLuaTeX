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

package.path = package.path .. ";../?.lua"
kpse.set_program_name("luatex") -- find files under texmf tree, e.g. lualibs
luatexbase = { -- dummy
  registernumber = function() end
}
local pyluatex = require("pyluatex")

local overall_result = true

local err_msg = nil
tex = {
  sprint = function(_n, str) err_msg = str end
}

local function evaluate(expected_err_msg)
  if expected_err_msg == nil and err_msg ~= nil then return false end
  if expected_err_msg ~= nil and err_msg == nil then return false end
  if err_msg ~= nil then
    local exp = "\\PackageError{PyLuaTeX}{" .. expected_err_msg .. "}{}"
    if err_msg ~= exp then return false end
  end
  return true
end

local function test(str, presets, expected_err_msg)
  err_msg = nil
  pyluatex.set_options(str, presets or {}, false)
  if not evaluate(expected_err_msg) then
    overall_result = false
    print('String: "' .. str .. '"')
    print('Exp. error message: "' .. (expected_err_msg or "") .. '"')
    print('Error message:      "' .. (err_msg or "") .. '"')
  end
end

test("verbose")
test("verbose=true")
test("verbose=false")
test("verbose=true ")
test("verbose= true")
test('verbose="true"')
test('verbose= "true" ')
test('verbose=" true "')
test("verbose={true }", {},
  'Option "verbose" must be "true" or "false" but is "{true }"')
test("verbose=True", {},
  'Option "verbose" must be "true" or "false" but is "True"')
test("verbose=x", {},
  'Option "verbose" must be "true" or "false" but is "x"')
test("verbose", { verbose = true }, 'Option "verbose" not allowed here')

test("session", {}, 'Value missing for option "session"')
test("foo", {}, 'Invalid option: "foo"')
test("session={x}y")

test("s", {}, 'Value missing for option "session"')
test("s=test-session")
test("s=foo", { session = "bar" }, 'Option "session" not allowed here')
test("q=foo", {}, 'Option "quiet" must be "true" or "false" but is "foo"')

if overall_result then os.exit(0) else os.exit(1) end
