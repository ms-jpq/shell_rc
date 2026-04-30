-- fuzzy search
vim.opt.completeopt:append { "fuzzy", "menuone", "noinsert", "noselect", "preview" }

-- dont follow unloaded buffers and tags
vim.opt.complete:remove { "u", "t" }
vim.opt.complete:append { "Fv:lua.vim.lsp.omnifunc" }


-- basic autocomplete
vim.opt.autocomplete = true
