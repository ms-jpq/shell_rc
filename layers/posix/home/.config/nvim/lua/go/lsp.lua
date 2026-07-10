local lib = require "go.lib"

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

do
  local kind_hl = {
    Class = "@type",
    Constant = "@constant",
    Constructor = "@constructor",
    Enum = "@type",
    EnumMember = "@constant",
    Event = "@type",
    Field = "@variable.member",
    File = "Directory",
    Folder = "Directory",
    Function = "@function",
    Interface = "@type",
    Keyword = "@keyword",
    Method = "@function.method",
    Module = "@module",
    Operator = "@operator",
    Property = "@property",
    Reference = "@string.special",
    Snippet = "@string.special",
    Struct = "@type",
    Text = "@string",
    TypeParameter = "@type.qualifier",
    Unit = "@constant",
    Value = "@constant",
    Variable = "@variable",
  }

  vim.api.nvim_create_autocmd({ "LspAttach" }, {
    group = lib.group,
    callback = function(args)
      if vim.b[args.buf].__attached__ then
        return
      end
      vim.b[args.buf].__attached__ = true

      vim.lsp.completion.enable(true, args.data.client_id, args.buf, {
        convert = function(item)
          local kind = vim.lsp.protocol.CompletionItemKind[item.kind]
          return { kind_hlgroup = kind_hl[kind] }
        end,
      })

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
end

vim.keymap.set({ "i", "s" }, [[<c-f>]], function()
  if not vim.lsp.inline_completion.get() then
    return [[<c-f>]]
  end
end, {
  expr = true,
  replace_keycodes = true,
})

vim.keymap.set({ "n" }, [[<leader>a]], function()
  vim.lsp.buf.code_action()
end)

vim.keymap.set({ "n" }, [[<leader>s]], function()
  vim.lsp.buf.document_symbol()
end)

vim.keymap.set({ "n" }, [[<leader>S]], function()
  vim.lsp.buf.workspace_symbol()
end)

vim.keymap.set({ "n" }, "gp", function()
  vim.lsp.buf.definition()
end)

vim.keymap.set({ "n" }, "gP", function()
  vim.lsp.buf.references()
end)

vim.keymap.set({ "n" }, "L", function()
  vim.lsp.buf.signature_help()
end)
