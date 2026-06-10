local lib = require "go.lib"

local gs = require "gitsigns"

gs.setup {
  current_line_blame = true,
  -- word_diff = true
}

vim.keymap.set({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>")

vim.keymap.set({ "n" }, "[g", function()
  gs.nav_hunk "prev"
end)
vim.keymap.set({ "n" }, "]g", function()
  gs.nav_hunk "next"
end)

vim.keymap.set({ "n" }, [[<leader>i]], gs.preview_hunk_inline)
vim.keymap.set({ "n" }, [[<leader>I]], gs.diffthis)

vim.keymap.set({ "n" }, [[<leader>e]], gs.stage_hunk)

vim.keymap.set({ "n", "x" }, [[<leader>c]], gs.reset_hunk)

vim.api.nvim_create_autocmd({ "FocusGained" }, { group = lib.group, command = [[Gitsigns refresh]] })
