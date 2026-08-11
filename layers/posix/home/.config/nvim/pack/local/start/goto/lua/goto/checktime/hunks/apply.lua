local buffer_state = require "goto.checktime.buffer-state"

local M = {}

local buffer_lines = function(linefeed, records)
  return vim
    .iter(records)
    :map(function(record)
      return string.sub(record, -#linefeed) == linefeed and string.sub(record, 1, -#linefeed - 1) or record
    end)
    :totable()
end

---@param buf integer
---@param current ChecktimeBuffer
---@param replacement ChecktimeReplacement
---@param mark fun(start: integer, finish: integer)
---@return boolean
M.run = function(buf, current, replacement, mark)
  return buffer_state.rewrite(buf, function()
    vim.api.nvim_buf_call(buf, function()
      for index, hunk in vim.iter(replacement.changes):rev():enumerate() do
        if index == #replacement.changes then
          vim.cmd [[let &undolevels=&undolevels]]
        else
          vim.cmd.undojoin()
        end

        local lines = buffer_lines(current.linefeed, hunk.lines)
        vim.api.nvim_buf_set_lines(buf, hunk.start, hunk.finish, true, lines)
        if #lines > 0 then
          mark(hunk.start, hunk.start + #lines)
        end
      end

      if not current.endofline then
        local count = vim.api.nvim_buf_line_count(buf)
        local last = unpack(vim.api.nvim_buf_get_lines(buf, count - 1, count, true))
        if replacement.trailing_empty ~= (count > 1 and last == "") then
          vim.cmd.undojoin()
          vim.api.nvim_buf_set_lines(
            buf,
            replacement.trailing_empty and -1 or -2,
            -1,
            true,
            replacement.trailing_empty and { "" } or {}
          )
        end
      end
    end)
    return true
  end)
end

return M
