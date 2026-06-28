#!/usr/bin/env -S -- nvim -l

local cfg = vim.fs.dirname(vim.fs.dirname(arg[0]))
vim.opt.rtp:append { cfg }

local libexec = require "go.libexec"
local filetypes = libexec.filetypes()

local mapping = {}
for ft, exts in pairs(filetypes) do
  for _, ext in ipairs(exts) do
    mapping["." .. ext] = ft
  end
end

local json = libexec.json_encode(mapping)
io.stdout:write(json)
