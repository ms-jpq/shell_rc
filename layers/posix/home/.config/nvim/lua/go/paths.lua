local lib = require "go.lib"

local pathsep = lib.is_win and ";" or ":"
local home = vim.uv.os_homedir()
local runtime = vim.fs.joinpath(home, ".cache", "helix-rt")

local paths = {
  vim.fs.joinpath(vim.fn.stdpath "config", "bin"),
  vim.fn.globpath(runtime, "{more,go}/*/bin", true, true),
  vim.env.PATH,
  vim.fn.globpath(runtime, "{ruby,php}/*/bin", true, true),
  vim.fn.globpath(runtime, "nodejs/*/node_modules/.bin", true, true),
  vim.fn.globpath(runtime, "python/*/venv/{Scripts,bin}", true, true),
}

local flat = vim.iter(paths):flatten():totable()
vim.env.PATH = table.concat(flat, pathsep)
