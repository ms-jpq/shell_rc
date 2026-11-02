local T = require "tests.lib"

T.test({ "concurrent burst", timeout = 10000 }, function()
  local path = T.file { "dog one", "dog two", "dog three" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.cmd [[doautocmd VimEnter]]

  local hunks = require "goto.fs_reconcile.hunks"
  local apply = hunks.apply
  local before_save
  T.patch(hunks, "apply", function(...)
    apply(...)
    before_save = { disk = vim.fn.readfile(path), modified = vim.bo.modified }
  end)

  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "user one" })

  local replace = function(lines)
    local temporary = path .. ".agent-" .. vim.uv.hrtime()
    vim.fn.writefile(lines, temporary)
    assert(vim.uv.fs_rename(temporary, path))
  end

  for index = 1, 32 do
    replace { "dog one", "agent two " .. index, "dog three" }
  end

  local expected = { "user one", "agent two 32", "dog three" }
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
      and not vim.bo.modified
  end, {
    timeout = 3500,
    message = function()
      return vim.inspect {
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })

  T.eq({ disk = { "dog one", "agent two 32", "dog three" }, modified = true }, before_save)
  assert(vim.deep_equal(vim.fn.readfile(path), expected))
  assert(not vim.bo.modified)
end)
