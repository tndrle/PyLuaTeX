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

local P, S, C, Cc, Cs, Ct = lpeg.P, lpeg.S, lpeg.C, lpeg.Cc, lpeg.Cs, lpeg.Ct

local pyluatex_parsers = {}

local function rstrip(str)
  return (str:gsub("%s*$", ""))
end

local function unescape(str)
  return (str:gsub('\\"', '"'))
end

local sp = S" \t\r\n"^0
local key = (1 - S",=")^1 / rstrip
local escaped_allowed = P'\\"' + 1 - '"'
local quoted = '"' * C(escaped_allowed^0) * '"'
local value = quoted + (escaped_allowed - ",")^0 / rstrip
local pair = sp * key * "=" * sp * Cs(value / unescape) * sp
local flag = sp * key * Cc(true)
local option = (pair + flag + sp) * ","
local options_patt = Ct((sp * option * sp)^0)

-- Returns a table containing the key-value pairs or nil on error.
-- Valueless options (e.g. "verbose" (as opposed to "session=default"))
-- receive a value of true (boolean type).
function pyluatex_parsers.parse_options(str)
  local result = lpeg.match(options_patt, str .. ",")
  if next(result) == nil and str:find("[^%s,]") ~= nil then
    return nil -- matching error
  end

  local t = {}
  for i = 1, #result, 2 do
    t[result[i]] = result[i + 1]
  end
  return t
end

return pyluatex_parsers
