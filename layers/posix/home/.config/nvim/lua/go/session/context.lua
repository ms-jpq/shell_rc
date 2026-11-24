local async = require "goto.async"
local lib = require "goto.lib"

local M = {}

M.startup_cwd = vim.fn.getcwd()

local dir = vim.fs.joinpath(vim.fn.stdpath "cache", "sessions")
local cwd = vim.fn.sha256(M.startup_cwd)

local instance = vim.fn.sha256(vim.fn.tempname())

local context = { cwd, "none", "none", "none" }
local refresh = function()
  if vim.env.TMUX and vim.env.TMUX_PANE then
    local result = async.system {
      "tmux",
      "display-message",
      "-p",
      "-t",
      vim.env.TMUX_PANE,
      table.concat({ [[#{session_name}]], [[#{window_index}]], [[#{pane_index}]] }, lib.US),
    }
    async.scheduled()
    local output = string.gsub(result.stdout or "", lib.LF .. "$", "")
    local name, window, pane = unpack(vim.split(output, lib.US, { plain = true }))

    if result.code == 0 and name and window and pane then
      context = { cwd, vim.fn.sha256(name), window, pane }
    end
  end

  return context
end

M.save_path = function(update)
  if update then
    refresh()
  end
  return vim.fs.joinpath(dir, table.concat(context, ".") .. "." .. instance .. ".vim")
end

M.restore_path = function()
  refresh()
  local candidates = vim.fn.globpath(dir, cwd .. "*.vim", false, true)

  local best, best_rank, best_time = nil, 0, -1
  for _, candidate in pairs(candidates) do
    local parts = vim.split(vim.fs.basename(candidate), ".", { plain = true })
    local rank = 0
    for i, value in ipairs(context) do
      if parts[i] ~= value then
        break
      end
      rank = i
    end
    local time = vim.fn.getftime(candidate)
    if rank > 0 and time >= 0 and (rank > best_rank or rank == best_rank and time > best_time) then
      best, best_rank, best_time = candidate, rank, time
    end
  end
  return best
end

return M
