local gs = require("gitsigns")

gs.setup {
  current_line_blame = true
  -- word_diff = true
}

vim.keymap.set("n", "[g", gs.prev_hunk, {noremap = true})
vim.keymap.set("n", "]g", gs.next_hunk, {noremap = true})

vim.keymap.set("n", [[<leader>i]], gs.preview_hunk_inline, {noremap = true})
vim.keymap.set("n", [[<leader>I]], gs.diffthis, {noremap = true})

vim.keymap.set("n", [[<leader>e]], gs.stage_hunk, {noremap = true})
vim.keymap.set("n", [[<leader>E]], gs.undo_stage_hunk, {noremap = true})

vim.keymap.set("n", [[<leader>c]], gs.reset_hunk, {noremap = true})
