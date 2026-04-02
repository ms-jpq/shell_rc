#!/usr/bin/env -S -- nvim -l

local opt = vim.fs.joinpath(vim.fn.stdpath("cache"), "..", "helix-rt", "nvim", "pack", "opt")
vim.opt.rtp:append {
  vim.fn.stdpath("config"),
  vim.fs.joinpath(opt, "nvim-treesitter"),
  vim.fs.joinpath(opt, "nvim-treesitter-context"),
  vim.fs.joinpath(opt, "nvim-treesitter-textobjects")
}

require("go.paths")
require("go.pack.treesitter")

local ts = require("nvim-treesitter")
local timeout = 5 * 60 * 1000
local languages = {
  "go",
  "javascript",
  "lua",
  "python",
  "ruby",
  "typescript",
  "vim"
}

vim.env.PATH = vim.env.PATH .. ":" .. vim.fs.joinpath(vim.env.HOME, ".local", "asdf", "shims")

ts.install(languages):wait(timeout)
ts.update(languages):wait(timeout)
