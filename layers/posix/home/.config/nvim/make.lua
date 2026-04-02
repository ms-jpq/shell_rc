#!/usr/bin/env -S -- nvim -l

vim.opt.rtp:append(vim.fn.stdpath("config"))

local ts = vim.fs.joinpath(vim.fn.stdpath("cache"), "..", "helix-rt", "nvim", "pack", "opt", "nvim-treesitter")
vim.opt.rtp:append(ts)

require("go.paths")
require("go.pack.treesitter")
require("nvim-treesitter").install {"all"}:wait(5 * 60 * 1000)
