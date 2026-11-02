local T = require "tests.lib"

T.test({ "post write agent", timeout = 10000 }, function()
  local path = T.file { "base" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local agent_wrote = false
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    callback = function()
      if not agent_wrote then
        agent_wrote = true
        vim.fn.writefile({ "agent" }, path)
      end
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })

  T.eventually(function()
    return agent_wrote
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and vim.deep_equal(vim.fn.readfile(path), { "agent" })
      and not vim.bo.modified
  end, {
    timeout = 4000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
