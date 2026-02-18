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
require("lualibs")
local pyluatex_parsers = require("pyluatex-parsers")

local overall_result = true

local function compare(opts, expected)
  if opts == nil then return expected == nil end
  if expected == nil then return false end
  return table.identical(opts, expected) and table.identical(expected, opts)
end

local function test_and_print(str, expected)
  local opts = pyluatex_parsers.parse_options(str)
  if not compare(opts, expected) then
    overall_result = false
    print('String: "' .. str .. '"')
    table.print(opts)
  end
end

local function succ(str, expected)
  test_and_print(str, expected)
end

local function fail(str)
  test_and_print(str, nil)
end

succ("", {})
succ("  ", {})
succ("  ,", {})
succ(",  ", {})
succ("  ,  ", {})
succ("key=val", {key = "val"})
succ(" key= val", {key = "val"})
succ("key =val ", {key = "val"})
succ(" key = val ", {key = "val"})
succ(" key key = val", {["key key"] = "val"})
succ(" key\tkey2 = val", {["key\tkey2"] = "val"})
succ('key="val "', {key = "val "})
succ('key= "val "', {key = "val "})
succ('key= "val " ', {key = "val "})
succ('key="1, 2 "', {key = "1, 2 "})
succ('key="1,\n 2 "', {key = "1,\n 2 "})
succ(
  ' tes t=foo, ,,,  key = "he,llo",verbose,quiet',
  {
    ["tes t"] = "foo",
    ["key"] = "he,llo",
    verbose = true,
    quiet = true,
  }
)
fail('key= "val " x')
fail("=no key")
succ("key==value", {key = "=value"})
succ("key=value=value2", {key = "value=value2"})
fail('key= "unclosed')
succ([[key= \"escaped]], {key = '"escaped'})
fail('key = unclosed"val')
succ("{key}=val", {["{key}"] = "val"})
succ("key={valid}key={oops}", {key = "{valid}key={oops}"})
succ("key", {key = true})
succ("key1,key2", {key1 = true, key2 = true})
succ("key1, key2", {key1 = true, key2 = true})
succ(" key1 , key2 ", {key1 = true, key2 = true})
succ("key=a,key=b", {key = "b"})
succ("key1=,key2=b", {key1 = "", key2 = "b"})
succ([[
  key=a,
  x=y,
  key=b
]], {key = "b", x = "y"})
succ("key=a}b", {key = "a}b"})
succ([[key={a\}bx\}cyy}]], {key = [[{a\}bx\}cyy}]]})
succ([[key={a\by\cxx}]], {key = [[{a\by\cxx}]]})
succ([[key="a\"b"]], {key = 'a"b'})
succ(
  [[s="ab",t="cd",u="||\"",v, ]],
  {s = "ab", t = "cd", u = '||"', v = true}
)

if overall_result then os.exit(0) else os.exit(1) end
