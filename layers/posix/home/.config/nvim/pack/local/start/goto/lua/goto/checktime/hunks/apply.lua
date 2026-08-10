local feedback = require "goto.checktime.feedback"

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
---@param text string
---@param changes ChecktimeHunk[]
---@param mark fun(start: integer, finish: integer)
---@return boolean
M.run = function(buf, current, text, changes, mark)
  return feedback.rewrite(buf, function()
    vim.api.nvim_buf_call(buf, function()
      for index, hunk in vim.iter(changes):rev():enumerate() do
        if index == #changes then
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
        local ending = string.sub(text, -#current.linefeed) == current.linefeed
        if ending ~= (count > 1 and last == "") then
          vim.cmd.undojoin()
          vim.api.nvim_buf_set_lines(buf, ending and -1 or -2, -1, true, ending and { "" } or {})
        end
      end
    end)
    return true
  end)
end

return M
