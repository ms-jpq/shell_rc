#!/usr/bin/env -S -- nvim -l

local ts = vim.fs.joinpath(vim.fn.stdpath("cache"), "..", "helix-rt", "nvim", "pack", "opt", "nvim-treesitter")
vim.opt.rtp:prepend(ts)

require("nvim-treesitter").install {"all"}:wait(5 * 60 * 1000)
