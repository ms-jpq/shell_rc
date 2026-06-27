local lib = require "go.lib"

local esc = "\027"
local tmux = vim.env.TMUX
local ssh = vim.env.SSH_TTY

local osc52 = function(data)
  local acc = {}

  -- TMUX wrap start
  if tmux then
    table.insert(acc, esc .. "Ptmux;")
  end

  -- TMUX escape `esc`
  if tmux then
    table.insert(acc, esc)
  end

  -- OSC52 start
  table.insert(acc, esc .. "]52;c;")

  -- OSC52 body
  table.insert(acc, data)

  -- TMUX escape `esc`
  if tmux then
    table.insert(acc, esc)
  end

  -- OSC52 end
  table.insert(acc, esc .. [[\]])

  -- TMUX wrap end
  if tmux then
    table.insert(acc, esc .. [[\]])
  end

  return table.concat(acc, "")
end

local send = function(stdin, ...)
  vim.system({ ... }, { stdin = stdin })
end

local recv = function(text, ...)
  local sep = lib.buf_linefeed(0)
  local proc = vim.system({ ... }, { text = text }):wait()
  return vim.split(proc.stdout, sep, { plain = true })
end

local copy = function(lines)
  local sep = lib.buf_linefeed(0)
  local s = table.concat(lines, sep)

  if tmux then
    send(s, "tmux", "load-buffer", "-w", "--", "-")
  elseif ssh then
    local b = vim.base64.encode(s)
    vim.api.nvim_chan_send(2, osc52(b))
  elseif vim.fn.has [[mac]] == 1 then
    send(s, "pbcopy")
  elseif vim.fn.has [[unix]] == 1 then
    send(s, "wl-copy")
  end
end

local paste = function()
  -- vim.api.nvim_chan_send(2, osc52("?"))
  if not ssh then
    if vim.fn.has [[mac]] == 1 then
      return recv(false, "pbpaste")
    elseif vim.fn.has [[unix]] == 1 then
      return recv(false, "wl-paste")
    elseif lib.is_win then
      local pwsh = {
        "powershell.exe",
        "-NoProfile",
        "-Command",
        "Get-Clipboard -Raw",
      }
      return recv(true, unpack(pwsh))
    end
  end
  if tmux then
    return recv(false, "tmux", "save-buffer", "-")
  end
  return {}
end

vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
  name = "OSC 52",
  cache_enabled = true,
  copy = {
    ["+"] = copy,
    ["*"] = copy,
  },
  paste = {
    ["+"] = paste,
    ["*"] = paste,
  },
}

local undo_quoting = function(line)
  return vim.split(line, "\027%[27;5;106~", { plain = true })
end

vim.paste = (function(paste)
  return function(lines, p)
    local acc = vim.iter(lines):map(undo_quoting):flatten():totable()
    if vim.fn.pumvisible() == 1 then
      vim.cmd.stopinsert()
      vim.cmd.startinsert { bang = true }
    end
    return paste(acc, p)
  end
end)(vim.paste)
