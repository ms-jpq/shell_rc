local lib = require "goto.lib"

local M = {}

M.HOME = vim.uv.os_homedir() or ""
M.cfg = vim.fn.stdpath "config"

M.sandbox = function(workdir, opts)
  if lib.is_win or false then
    return {}
  end

  local nice = vim.fs.joinpath(M.HOME, ".local", "libexec", "supernice.sh")
  local exec = vim.fs.joinpath(M.HOME, ".local", "libexec", "sandbox", "libexec", "dispatch.sh")
  local net = opts.network and { "--network" } or {}
  return vim.iter({ { nice }, { exec }, net, { "--dir", workdir, "--" } }):flatten():totable()
end

M.pack = function(name)
  local ret = {}
  if _G.Go.pack[name] ~= false then
    lib.report(function()
      ret = { require("go.pack." .. name) }
    end)
  end
  return unpack(ret)
end

return M
