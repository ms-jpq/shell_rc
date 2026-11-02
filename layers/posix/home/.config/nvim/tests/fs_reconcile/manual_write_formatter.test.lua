local T = require "tests.lib"

T.test({ "manual write formatter", timeout = 10000 }, function()
  local path = T.file { "dog" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local formatted = false
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      if not formatted then
        formatted = true
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { "DOG" })
      end
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  vim.cmd.write()
  T.eventually(function()
    return formatted and vim.deep_equal(vim.fn.readfile(path), { "DOG" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect { disk = vim.fn.readfile(path), formatted = formatted, modified = vim.bo.modified }
    end,
  })

  vim.fn.writefile({ "agent" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" }) and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
