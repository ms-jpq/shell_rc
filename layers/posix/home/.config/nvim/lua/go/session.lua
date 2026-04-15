local async = require "go.async"
local lib = require "go"

-- limit session restoration info
vim.opt.sessionoptions:remove { "blank", "buffers", "curdir", "help", "terminal" }
vim.opt.sessionoptions:append { "skiprtp" }

-- scratch buffer
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_get_name(buf) == "" then
    vim.bo[buf].buftype = "nofile"
  end
end

local detect_stdin = function(cwd)
  local acc = {}
  for _, name in pairs(vim.fn.argv(-1)) do
    local path = vim.fs.joinpath(cwd, name)
    local norm = vim.fs.normalize(path, { expand_env = false })
    acc[norm] = true
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local dirty = function()
      if vim.api.nvim_buf_line_count(buf) > 1 then
        return true
      end

      local lines = vim.api.nvim_buf_get_lines(buf, -2, -1, true)
      return #lines > 0 and #lines[1] > 0
    end

    local name = vim.api.nvim_buf_get_name(buf)
    if not acc[name] and dirty() then
      return true
    end
  end

  return false
end

local no_session = (function()
  local cached = nil

  return function(cwd)
    if cwd == "" then
      return true
    end

    if cached ~= nil then
      return cached
    end

    cached = vim.fn.getcwd() == vim.uv.os_homedir() or vim.wo.diff or detect_stdin(cwd)

    return cached
  end
end)()

local session_path = function(cwd)
  local argv = vim.fn.argv(-1)
  local name = vim.re.gsub(cwd or vim.fn.getcwd(), "[/\\]", ".")
  local postfix = table.concat(argv, "&")
  local dir = vim.fs.joinpath(vim.fn.stdpath "cache", "sessions", name)
  local path = vim.fs.joinpath(dir, postfix .. ".vim")

  local norm = vim.fs.normalize(path, { expand_env = false })
  local escaped = vim.fn.fnameescape(norm)
  return norm, escaped
end

local mk_session = function(kill)
  local cwd = vim.fn.getcwd()
  if not kill and no_session(cwd) then
    return
  end

  local path, escaped = session_path(cwd)
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p")
  vim.fn.setfperm(parent, [[rwxr-xr-x]])

  vim.cmd([[mksession! ]] .. escaped)
end

local prune_buffers = function()
  local dead = {}
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if vim.fn.filereadable(name) == 0 then
        table.insert(dead, buf)
      end
    end
  end

  for _, buf in pairs(dead) do
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

vim.api.nvim_create_user_command("PS", function()
  prune_buffers()
  mk_session(true)
end, {})

vim.api.nvim_create_user_command("KS", function()
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  mk_session(true)
end, {})

vim.api.nvim_create_autocmd({ "VimSuspend", "FocusLost", "CursorHold" }, { group = lib.group, callback = mk_session })

vim.api.nvim_create_autocmd({ "QuitPre" }, {
  group = lib.group,
  once = true,
  callback = function()
    if no_session(nil) then
      return
    end

    prune_buffers()
    mk_session()
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = async(function()
    async.scheduled()

    local cwd = vim.fn.getcwd()
    if no_session(cwd) then
      return
    end

    local path, escaped = session_path(cwd)
    if vim.fn.filereadable(path) == 1 then
      vim.cmd([[silent! source ]] .. escaped)
    end
  end),
})
