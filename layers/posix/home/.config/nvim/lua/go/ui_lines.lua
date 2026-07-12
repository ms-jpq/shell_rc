do
  local lhs = (function()
    local preview = "%w"
    local ql = "%q"
    local name = "%f"

    return preview .. ql .. name
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
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if #clients == 0 then
      return ""
    end
    local acc = vim
      .iter(clients)
      :map(function(client)
        return client.name
      end)
      :totable()
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
end

do
  local tab_file = function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local path = vim.fn.pathshorten(vim.fn.fnamemodify(name, [[:~:.]]))
    local escaped = string.gsub(path, "%%", "%%%%")

    return escaped == "" and [[∅]] or escaped
  end

  Go.tabline = function()
    local current = vim.api.nvim_get_current_tabpage()

    local sections = coroutine.wrap(function()
      for _, tab in pairs(vim.api.nvim_list_tabpages()) do
        local nr = vim.api.nvim_tabpage_get_number(tab)
        local win = vim.api.nvim_tabpage_get_win(tab)
        local buf = vim.api.nvim_win_get_buf(win)
        local hl = tab == current and "%#TabLineSel#" or "%#TabLine#"
        local filename = tab_file(buf)

        coroutine.yield("%" .. nr .. "T" .. hl .. nr .. " " .. filename .. " ")
      end

      coroutine.yield "%#TabLineFill#%T"
    end)

    return table.concat(vim.iter(sections):totable())
  end

  vim.opt.tabline = [[%!v:lua.Go.tabline()]]
end
