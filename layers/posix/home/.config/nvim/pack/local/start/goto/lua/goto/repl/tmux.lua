local async = require "goto.async"
local lib = require "goto.lib"

local M = {}

local separator = string.gsub(vim.fn.tempname(), "/", "-")
local socket = vim.env.__TMUX_ROOT_SOCKET__ or string.match(vim.env.TMUX or "", "^[^,]+")

M.CURRENT_PANE = vim.env.__TMUX_ROOT_PANE__ or vim.env.TMUX_PANE

---@class ReplPane
---@field active boolean
---@field id string
---@field location string
---@field order integer
---@field path string
---@field same_window boolean

local call = function(args)
  local argv = vim.list_extend({ "tmux", "-S", socket }, args)
  local proc = async.system(argv)
  return proc.stdout
end

local fields = {
  "#{pane_id}",
  "#{window_id}",
  "#{window_active}",
  "#{session_name} -> #{window_index} -> #{pane_index}",
  "#{?#{pane_path},#{pane_path},#{pane_current_path}}",
}

M.panes = function()
  assert(socket and M.CURRENT_PANE)

  local window = call { "display-message", "-t", M.CURRENT_PANE, "-p", "-F", "#{window_id}" }
  local listed = call { "list-panes", "-a", "-F", table.concat(fields, separator) }
  local current_window = string.match(window, "%S+")

  return vim
    .iter(vim.gsplit(listed, lib.LF, { plain = true, trimempty = true }))
    :enumerate()
    :map(function(order, line)
      local id, window_id, active, location, path = unpack(vim.split(line, separator, { plain = true }))
      if id ~= M.CURRENT_PANE then
        return {
          active = active == "1",
          id = id,
          location = location,
          order = order,
          path = path,
          same_window = window_id == current_window,
        }
      end
    end)
    :totable()
end

return M
