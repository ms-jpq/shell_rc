local async = require "go.async"
local lib = require "go"

local file_exp_die = function()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if vim.fn.filereadable(name) == 1 then
        bufs[buf] = name
      end
    end
  end

  local current = vim.api.nvim_get_current_buf()
  local cur_name = vim.api.nvim_buf_get_name(current)
  local alt = vim.fn.getreg "#"

  return function()
    local dead = {}
    for buf, name in pairs(bufs) do
      if vim.fn.filereadable(name) == 0 then
        table.insert(dead, buf)
      end
    end

    for _, buf in pairs(dead) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    local altfile = vim.api.nvim_get_current_buf() == current and alt or cur_name
    pcall(vim.fn.setreg, "#", altfile)
  end
end

local termstart = async.wrap(function(buf, cmd, cb)
  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, new_buf)
  if buf then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.api.nvim_buf_call(
    new_buf,
    async(function()
      async.fn.jobstart(cmd, { term = true })
      vim.api.nvim_buf_delete(new_buf, { force = true })
      cb()
    end)
  )
end)

local spawn_yazi = function(buf, path)
  lib.scope(function(defer)
    defer(file_exp_die())

    local tmp = vim.fn.tempname()
    defer(function()
      vim.fs.rm(tmp, { force = true })
    end)

    local cmd = { "yazi", "--chooser-file", tmp, "--", path }
    termstart(buf, cmd)

    if vim.fn.filereadable(tmp) == 1 then
      local selected = vim.fn.readblob(tmp)
      local parsed = string.match(selected, [[.*/(/.*)]]) or selected

      local escaped = vim.fn.fnameescape(parsed)
      vim.cmd.edit(escaped)
    end
  end)
end

local netrw = function(args)
  local name = vim.api.nvim_buf_get_name(args.buf)
  if name ~= "" and vim.fn.isdirectory(name) == 1 then
    async.scheduled()
    if not vim.api.nvim_buf_is_valid(args.buf) then
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

vim.keymap.set({ "n" },
  [[<c-t>]],
  async(function()
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(path) == 0 then
      path = vim.fn.getcwd()
    end
    spawn_yazi(nil, path)
  end)
)

vim.keymap.set({ "n" },
  [[<leader>t]],
  async(function()
    local path = vim.fn.getcwd()
    spawn_yazi(nil, path)
  end)
)
