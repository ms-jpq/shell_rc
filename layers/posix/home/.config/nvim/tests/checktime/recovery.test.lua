local T = require "tests.lib"

T.test({ "write hook error does not lose the merged snapshot" }, function()
  local path = T.file { "dogs", "cats" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds("VimEnter", {})
  local attempts = 0
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = 0,
    callback = function()
      attempts = attempts + 1
      if attempts == 1 then
        error "expected write failure"
      end
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "small dogs" })
  vim.fn.writefile({ "dogs", "small cats" }, path)
  local expected = { "small dogs", "small cats" }
  T.eventually(function()
    return attempts >= 1
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
      and not vim.bo.modified
  end, {
    message = function()
      return vim.inspect {
        attempts = attempts,
        buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
        disk = vim.fn.readfile(path),
        modified = vim.bo.modified,
      }
    end,
  })
end)

T.test({ "local edit and undo save without TextChanged events" }, function()
  local path = T.file { "dogs" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds("VimEnter", {})
  vim.api.nvim_clear_autocmds { event = { "TextChanged", "TextChangedI", "TextChangedP" } }
  vim.cmd.normal { args = { "Gosmall dogs" }, bang = true }
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "dogs", "small dogs" }) and not vim.bo.modified
  end)
  vim.cmd.undo()
  T.eventually(function()
    return vim.deep_equal(vim.fn.readfile(path), { "dogs" }) and not vim.bo.modified
  end)
end)

T.test({ "disk changes during a read retain the common ancestor" }, function()
  local util = require "goto.fs_reconcile.util"
  local path = T.file { "dogs", "cats", "birds" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds("VimEnter", {})
  local read = util.read_file
  local injected = false
  T.patch(util, "read_file", function(...)
    local observed, state = read(...)
    if observed and observed.text == "dogs\nsmall cats\nbirds" and not injected then
      injected = true
      vim.fn.writefile({ "dogs", "small cats", "small birds" }, path)
    end
    return observed, state
  end)
  vim.api.nvim_buf_set_lines(0, 0, 1, true, { "small dogs" })
  vim.fn.writefile({ "dogs", "small cats", "birds" }, path)
  local expected = { "small dogs", "small cats", "small birds" }
  T.eventually(function()
    return injected
      and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), expected)
      and vim.deep_equal(vim.fn.readfile(path), expected)
      and not vim.bo.modified
  end)
end)

T.test({ "read-only concurrent insertions into empty text retain local-first record order" }, function()
  local path = T.file {}
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds("VimEnter", {})
  vim.bo.readonly = true
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "", "", "", "" })
  vim.fn.writefile({ "dogs" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "", "", "", "", "dogs" })
  end, {
    message = function()
      return vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end,
  })
  T.eq({ "dogs" }, vim.fn.readfile(path))
  assert(vim.bo.modified)
end)

T.test({ "read-only merge retains a final empty record without endofline" }, function()
  local path = T.file { "dogs" }
  vim.cmd.edit(path)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds("VimEnter", {})
  vim.bo.readonly = true
  vim.bo.endofline = false
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "dogs", "" })
  vim.fn.writefile({ "small dogs" }, path)
  T.eventually(function()
    return vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "small dogs", "" })
  end)
  assert(not vim.bo.endofline)
  T.eq({ "small dogs" }, vim.fn.readfile(path))
end)
