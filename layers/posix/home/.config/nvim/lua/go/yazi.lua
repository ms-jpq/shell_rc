local async = require "go.async"
local lib = require "go.lib"

local termstart = async.wrap(function(buf, cmd, cb)
  local new_buf = vim.api.nvim_create_buf(false, true)
  lib.keepalt_buffer(new_buf)
  if buf then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.api.nvim_buf_call(
    new_buf,
    async(function()
      local _, code = async.fn.jobstart(cmd, { term = true })
      if code == 0 then
        vim.api.nvim_buf_delete(new_buf, { force = true })
      end
      cb()
    end)
  )
end)

local yazi_sh = vim.fs.joinpath(lib.HOME, ".local", "libexec", "yazi.sh")

local chooser_path = function(line)
  return string.match(line, "^search://[^/]*/(.*)$") or line
end

local spawn_yazi = function(buf, path)
  lib.scope(function(defer)
    local tmp = vim.fn.tempname()
    defer(function()
      vim.fs.rm(tmp, { force = true })
    end)

    termstart(buf, { yazi_sh, "--chooser-file", tmp, "--", path })

    if vim.fn.filereadable(tmp) == 1 then
      local selected = vim.fn.readblob(tmp)
      local parsed = unpack(vim.split(selected, lib.LF, { plain = true, trimempty = true }))

      if parsed then
        vim.cmd.edit { vim.fn.fnameescape(chooser_path(parsed)), mods = { keepalt = true } }
      end
    end
  end)
end

local netrw = function(args)
  local win = vim.api.nvim_get_current_win()
  local name = vim.api.nvim_buf_get_name(args.buf)
  if name ~= "" and vim.fn.isdirectory(name) == 1 then
    async.scheduled()
    if not vim.api.nvim_buf_is_valid(args.buf) then
      return
    end
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= args.buf then
      return
    end

    vim.opt.cursorline = false
    vim.opt.cursorcolumn = false
    spawn_yazi(args.buf, name)
    vim.opt.cursorline = true
  end
end

-- replace directory buffers with yazi
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = async(function()
    async.scheduled()
    vim.api.nvim_create_autocmd({ "BufEnter" }, { group = lib.group, callback = async(netrw) })
  end),
})

vim.keymap.set(
  { "n" },
  [[<c-t>]],
  async(function()
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(path) == 0 then
      path = vim.fn.getcwd()
    end
    spawn_yazi(nil, path)
  end)
)

vim.keymap.set(
  { "n" },
  [[<leader>t]],
  async(function()
    local path = vim.fn.getcwd()
    spawn_yazi(nil, path)
  end)
)
