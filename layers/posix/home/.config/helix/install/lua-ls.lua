#!/usr/bin/env -S -- nvim -l

local jit = require "jit"
local run, lib = vim.env.RUN, vim.env.LIB

local repo = [[LuaLS/lua-language-server]]
local base = [[https://github.com/]] .. repo .. [[/releases/latest/download/lua-language-server]]
local version = vim.system({ "gh-latest.sh", ".", repo }):wait().stdout
local prefix = base .. "-" .. version

local uri = (function()
  if vim.fn.has [[win32]] == 1 or vim.fn.has [[win32unix]] == 1 then
    return prefix .. "-win32-" .. jit.arch .. ".zip"
  elseif vim.fn.has [[mac]] == 1 then
    return prefix .. "-darwin-" .. jit.arch .. ".tar.gz"
  else
    return prefix .. "-linux-" .. jit.arch .. ".tar.gz"
  end
end)()

local std = function(out, err)
  for _, txt in pairs { o = out, e = err } do
    print(txt)
  end
end

local proc1 = vim.system({ "get.sh", uri }, { stderr = std }):wait()
assert(proc1.code == 0, vim.inspect(proc1))

local proc2 = vim.system({ "unpack.sh", run, proc1.stdout }, { stdout = std, stderr = std }):wait()
assert(proc2.code == 0, vim.inspect(proc2))

vim.fs.rm(lib, { recursive = true, force = true })
local cp = vim.system({ "cp", "-r", "--", run, lib }, { stdout = std, stderr = std }):wait()
assert(cp.code == 0, vim.inspect(cp))
