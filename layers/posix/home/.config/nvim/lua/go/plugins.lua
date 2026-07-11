vim.opt.loadplugins = false
vim.g.no_plugin_maps = 1

local man = unpack(vim.api.nvim_get_runtime_file("plugin/man.*", true))
vim.cmd.source { args = { man } }

local parens = unpack(vim.api.nvim_get_runtime_file("plugin/matchparen.vim", true))
vim.cmd.source { args = { parens } }

vim.cmd.packadd [[matchit]]
