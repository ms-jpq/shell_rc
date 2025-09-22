local gs = require("gitsigns")

gs.setup {
  current_line_blame = true
  -- word_diff = true
}

vim.keymap.set("n", "[s", gs.prev_hunk, {noremap = true})
vim.keymap.set("n", "]s", gs.next_hunk, {noremap = true})

vim.keymap.set("n", [[<leader>a]], gs.prev_hunk, {noremap = true})
vim.keymap.set("n", [[<leader>A]], gs.diffthis, {noremap = true})

vim.keymap.set("n", [[<leader>s]], gs.stage_hunk, {noremap = true})
vim.keymap.set("n", [[<leader>S]], gs.undo_stage_hunk, {noremap = true})

vim.keymap.set("n", [[<leader>c]], gs.reset_hunk, {noremap = true})
