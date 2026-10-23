local async = require "goto.async"
local cmds = require "goto.commands"
local lib = require "goto.lib"

local M = {}

local REPL_IFS = string.char(31)
local exec = assert(unpack(vim.api.nvim_get_runtime_file("libexec/repl.sh", false)))

do
  local tag = "__goto_repl_path__"
  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPre" }, {
    group = lib.group,
    callback = function(args)
      if args.file ~= "" and not vim.b[args.buf][tag] then
        vim.b[args.buf][tag] = vim.fs.abspath(args.file)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufFilePost", {
    group = lib.group,
    callback = function(args)
      vim.b[args.buf][tag] = vim.fs.abspath(args.file)
    end,
  })

  M.buf_path = function(buf)
    return vim.b[buf][tag] or vim.fs.abspath(vim.api.nvim_buf_get_name(buf))
  end
end

local column = function(buf, row, bytes)
  local line = unpack(vim.api.nvim_buf_get_lines(buf, row - 1, row, true))
  return vim.fn.strchars(string.sub(line, 1, bytes)) + 1
end

local selection = function(win, args)
  local buf = vim.api.nvim_win_get_buf(win)
  local mode = vim.fn.mode(1)

  if string.find(mode, "^[vV\22]") then
    local region = vim.fn.getregionpos(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode, eol = true })
    local first, last = unpack(region[1]), unpack(region[#region], 2)
    local _, lo, col_lo = unpack(first)
    local _, hi, col_hi = unpack(last)
    local location = string.format("%d:%d-%d:%d", lo, column(buf, lo, col_lo - 1), hi, column(buf, hi, col_hi))
    return lo, hi, location
  end

  if args and args.range > 0 then
    local lo, hi = args.line1, args.line2
    return lo, hi, string.format("%d:1-%d:%d", lo, hi, column(buf, hi, -1))
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  return row, row, string.format("%d:%d", row, column(buf, row, col))
end

local metadata = function(buf, target, lo, hi, location)
  local filename = M.buf_path(buf)
  local paths = vim.iter(vim.fs.parents(filename)):totable()
  table.remove(paths)

  return {
    REPL_ANCESTOR_PATHS = table.concat(paths, ":"),
    REPL_LOCATION = location,
    REPL_FILE_NAME = filename,
    REPL_IFS = REPL_IFS,
    REPL_LINE_COUNT = tostring(vim.api.nvim_buf_line_count(buf)),
    REPL_PARENT_PATH = vim.fs.dirname(filename),
    REPL_PRETTY_NAME = vim.fn.fnamemodify(filename, [[:~]]),
    REPL_SELECT_HI = tostring(hi),
    REPL_SELECT_LO = tostring(lo),
    REPL_TARGET = target,
  }
end
---@param buf integer
---@param all? boolean
---@param env table<string, string>
local pick = function(buf, all, env)
  local target = vim.b[buf].__repl_target__
  if not all and target and string.find(target, REPL_IFS, 1, true) then
    return target
  end

  env.REPL_TARGET = all and "*" or ""
  local proc = async.system({ exec }, { env = env })
  async.scheduled()
  if proc.code ~= 0 or proc.stderr ~= "" then
    vim.notify(proc.stderr .. proc.stdout, vim.log.levels.ERROR)
    return
  end
  if proc.stdout == "" then
    vim.notify([[🚫]], vim.log.levels.ERROR)
    return
  end

  local choices = vim.split(proc.stdout, "\0", { plain = true, trimempty = true })
  if #choices == 0 then
    return nil
  end
  async.scheduled()
  target = async.ui.select(choices, {
    format_item = function(choice)
      local line = string.gsub(choice, "^[^" .. REPL_IFS .. "]*" .. REPL_IFS, "")
      return string.gsub(line, REPL_IFS, " ")
    end,
  })
  vim.b[buf].__repl_target__ = target
  return target
end

---@param all? boolean
---@return fun()
local run_repl = function(all)
  return async(function(args)
    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    if vim.api.nvim_buf_get_name(buf) == "" or (buftype ~= "" and buftype ~= "acwrite") then
      return
    end
    local lo, hi, location = selection(0, args)
    local env = metadata(buf, "", lo, hi, location)

    vim.api.nvim_buf_call(buf, function()
      vim.cmd [[silent write! ++p]]
    end)

    local target = pick(buf, all, env)
    if not target then
      return
    end

    env.REPL_TARGET = target
    local proc = async.system({ exec }, { env = env })

    async.scheduled()
    vim.notify(proc.stdout, vim.log.levels.INFO)
    vim.notify(proc.stderr, vim.log.levels.ERROR)
  end)
end

local clear = function()
  vim.b.__repl_target__ = nil
end

cmds.register {
  repl = run_repl(false),
  ["repl-all"] = run_repl(true),
  ["repl-clear"] = clear,
}

return M
