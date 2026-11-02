local T = require "tests.lib"

T.test({ "symlink", timeout = 10000 }, function()
  local root = vim.fn.tempname()
  local target_dir = vim.fs.joinpath(root, "target")
  local target = vim.fs.joinpath(target_dir, "file")
  local link = vim.fs.joinpath(root, "link")
  assert(vim.uv.fs_mkdir(root, 493))
  assert(vim.uv.fs_mkdir(target_dir, 493))
  vim.fn.writefile({ "before" }, target)
  assert(vim.uv.fs_symlink(target, link, { junction = false }))

  vim.cmd.edit(link)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  vim.fn.writefile({ "agent" }, target)

  T.eventually(function()
    return vim.endswith(vim.api.nvim_buf_get_name(0), "/link")
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "agent" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        name = vim.api.nvim_buf_get_name(0),
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, true),
      }
    end,
  })

  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  T.eventually(function()
    local status = vim.uv.fs_lstat(link)
    return status ~= nil
      and status.type == "link"
      and vim.endswith(vim.api.nvim_buf_get_name(0), "/link")
      and vim.deep_equal(vim.fn.readfile(target), { "local" })
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        link = vim.uv.fs_lstat(link),
        name = vim.api.nvim_buf_get_name(0),
        target = vim.fn.readfile(target),
      }
    end,
  })
end)
