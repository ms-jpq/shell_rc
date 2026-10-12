#!/usr/bin/env -S -- nvim -l

local cfg = vim.fs.dirname(vim.fs.dirname(arg[0]))
local start = vim.fs.joinpath(vim.fn.stdpath "cache", "..", "helix-rt", "nvim", "pack", "start")
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(start, "nvim-treesitter"),
  vim.fs.joinpath(start, "nvim-treesitter-context"),
  vim.fs.joinpath(start, "nvim-treesitter-textobjects"),
}

require "go.paths"
require "go.pack.treesitter"

do
  local ts = require "nvim-treesitter"
  local log = require "nvim-treesitter.log"
  local languages = vim.json.decode(vim.fn.readblob(vim.fs.joinpath(cfg, "ts-languages.json"))).languages
  local options = { summary = true }
  local timeout = 5 * 60 * 1000

  vim.env.PATH = vim.env.PATH .. ":" .. vim.fs.joinpath(vim.env.HOME, ".local", "asdf", "shims")

  if vim.fn.has "macunix" == 1 then
    options.max_jobs = 1
  end

  vim.print "<<< <<<"
  vim.print(languages)
  local installed = ts.install(languages, options):wait(timeout)
  local updated = ts.update(languages, options):wait(timeout)
  local succ = not installed or not updated
  if not succ then
    log.show()
  end
  vim.print ">>> >>>"
end
