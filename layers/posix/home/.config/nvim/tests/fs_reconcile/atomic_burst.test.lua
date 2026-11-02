local T = require "tests.lib"

T.test({ "atomic burst", timeout = 10000 }, function()
  local path = vim.fn.tempname()
  local final = { "agent 32" }

  local replace = function(lines)
    local temporary = path .. ".agent-" .. vim.uv.hrtime()
    vim.fn.writefile(lines, temporary)
    assert(vim.uv.fs_rename(temporary, path))
  end

  vim.fn.writefile({ "base" }, path)
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local writes = 0
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    callback = function()
      writes = writes + 1
    end,
  })

  for index = 1, 32 do
    replace { "agent " .. index }
  end

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), final)
      and vim.deep_equal(vim.fn.readfile(path), final)
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        writes = writes,
      }
    end,
  })
  assert(writes == 0, vim.inspect { writes = writes })

  replace { "agent after burst" }
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent after burst" })
      and vim.deep_equal(vim.fn.readfile(path), { "agent after burst" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        writes = writes,
      }
    end,
  })
  assert(writes == 0, vim.inspect { writes = writes })
end)
