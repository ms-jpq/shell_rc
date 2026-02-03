local lib = require("go")

vim.opt.tagfunc = "v:lua.vim.lsp.tagfunc"
vim.opt.formatexpr = "v:lua.vim.lsp.formatexpr()"

vim.lsp.inlay_hint.enable(true)

if vim.fn.has [[nvim-0.12]] == 1 then
  vim.lsp.linked_editing_range.enable(true)
  vim.lsp.semantic_tokens.enable(true)
end

local virtual_text = true
local virtual_lines = false
vim.diagnostic.config({virtual_text = virtual_text, virtual_lines = virtual_lines})

local toggle = function()
  virtual_text = not virtual_text
  virtual_lines = not virtual_lines
  local conf = {virtual_text = virtual_text, virtual_lines = virtual_lines}
  local text = [[🎱 ]] .. string.gsub(vim.inspect(conf), [[%s]], "")

  vim.diagnostic.config(conf)
  vim.notify(text, vim.log.levels.INFO, {})
end

vim.keymap.set("n", "gO", toggle)
vim.api.nvim_create_user_command("DToggle", toggle, {})

vim.api.nvim_create_autocmd(
  {"BufEnter", "CursorHold", "InsertLeave"},
  {
    group = lib.group,
    pattern = "<buffer>",
    command = [[silent! lua vim.lsp.codelens.refresh()]]
  }
)

vim.api.nvim_create_autocmd(
  {"CursorHold", "CursorHoldI"},
  {
    group = lib.group,
    pattern = {"<buffer>"},
    command = [[silent! lua vim.lsp.buf.document_highlight()]]
  }
)

vim.api.nvim_create_autocmd(
  {"CursorMoved"},
  {
    group = lib.group,
    pattern = {"<buffer>"},
    command = [[silent! lua vim.lsp.buf.clear_references()]]
  }
)

vim.api.nvim_create_autocmd(
  "LspAttach",
  {
    group = lib.group,
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      if client:supports_method("textDocument/foldingRange") then
        local win = vim.api.nvim_get_current_win()
        vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      end
      if client:supports_method("textDocument/documentColor") then
        if vim.fn.has [[nvim-0.12]] == 1 then
          vim.lsp.document_color.enable(true, args.buf)
        end
      end
    end
  }
)

-- vim.lsp.inline_completion.enable(true)

-- vim.keymap.set(
--   "i",
--   [[<c-f>]],
--   function()
--     if not vim.lsp.inline_completion.get() then
--       return [[<c-f>]]
--     end
--   end,
--   {
--     expr = true,
--     replace_keycodes = true
--   }
-- )

vim.keymap.set(
  "n",
  [[<leader>a]],
  function()
    vim.lsp.buf.code_action()
  end
)

vim.keymap.set(
  "n",
  [[<leader>d]],
  function()
    vim.diagnostic.setloclist()
  end
)

vim.keymap.set(
  "n",
  [[<leader>D]],
  function()
    vim.diagnostic.setqflist()
  end
)

vim.keymap.set(
  "n",
  [[<leader>s]],
  function()
    vim.lsp.buf.document_symbol()
  end
)

vim.keymap.set(
  "n",
  [[<leader>S]],
  function()
    vim.lsp.buf.workspace_symbol()
  end
)

vim.keymap.set(
  "n",
  "H",
  function()
    vim.diagnostic.open_float()
  end
)

vim.keymap.set(
  "n",
  "gp",
  function()
    vim.lsp.buf.definition()
  end
)

vim.keymap.set(
  "n",
  "gP",
  function()
    vim.lsp.buf.references()
  end
)

vim.keymap.set(
  "x",
  "+",
  function()
    vim.lsp.buf.selection_range(vim.v.count1)
  end
)

vim.keymap.set(
  "x",
  "_",
  function()
    vim.lsp.buf.selection_range(-vim.v.count1)
  end
)

vim.keymap.set(
  "n",
  "L",
  function()
    vim.lsp.buf.signature_help()
  end
)
