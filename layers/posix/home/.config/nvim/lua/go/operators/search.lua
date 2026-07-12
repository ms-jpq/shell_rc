local fzf = require "go.pack.fzf.lib"
local lib = require "go.lib"
local to = require "go.text_objects"

local magic_escape = function(text)
  local e1 = vim.fn.escape(text, [[\]])
  local e2 = string.gsub(e1, "\t", [[\t]])
  local e3 = string.gsub(e2, lib.LF, [[\n]])
  local e4 = string.gsub(e3, "\r", [[\r]])
  return e4
end

local selected_text = function(visual_type)
  local buf = vim.api.nvim_get_current_buf()
  local row1, col1, row2, col2 = to.operator_marks(buf, visual_type)
  local lines = vim.api.nvim_buf_get_text(0, row1, col1, row2, col2, {})
  local text = table.concat(lines, lib.buf_linefeed(buf))

  return text
end

do
  local candidates = vim.split([[#@~!$%^&*]], "")
  local group = vim.api.nvim_create_augroup([[lv_search]], { clear = true })

  local select_sep = function(text)
    for _, sep in pairs(candidates) do
      if not string.find(text, sep, 1, true) then
        return sep
      end
    end
    return "/"
  end

  Go.op_buf_edit = function(visual_type)
    local text = selected_text(visual_type)
    local escaped = magic_escape(text)
    local sep = select_sep(escaped)
    local reg = [[\V]] .. vim.fn.escape(escaped, sep)
    local line = "%s" .. sep .. reg .. sep .. sep .. "g"
    vim.fn.setreg("/", reg)

    vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
      group = group,
      once = true,
      pattern = ":",
      callback = function()
        vim.fn.setcmdline(line, #line - 1)
      end,
    })
    vim.api.nvim_feedkeys(":", "n", false)
  end

  vim.keymap.set({ "n" }, "gs", [[<cmd>set opfunc=v:lua.Go.op_buf_edit<cr>g@]])
  vim.keymap.set({ "x" }, "gs", to.norm .. [[<cmd>lua Go.op_buf_edit(nil)<cr>]])
end

do
  local searcher = function(kind)
    return function(visual_type)
      local text = selected_text(visual_type)
      local escaped = magic_escape(text)
      vim.fn.setreg("/", [[\V]] .. escaped)
      vim.opt.hlsearch = true

      if kind == "blines" then
        local buf = vim.api.nvim_get_current_buf()
        fzf.blines_search(buf, text)
      else
        fzf.rg_search(text)
      end
    end
  end

  Go.op_blines = searcher "blines"
  Go.op_rg = searcher "rg"

  for key, val in pairs { op_blines = "gF", op_rg = "gf" } do
    vim.keymap.set({ "n" }, val, [[<cmd>set opfunc=v:lua.Go.]] .. key .. [[<cr>g@]], { nowait = true, noremap = true })
    vim.keymap.set({ "x" }, val, to.norm .. [[<cmd>lua Go.]] .. key .. [[(nil)<cr>]], { nowait = true, noremap = true })
  end
end
