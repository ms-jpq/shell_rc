local T = require "tests.lib"

T.test({ "endofline representation", timeout = 10000 }, function()
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"
  local path = vim.fn.tempname()

  local write = function(text)
    local fd = assert(vim.uv.fs_open(path, "w", 420))
    assert(vim.uv.fs_write(fd, text, 0))
    assert(vim.uv.fs_close(fd))
  end

  for _, case in ipairs {
    { file = "", expected = { text = "", endofline = false } },
    { file = "\n", expected = { text = "", endofline = true } },
    { file = "a", expected = { text = "a", endofline = false } },
    { file = "a\n", expected = { text = "a", endofline = true } },
    { file = "a\n\n", expected = { text = "a\n", endofline = true } },
  } do
    write(case.file)
    vim.cmd.edit(path)
    local snapshot = assert(util.read_file(0, path))
    assert(vim.deep_equal({ text = snapshot.text, endofline = snapshot.endofline }, case.expected), vim.inspect(case))
  end

  assert(vim.deep_equal(util.from_text "a\n", { text = "a", endofline = true }))
  assert(
    vim.deep_equal(util.format_output({ text = "a", endofline = false }, "b\n"), { text = "b", endofline = false })
  )

  assert(
    util.merge_endofline(
      { text = "", endofline = false },
      { text = "", endofline = false },
      { text = "", endofline = true }
    )
  )
  assert(
    util.merge_endofline(
      { text = "", endofline = false },
      { text = "", endofline = true },
      { text = "", endofline = false }
    )
  )
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "a", "" })
  vim.bo.endofline = false
  assert(
    vim.deep_equal(
      util.buffer(0),
      { text = "a\n", endofline = false, changedtick = vim.api.nvim_buf_get_changedtick(0) }
    )
  )

  vim.bo.endofline = true
  assert(
    vim.deep_equal(
      util.buffer(0),
      { text = "a\n", endofline = true, changedtick = vim.api.nvim_buf_get_changedtick(0) }
    )
  )

  vim.bo.endofline = false
  assert(vim.deep_equal(util.empty(0), { text = "", endofline = false, encoding = vim.o.encoding }))

  vim.bo.endofline = true
  assert(vim.deep_equal(util.empty(0), { text = "", endofline = true, encoding = vim.o.encoding }))

  vim.bo.endofline = false
  local replacement = hunks.plan(util.buffer(0), { text = "a\nb", endofline = true })
  hunks.apply(0, replacement, function() end)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "a", "b" }))
  assert(vim.bo.endofline)
end)
