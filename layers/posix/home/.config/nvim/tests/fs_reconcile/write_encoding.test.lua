local T = require "tests.lib"

T.test({ "write encoding", timeout = 10000 }, function()
  local path = T.file { "café" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "café", "café" })
  vim.bo.fileencoding = "latin1"
  vim.cmd.write()

  assert(vim.fn.readblob(path) == "caf\233\ncaf\233\n")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café", "café" }))
  assert(not vim.bo.modified)

  local fd = assert(vim.uv.fs_open(path, "w", 420))
  assert(vim.uv.fs_write(fd, "caf\233\nagent\n", 0))
  assert(vim.uv.fs_close(fd))
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café", "agent" }) and not vim.bo.modified
  end)

  vim.bo.fileencoding = "utf-8"
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "café", "again" })
  T.eventually(function()
    return vim.fn.readblob(path) == "café\nagain\n" and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        bytes = { string.byte(vim.fn.readblob(path), 1, -1) },
        modified = vim.bo.modified,
        attached = vim.b.__fs_reconcile__ ~= nil,
      }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "café" })
  vim.cmd [[write! ++enc=utf-8]]
  assert(vim.fn.readblob(path) == "café\n")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "café" }))
  assert(not vim.bo.modified)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "wide" })
  local ok, err = pcall(function()
    vim.cmd [[write! ++enc=utf-16le]]
  end)
  assert(ok, vim.inspect { err = err })
  assert(not vim.bo.modified)

  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "wide" })
      and not vim.bo.modified
      and vim.b.__fs_reconcile__ ~= nil
  end, {
    timeout = 1500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readblob(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)
