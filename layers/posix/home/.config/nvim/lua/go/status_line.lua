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
  local acc = {}
  for _, client in ipairs(clients) do
    table.insert(acc, client.name)
  end
  table.sort(acc, function(l, r)
    return vim.stricmp(l, r) < 0
  end)
  return "[" .. table.concat(acc, " ") .. "]"
end

local rhs = (function()
  local progress = "%{%v:lua.vim.ui.progress_status()%}"
  local diagnostics = "%{%v:lua.vim.diagnostic.status()%}"
  local lsp_servers = "%{v:lua.Go.lsp_status()}"
  local busy = "%{&busy > 0 ? ' ◐ ' : ' '}"

  return progress .. " " .. diagnostics .. busy .. lsp_servers .. " " .. classic
end)()

vim.opt.statusline = lhs .. " %= " .. rhs
