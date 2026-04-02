#!/usr/bin/env -S -- nvim -l

local cfg = vim.fn.stdpath("config")
local opt = vim.fs.joinpath(vim.fn.stdpath("cache"), "..", "helix-rt", "nvim", "pack", "opt")
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(opt, "nvim-treesitter"),
  vim.fs.joinpath(opt, "nvim-treesitter-context"),
  vim.fs.joinpath(opt, "nvim-treesitter-textobjects")
}

require("go.paths")
require("go.pack.treesitter")

local ts = require("nvim-treesitter")
local languages = vim.json.decode(vim.fn.readblob(vim.fs.joinpath(cfg, "ts-languages.json")))
local timeout = 5 * 60 * 1000

vim.env.PATH = vim.env.PATH .. ":" .. vim.fs.joinpath(vim.env.HOME, ".local", "asdf", "shims")

vim.print("<<< <<<")
vim.print(languages)
ts.install(languages):wait(timeout)
ts.update(languages):wait(timeout)
vim.print(">>> >>>")
