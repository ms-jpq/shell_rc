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

local selection = function(win)
  local row = unpack(vim.api.nvim_win_get_cursor(win))
  if not string.find(vim.fn.mode(1), "^[vV\22]") then
    return row, row
  end

  local anchor = vim.fn.line "v"
  return math.min(anchor, row), math.max(anchor, row)
end

local metadata = function(buf, target, lo, hi)
  local filename = M.buf_path(buf)
  local paths = vim.iter(vim.fs.parents(filename)):totable()
  table.remove(paths)

  return {
    REPL_ANCESTOR_PATHS = table.concat(paths, ":"),
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
---@param lo integer
---@param hi integer
local pick = function(buf, all, lo, hi)
  local target = vim.b[buf].__repl_target__
  if not all and target and string.find(target, REPL_IFS, 1, true) then
    return target
  end

  local proc = async.system({ exec }, { env = metadata(buf, all and "*" or "", lo, hi) })
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
  return async(function()
    local buf = vim.api.nvim_get_current_buf()
    local lo, hi = selection(0)
    local target = pick(buf, all, lo, hi)
    if not target then
      return
    end

    vim.api.nvim_buf_call(buf, function()
      vim.cmd [[silent! write! ++p]]
    end)
    local proc = async.system({ exec }, { env = metadata(buf, target, lo, hi) })

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
