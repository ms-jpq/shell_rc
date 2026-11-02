local T = require "tests.lib"

return function(command)
  vim.cmd.enew { bang = true }
  local first, second = T.file { "first" }, T.file { "agent" }
  vim.cmd.edit(first)
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    buffer = 0,
    once = true,
    callback = function()
      vim.cmd.file(vim.fn.fnameescape(second))
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "local" })
  local ok, err = pcall(function()
    vim.cmd(command)
  end)
  return {
    ok = ok,
    error = not ok and type(err) == "string" and string.match(err, "E%d+:") or nil,
    first = vim.fn.readfile(first),
    second = vim.fn.readfile(second),
    buffer = vim.api.nvim_buf_get_lines(0, 0, -1, true),
    modified = vim.bo.modified,
  }
end
