local T = require "tests.lib"

T.test({ "continued hunk race", timeout = 10000 }, function()
  local path = T.file { "> hi there" }
  vim.cmd.edit(path)

  local hunks = require "goto.fs_reconcile.hunks"
  local plan = hunks.plan
  local changes = 0
  local apply = hunks.apply
  local before_save
  T.patch(hunks, "apply", function(...)
    apply(...)
    before_save = { disk = vim.fn.readfile(path), modified = vim.bo.modified }
  end)
  T.patch(hunks, "plan", function(...)
    if changes < 2 then
      changes = changes + 1
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { "> hi there", string.rep("*", changes) })
    end
    return plan(...)
  end)

  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]
  T.eventually(function()
    return vim.b.__fs_reconcile__ ~= nil
  end)
  vim.fn.writefile({ "> hi there", "agent" }, path)
  vim.api.nvim_exec_autocmds({ "FileChangedShell" }, { buffer = 0 })

  T.eventually(function()
    return changes == 2
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "> hi there", "**", "agent" })
      and vim.deep_equal(vim.fn.readfile(path), { "> hi there", "**", "agent" })
      and not vim.bo.modified
  end, {
    timeout = 3000,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        changes = changes,
        modified = vim.bo.modified,
      }
    end,
  })

  T.eq({ disk = { "> hi there", "agent" }, modified = true }, before_save)
  assert(vim.deep_equal(vim.fn.readfile(path), { "> hi there", "**", "agent" }))
  assert(not vim.bo.modified)

  hunks.plan = plan
end)
