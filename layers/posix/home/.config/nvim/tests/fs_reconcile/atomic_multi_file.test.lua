local T = require "tests.lib"

T.test({ "atomic multi file", timeout = 10000 }, function()
  vim.o.hidden = true

  local first, second = vim.fn.tempname(), vim.fn.tempname()
  vim.fn.writefile({ "first base" }, first)
  vim.fn.writefile({ "second base" }, second)
  vim.cmd.edit(first)
  local first_buf = vim.api.nvim_get_current_buf()
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.cmd.edit(second)
  local second_buf = vim.api.nvim_get_current_buf()
  vim.cmd.edit(first)

  local replace = function(path, lines)
    local temporary = path .. ".agent-" .. vim.uv.hrtime()
    vim.fn.writefile(lines, temporary)
    assert(vim.uv.fs_rename(temporary, path))
  end

  replace(first, { "first agent" })
  replace(second, { "second agent" })

  T.eventually(function()
    return vim.api.nvim_get_current_buf() == first_buf
      and vim.deep_equal(vim.api.nvim_buf_get_lines(first_buf, 0, -1, true), { "first agent" })
      and vim.deep_equal(vim.api.nvim_buf_get_lines(second_buf, 0, -1, true), { "second agent" })
      and not vim.bo[first_buf].modified
      and not vim.bo[second_buf].modified
  end, {
    timeout = 2500,
    message = function()
      return vim.inspect {
        current = vim.api.nvim_get_current_buf(),
        first = vim.api.nvim_buf_get_lines(first_buf, 0, -1, true),
        second = vim.api.nvim_buf_get_lines(second_buf, 0, -1, true),
      }
    end,
  })
end)
