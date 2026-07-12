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
  return coroutine.wrap(function()
    for _, win in pairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        local row, col = unpack(vim.api.nvim_win_get_cursor(win))
        coroutine.yield {
          win = win,
          row = row,
          col = col,
          mark = vim.api.nvim_buf_set_extmark(buf, reload_ns, row - 1, col, {}),
        }
      end
    end
  end)
end

local restore_cursor_location = function(buf, marks)
  for _, spec in pairs(marks) do
    if vim.api.nvim_win_is_valid(spec.win) then
      local row, col = unpack(vim.api.nvim_buf_get_extmark_by_id(buf, reload_ns, spec.mark, {}))
      local count = vim.api.nvim_buf_line_count(buf)

      if not row or row < 0 then
        row, col = spec.row - 1, spec.col
      end
      row = math.min(row, count - 1)

      if row >= 0 then
        local line = unpack(vim.api.nvim_buf_get_lines(buf, row, row + 1, true))
        col = math.min(col, #line)
        vim.api.nvim_win_set_cursor(spec.win, { row + 1, col })
      end
    end
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
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local hunks = vim.text.diff(table.concat(before, lib.LF), table.concat(lines, lib.LF), { result_type = "indices" })

  for hunk in vim.iter(hunks):rev() do
    local old_start, old_count, new_start, new_count = unpack(hunk)
    local start = old_count == 0 and old_start or old_start - 1
    local replace = vim.list_slice(lines, new_start, new_start + new_count - 1)
    vim.api.nvim_buf_set_lines(buf, start, start + old_count, true, replace)
  end
end

local reload = function(buf)
  local lines = read(buf)
  if not lines then
    return false
  end

  vim.api.nvim_buf_clear_namespace(buf, reload_ns, 0, -1)
  local marks = vim.iter(buffer_marks(buf)):totable()

  patch_lines(buf, lines)
  restore_cursor_location(buf, marks)
  vim.bo[buf].modified = false

  return true
end

local delete_or_recheck = function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  async.sleep(66)

  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if name ~= "" and vim.uv.fs_stat(name) then
    vim.cmd.checktime { args = { tostring(buf) }, mods = { silent = true, emsg_silent = true } }
  else
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
  group = lib.group,
  callback = async(function(args)
    if vim.v.fcs_reason == "changed" or vim.v.fcs_reason == "conflict" then
      if reload(args.buf) then
        vim.v.fcs_choice = ""
      else
        vim.v.fcs_choice = "edit"
      end
    elseif vim.v.fcs_reason == "deleted" then
      vim.v.fcs_choice = ""
      delete_or_recheck(args.buf)
    else
      vim.v.fcs_choice = ""
    end
  end),
})

local wall = function()
  vim.cmd [[silent! wall! ++p]]
end

vim.api.nvim_create_autocmd({ "VimLeavePre" }, { group = lib.group, once = true, callback = wall })

do
  local alive = lib.generation "checktime"
  local cycle = 299
  local delay = 99

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
      schedule { check, wall }
    end
  end)
end
