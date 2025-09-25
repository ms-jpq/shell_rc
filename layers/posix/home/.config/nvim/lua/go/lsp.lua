vim.opt.tagfunc = "v:lua.vim.lsp.tagfunc"
vim.opt.formatexpr = "v:lua.vim.lsp.formatexpr()"

vim.diagnostic.config({virtual_lines = true})
vim.lsp.inlay_hint.enable(true)

if vim.fn.has("nvim-0.12") == 1 then
  vim.lsp.inline_completion.enable(true)
  vim.lsp.linked_editing_range.enable(true)
  vim.lsp.semantic_tokens.enable(true)
end

vim.api.nvim_create_autocmd(
  {"BufEnter", "CursorHold", "InsertLeave"},
  {
    pattern = "<buffer>",
    command = [[silent! lua vim.lsp.codelens.refresh()]]
  }
)

vim.api.nvim_create_autocmd(
  {"CursorHold", "CursorHoldI"},
  {
    pattern = {"<buffer>"},
    command = [[silent! lua vim.lsp.buf.document_highlight()]]
  }
)

vim.api.nvim_create_autocmd(
  {"CursorMoved"},
  {
    pattern = {"<buffer>"},
    command = [[silent! lua vim.lsp.buf.clear_references()]]
  }
)

vim.api.nvim_create_autocmd(
  "LspAttach",
  {
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      if client:supports_method("textDocument/foldingRange") then
        local win = vim.api.nvim_get_current_win()
        vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      end
      if client:supports_method("textDocument/documentColor") then
        if vim.fn.has("nvim-0.12") == 1 then
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
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>d]],
  function()
    vim.diagnostic.setloclist()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>D]],
  function()
    vim.diagnostic.setqflist()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>s]],
  function()
    vim.lsp.buf.document_symbol()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>S]],
  function()
    vim.lsp.buf.workspace_symbol()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  "H",
  function()
    vim.diagnostic.open_float()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  "gp",
  function()
    vim.lsp.buf.definition()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  "gP",
  function()
    vim.lsp.buf.references()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>j]],
  function()
    vim.diagnostic.setloclist()
  end,
  {noremap = true}
)

vim.keymap.set(
  "n",
  [[<leader>J]],
  function()
    vim.lsp.buf.setqflist()
  end,
  {noremap = true}
)
