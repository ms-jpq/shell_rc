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

local window_positions = function(buf)
  return coroutine.wrap(function()
    for _, win in pairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        local row, col = unpack(vim.api.nvim_win_get_cursor(win))
        coroutine.yield { win = win, row = row, col = col }
      end
    end
  end)
end

local hunk_span = function(hunk)
  local old_start, old_count, new_start, new_count = unpack(hunk)
  local old_first = old_start + (old_count == 0 and 1 or 0)
  local old_last = old_start + old_count - 1
  local new_last = new_start + new_count - 1

  return old_first, old_last, old_count, new_start, new_last, new_count
end

local relocate_row = function(row, hunks)
  local shift = 0

  for _, hunk in ipairs(hunks) do
    local old_first, old_last, old_count, _, _, new_count = hunk_span(hunk)

    if row < old_first then
      break
    elseif old_count == 0 then
      shift = shift + new_count
    elseif row > old_last then
      shift = shift + new_count - old_count
    else
      local offset = math.min(row - old_first, math.max(new_count - 1, 0))
      return old_first + shift + offset
    end
  end

  return row + shift
end

local restore_cursor_location = function(buf, positions, hunks)
  local count = vim.api.nvim_buf_line_count(buf)
  for _, spec in pairs(positions) do
    if vim.api.nvim_win_is_valid(spec.win) then
      local row = math.max(1, math.min(relocate_row(spec.row, hunks), count))
      local col = spec.col
      local line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, true))

      col = math.min(col, #line)
      vim.api.nvim_win_set_cursor(spec.win, { row, col })
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
  ---@cast hunks integer[][]

  for hunk in vim.iter(hunks):rev() do
    local old_first, _, old_count, new_start, new_last = hunk_span(hunk)
    local replace = vim.list_slice(lines, new_start, new_last)
    local start = old_first - 1

    vim.api.nvim_buf_set_lines(buf, start, start + old_count, true, replace)
  end

  return hunks
end

local reload = function(buf)
  local lines = read(buf)
  if not lines then
    return false
  end

  local positions = vim.iter(window_positions(buf)):totable()
  local hunks = patch_lines(buf, lines)
  restore_cursor_location(buf, positions, hunks)
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
    vim.cmd.checktime { tostring(buf), mods = { silent = true, emsg_silent = true } }
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

do
  vim.api.nvim_create_autocmd({ "FocusLost", "VimSuspend" }, { group = lib.group, callback = wall })
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, { group = lib.group, once = true, callback = wall })
end

do
  local alive = lib.generation "checktime"
  local interval = 199
  local sweep_every = math.floor(5000 / interval)

  local check = function(buf)
    local args = buf and { tostring(buf) } or {}
    args.mods = { silent = true, emsg_silent = true }
    vim.cmd.checktime(args)
  end

  async.run(function()
    local ticks = 0
    while alive() do
      async.sleep(interval)
      ticks = ticks + 1

      lib.report(function()
        if ticks % sweep_every == 0 then
          check()
        else
          check(vim.api.nvim_get_current_buf())
        end

        wall()
      end)
    end
  end)
end
