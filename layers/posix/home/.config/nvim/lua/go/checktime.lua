local async = require "go.async"
local lib = require "go.lib"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true
vim.opt.autoread = false

-- noskip backup
vim.opt.backupskip = ""

local MAX_RELOAD_BYTES = 2 * 1024 * 1024
local reload_ns = vim.api.nvim_create_namespace "go.checktime.reload"

local buffer_marks = function(buf)
  return vim.iter(coroutine.wrap(function()
    for _, win in pairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        local row, col = unpack(vim.api.nvim_win_get_cursor(win))
        coroutine.yield {
          win = win,
          row = row,
          col = col,
          line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, false)),
          mark = vim.api.nvim_buf_set_extmark(buf, reload_ns, row - 1, col, {}),
        }
      end
    end
  end))
end

local preserve_cursor_location = function(buf, marks)
  return function()
    for _, spec in pairs(marks) do
      if vim.api.nvim_win_is_valid(spec.win) then
        local row, col = unpack(vim.api.nvim_buf_get_extmark_by_id(buf, reload_ns, spec.mark, {}))
        if row then
          vim.api.nvim_win_set_cursor(spec.win, { row + 1, col })
        end
      end
    end
  end
end

local preserve_cursor_lines = function(buf, marks, modified)
  if not modified then
    return function()
      return false
    end
  end

  return function()
    local restored = false
    for _, spec in pairs(marks) do
      local row = unpack(vim.api.nvim_buf_get_extmark_by_id(buf, reload_ns, spec.mark, {}))
      if row and spec.line then
        local current = unpack(vim.api.nvim_buf_get_lines(buf, row, row + 1, false))
        if current ~= spec.line and row > 0 then
          row = row - 1
        end
        vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { spec.line })
        if vim.api.nvim_win_is_valid(spec.win) then
          vim.api.nvim_win_set_cursor(spec.win, { row + 1, spec.col })
        end
        restored = true
      end
    end
    return restored
  end
end

local read = function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return nil
  end

  local stat = vim.uv.fs_stat(name)
  if stat and stat.size > MAX_RELOAD_BYTES then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, name)
  return ok and lines or nil
end

local patch_lines = function(buf, lines)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local hunks = vim.text.diff(table.concat(before, lib.LF), table.concat(lines, lib.LF), { result_type = "indices" })

  for hunk in vim.iter(hunks):rev() do
    local old_start, old_count, new_start, new_count = unpack(hunk)
    local start = old_start == 0 and 0 or old_start - 1
    local replace = vim.list_slice(lines, new_start, new_start + new_count - 1)
    vim.api.nvim_buf_set_lines(buf, start, start + old_count, false, replace)
  end
end

local reload = function(buf)
  local lines = read(buf)
  if not lines then
    return false
  end

  vim.api.nvim_buf_clear_namespace(buf, reload_ns, 0, -1)
  local modified = vim.bo[buf].modified
  local marks = buffer_marks(buf):totable()
  local preserve = preserve_cursor_location(buf, marks)
  local preserve_lines = preserve_cursor_lines(buf, marks, modified)

  patch_lines(buf, lines)
  preserve()
  local restored = preserve_lines()

  vim.bo[buf].modified = modified or restored
  return true
end

vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
  group = lib.group,
  callback = function(args)
    if vim.v.fcs_reason ~= "deleted" then
      vim.v.fcs_choice = reload(args.buf) and "" or "edit"
    end
  end,
})

local wall = function()
  vim.cmd [[silent! wall! ++p]]
end

vim.api.nvim_create_autocmd({ "VimLeavePre" }, { group = lib.group, once = true, callback = wall })

local alive = lib.generation "checktime"

do
  local cycle = 99
  local delay = 99
  local focused = true

  local check = function()
    vim.cmd.checktime { mods = { silent = true, emsg_silent = true } }
  end

  local pending = {}
  local drain = lib.throttle(delay, function()
    local fns = pending
    pending = {}

    lib.report(function()
      for _, fn in ipairs { check, wall } do
        if fns[fn] then
          fn()
        end
      end
    end)
  end)

  local schedule = function(actions)
    for _, fn in pairs(actions) do
      pending[fn] = true
    end
    drain()
  end

  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume", "WinEnter" }, {
    group = lib.group,
    callback = function()
      focused = true
      schedule { check }
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusLost", "CursorHold", "CursorHoldI" }, {
    group = lib.group,
    callback = function()
      schedule { check, wall }
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(cycle)

      if not focused or not vim.startswith(vim.api.nvim_get_mode().mode, "i") then
        schedule { check, wall }
      end
    end
  end)
end
