#!/usr/bin/env -S -- nvim -l

local jit = require "jit"
local bin = vim.env.BIN

local repo = [[JohnnyMorganz/StyLua]]
local prefix = [[https://github.com/]] .. repo .. [[/releases/latest/download/stylua]]
local arch = jit.arch == [[arm64]] and [[aarch64]] or [[x86_64]]

local uri = (function()
  if vim.fn.has [[win32]] == 1 or vim.fn.has [[win32unix]] == 1 then
    return prefix .. "-windows-" .. arch .. ".zip"
  elseif vim.fn.has [[mac]] == 1 then
    return prefix .. "-macos-" .. arch .. ".zip"
  else
    return prefix .. "-linux-" .. arch .. ".zip"
  end
end)()

local std = function(out, err)
  for _, txt in pairs { o = out, e = err } do
    print(txt)
  end
end

local proc1 = vim.system({ "get.sh", uri }, { stderr = std }):wait()
assert(proc1.code == 0, vim.inspect(proc1))

vim.fn.mkdir(bin, "p")

local proc2 = vim.system({ "unpack.sh", bin, proc1.stdout }, { stdout = std, stderr = std }):wait()
assert(proc2.code == 0, vim.inspect(proc2))
