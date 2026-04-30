-- dont follow unloaded buffers and tags
vim.opt.complete:remove { "u", "t" }
vim.opt.complete:append { "o" }

vim.opt.completeopt:append { "fuzzy", "menuone", "noinsert", "noselect", "preview" }

-- basic autocomplete
vim.opt.autocomplete = true
