-- vim.env.FZF_DEFAULT_OPTS = vim.env.FZF_DEFAULT_OPTS .. " --no-border"

local lib = require "go.lib"

vim.g.fzf_layout = {
  window = {
    width = 0.96,
    height = 0.96,
  },
}

local preview = vim.fs.joinpath(lib.HOME, ".local", "libexec", "preview.sh")

local function shelljoin(args)
  return vim.iter(args):map(vim.fn.shellescape):join " "
end

local run = function(name, spec)
  vim.fn["fzf#run"](vim.fn["fzf#wrap"](name, spec, true))
end

local opts = function(map)
  return vim.iter(map):fold({}, function(list, flag, value)
    table.insert(list, "--" .. string.gsub(flag, "_", "-"))
    if value ~= true then
      table.insert(list, value)
    end
    return list
  end)
end

local jump = function(entry)
  if type(entry.filename) == "string" then
    vim.cmd.edit(vim.fn.fnameescape(entry.filename))
  elseif type(entry.bufnr) == "number" then
    local win = vim.fn.bufwinid(entry.bufnr)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    else
      vim.cmd.buffer(entry.bufnr)
    end
  end

  if type(entry.lnum) == "number" then
    vim.api.nvim_win_set_cursor(0, { entry.lnum, (type(entry.col) == "number" and entry.col or 1) - 1 })
  end
end

local sink = function(parse)
  return function(lines)
    local entries = vim.iter(lines):map(parse):totable()

    if #entries == 1 then
      jump(entries[1])
    elseif #entries > 1 then
      vim.fn.setqflist(entries)
      vim.cmd.copen()
    end
  end
end

vim.keymap.set({ "n" }, [[<leader>b]], function()
  local items = vim
    .iter(vim.fn.getbufinfo { buflisted = 1 })
    :map(function(b)
      local name = b.name ~= "" and vim.fn.fnamemodify(b.name, [[:~:.]]) or "[No Name]"
      return b.bufnr .. "\t" .. name
    end)
    :totable()
  run("buffers", {
    source = items,
    options = opts {
      multi = true,
      delimiter = "\t",
      with_nth = "2..",
      nth = "2..",
      preview = preview .. " {2..}",
      preview_window = "right:wrap",
    },
    ["sink*"] = sink(function(line)
      local bufnr = tonumber(string.match(line, "^(%d+)\t"))

      if type(bufnr) == "number" then
        return { bufnr = bufnr, text = string.gsub(line, "^%d+\t", "") }
      end
    end),
  })
end)

do
  local file_opts = opts { preview = preview .. " {}", preview_window = "right:wrap" }
  local file_sink = sink(function(line)
    return { filename = line }
  end)

  vim.keymap.set({ "n" }, [[<leader>f]], function()
    run("files", {
      source = shelljoin { "fd", "--hidden", "--no-ignore-parent", "--type=f", "--" },
      options = file_opts,
      ["sink*"] = file_sink,
    })
  end)

  vim.keymap.set({ "n" }, [[<leader>G]], function()
    run("gfiles", { source = "git ls-files", options = file_opts, ["sink*"] = file_sink })
  end)

  vim.keymap.set({ "n" }, [[<leader>g]], function()
    run("gstatus", {
      source = shelljoin { "git", "status", "--short", "--untracked-files=all" },
      options = opts {
        multi = true,
        preview = preview .. " {2..} --diff",
        preview_window = "right:wrap",
      },
      ["sink*"] = sink(function(line)
        local path = string.sub(line, 4)
        local arrow = string.find(path, " %-> ")
        if arrow then
          path = string.sub(path, arrow + 4)
        end
        if path ~= "" then
          return { filename = path }
        end
      end),
    })
  end)
end

do
  local marks = function(list, want)
    local items, by_letter = {}, {}
    vim
      .iter(list)
      :filter(function(m)
        return string.match(string.sub(m.mark, 2), want) ~= nil
      end)
      :each(function(m)
        local letter = string.sub(m.mark, 2)
        local bufnr, lnum, col = unpack(m.pos)
        local entry = { lnum = lnum, col = col }
        if bufnr ~= 0 and vim.api.nvim_buf_is_loaded(bufnr) then
          local line = unpack(vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, true))
          entry.bufnr = bufnr
          entry.text = string.gsub(line, "^%s+", "")
        elseif m.file and m.file ~= "" then
          entry.filename = vim.fn.fnamemodify(m.file, [[:~:.]])
          entry.text = entry.filename
        end
        by_letter[letter] = entry
        table.insert(items, string.format("%s  %d:%d  %s", letter, lnum, col, entry.text or ""))
      end)

    if #items == 0 then
      return
    end
    run("marks", {
      source = items,
      options = opts { multi = true, no_sort = true },
      ["sink*"] = sink(function(line)
        return by_letter[string.match(line, "^(%S)")]
      end),
    })
  end

  vim.keymap.set({ "n" }, [[<leader>j]], function()
    marks(vim.fn.getmarklist(vim.api.nvim_get_current_buf()), "%l")
  end)

  vim.keymap.set({ "n" }, [[<leader>J]], function()
    marks(vim.fn.getmarklist(), "%u")
  end)
end

do
  local rg_args = shelljoin {
    "rg",
    "--fixed-strings",
    "--with-filename",
    "--column",
    "--line-number",
    "--no-heading",
    "--color=always",
    "--smart-case",
    "--",
  }

  local live_grep = function(reload)
    run("rg", {
      source = "true",
      options = opts {
        ansi = true,
        multi = true,
        disabled = true,
        delimiter = ":",
        bind = "change:reload:" .. reload .. " || true",
        preview = shelljoin { "bat", "--force-colorization", "--highlight-line", "{2}", "--", "{1}" },
        preview_window = "right:wrap:~3:+{2}+3/3",
      },
      ["sink*"] = sink(function(line)
        local file, lnum, col, text = string.match(line, "^(.-):(%d+):(%d+):(.*)")
        if type(file) == "string" then
          return { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = text }
        end
      end),
    })
  end

  vim.keymap.set({ "n" }, [[<leader>?]], function()
    live_grep(rg_args .. " {q}")
  end)

  vim.keymap.set({ "n" }, [[<leader>/]], function()
    local buf = vim.api.nvim_get_current_buf()
    local absname = vim.api.nvim_buf_get_name(buf)

    if vim.fn.filereadable(absname) ~= 0 then
      local name = vim.fn.shellescape(vim.fn.fnamemodify(absname, [[:~:.]]))
      live_grep(rg_args .. " {q} " .. name)
      return
    end

    local items = vim
      .iter(vim.api.nvim_buf_get_lines(buf, 0, -1, true))
      :enumerate()
      :map(function(i, line)
        return i .. "\t" .. line
      end)
      :totable()

    run("blines", {
      source = items,
      options = opts {
        ansi = true,
        multi = true,
        delimiter = "\t",
        with_nth = "2..",
        nth = "2..",
      },
      ["sink*"] = sink(function(line)
        local lnum, text = string.match(line, "^(%d+)\t(.*)")
        if type(lnum) == "string" then
          return { bufnr = buf, lnum = tonumber(lnum), col = 1, text = text }
        end
      end),
    })
  end)
end
