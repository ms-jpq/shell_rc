local async = require "goto.async"
local merge = require "goto.fs_reconcile.hunks.merge"

local M = {}

---@param linefeed string
---@param base string
---@param local_text string
---@param remote_text string
---@return string
M.merge = function(linefeed, base, local_text, remote_text)
  if local_text == base then
    return remote_text
  elseif remote_text == base then
    return local_text
  end

  return async.work(merge.worker, linefeed, base, local_text, remote_text)
end

return M
