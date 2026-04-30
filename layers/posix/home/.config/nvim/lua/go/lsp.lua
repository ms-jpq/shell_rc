local lib = require "go"

vim.opt.tagfunc = "v:lua.vim.lsp.tagfunc"
vim.opt.formatexpr = "v:lua.vim.lsp.formatexpr()"

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = function()
    vim.lsp.inlay_hint.enable(true)
    vim.lsp.inline_completion.enable(true)
    vim.lsp.linked_editing_range.enable(true)
    vim.lsp.semantic_tokens.enable(true)
  end,
})

vim.api.nvim_create_autocmd({ "LspAttach" }, {
  group = lib.group,
  callback = function(args)
    if vim.b.__attached__ then
      return
    end
    vim.b.__attached__ = true

    vim.lsp.completion.enable(true, args.data.client_id, args.buf)

    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      group = lib.group,
      buffer = args.buf,
      command = [[silent! lua vim.lsp.codelens.refresh()]],
    })

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      group = lib.group,
      buffer = args.buf,
      command = [[silent! lua vim.lsp.buf.document_highlight()]],
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      group = lib.group,
      buffer = args.buf,
      command = [[silent! lua vim.lsp.buf.clear_references()]],
    })
  end,
})

vim.keymap.set("i", [[<c-f>]], function()
  if not vim.lsp.inline_completion.get() then
    return [[<c-f>]]
  end
end, {
  expr = true,
  replace_keycodes = true,
})

vim.keymap.set("n", [[<leader>a]], function()
  vim.lsp.buf.code_action()
end)

vim.keymap.set("n", [[<leader>s]], function()
  vim.lsp.buf.document_symbol()
end)

vim.keymap.set("n", [[<leader>S]], function()
  vim.lsp.buf.workspace_symbol()
end)

vim.keymap.set("n", "gp", function()
  vim.lsp.buf.definition()
end)

vim.keymap.set("n", "gP", function()
  vim.lsp.buf.references()
end)

vim.keymap.set("n", "L", function()
  vim.lsp.buf.signature_help()
end)
