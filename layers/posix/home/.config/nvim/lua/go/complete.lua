-- dont follow unloaded buffers and tags
vim.opt.complete:remove { "u", "t" }

vim.opt.completeopt:append { "fuzzy", "menuone", "noinsert", "noselect", "preview" }
