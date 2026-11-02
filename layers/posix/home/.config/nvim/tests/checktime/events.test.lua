local T = require "tests.lib"

T.test({ "async continuations leave fast callbacks before using Neovim" }, function()
  local async = require "goto.async"
  local states = { vim.in_fast_event() }
  async.scheduled()
  table.insert(states, vim.in_fast_event())
  async.sleep(1)
  table.insert(states, vim.in_fast_event())
  local _, stat = async.uv.fs_stat(T.root)
  assert(stat)
  table.insert(states, vim.in_fast_event())
  async.scheduled()
  table.insert(states, vim.in_fast_event())
  T.eq({ false, false, false, true, false }, states)
end)

T.test({ "edit reload emits read and window events" }, function()
  local events = {}
  vim.api.nvim_create_autocmd(
    { "BufReadPost", "BufFilePost", "FileType", "TextChanged", "TextChangedI", "BufWinEnter" },
    {
      callback = function(event)
        table.insert(events, event.event)
      end,
    }
  )
  vim.cmd.edit(T.file { "dog" })
  events = {}
  vim.cmd [[edit!]]
  T.eq({ "BufReadPost", "BufWinEnter" }, events)
end)

T.test({ "window departure becomes visible on the scheduled turn" }, function()
  vim.cmd.edit(T.file { "dog" })
  local buf = vim.api.nvim_get_current_buf()
  local immediate, scheduled
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf,
    callback = function()
      immediate = #vim.fn.win_findbuf(buf)
      vim.schedule(function()
        scheduled = #vim.fn.win_findbuf(buf)
      end)
    end,
  })
  vim.cmd.enew()
  T.eq(1, immediate)
  T.eventually(function()
    return scheduled ~= nil
  end)
  T.eq(0, scheduled)
end)

for _, operation in ipairs { "name", "file", "saveas" } do
  T.test({ operation .. " announces names without changing buffer text" }, function()
    local before = T.file { "dog" }
    local directory = vim.uv.fs_realpath(T.tempdir())
    assert(type(directory) == "string")
    local after = vim.fs.joinpath(directory, "lil")
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    if operation ~= "name" then
      vim.cmd.edit(before)
      buf = vim.api.nvim_get_current_buf()
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    local events = {}
    vim.api.nvim_create_autocmd({ "BufFilePre", "BufFilePost", "BufWritePre", "BufWritePost" }, {
      buffer = buf,
      callback = function(event)
        T.eq(tick, vim.api.nvim_buf_get_changedtick(buf))
        T.eq(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, true))
        table.insert(events, event.event)
      end,
    })
    if operation == "name" then
      vim.api.nvim_buf_set_name(buf, after)
    elseif operation == "file" then
      vim.cmd.file(after)
    else
      vim.cmd.saveas { after, bang = true }
    end
    local expected = { "BufFilePre", "BufFilePost" }
    if operation == "saveas" then
      vim.list_extend(expected, { "BufWritePre", "BufWritePost" })
    end
    T.eq(expected, events)
    T.eq(after, vim.api.nvim_buf_get_name(buf))
  end)
end
