local lhs = (function()
  local preview = "%w"
  local ql = "%q"
  local name = "%f"
  local modified = "%m"

  return preview .. ql .. name .. modified
end)()

local classic = (function()
  local ft = "%y"
  local tabs = "%{&tabstop .. (&expandtab ? 'S' : 'T')}"
  local linefeed = "%{&fileformat}"
  local pos = "%5l:%-3c"
  local scroll = "%3p%%"

  return "| " .. ft .. " " .. tabs .. " " .. linefeed .. " @ " .. pos .. "≡ " .. scroll
end)()

Go.lsp_status = function()
  local clients = vim.lsp.get_clients()
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
  end
  return "[" .. table.concat(names, ",") .. "]"
end

local rhs = (function()
  local progress = "%{%v:lua.vim.ui.progress_status()%}"
  local diagnostics = "%{%v:lua.vim.diagnostic.status()%}"
  local lsp_servers = "%{v:lua.lsp_status()}"
  local busy = "%{&busy > 0 ? ' ◐ ' : ' '}"

  return progress .. " " .. diagnostics .. busy .. lsp_servers .. " " .. classic
end)()

vim.opt.statusline = lhs .. " %= " .. rhs
