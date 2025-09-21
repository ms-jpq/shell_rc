-- hide background buffers
vim.opt.hidden = true
-- reuse buf
vim.opt.switchbuf:append("useopen", "usetab")

-- modern split direction
vim.opt.splitright = true
vim.opt.splitbelow = true

-- move between windows
for _, key in pairs {"<c-up>", "<c-k>"} do
  vim.keymap.set("n", key, "<cmd>wincmd k<cr>", {noremap = true})
end
for _, key in pairs {"<c-down>", "<c-j>"} do
  vim.keymap.set("n", key, "<cmd>wincmd j<cr>", {noremap = true})
end
for _, key in pairs {"<c-left>", "<c-h>"} do
  vim.keymap.set("n", key, "<cmd>wincmd h<cr>", {noremap = true})
end
for _, key in pairs {"<c-right>", "<c-l>"} do
  vim.keymap.set("n", key, "<cmd>wincmd l<cr>", {noremap = true})
end

-- close
vim.keymap.set("n", "<c-w><c-c>", "<cmd>wincmd c<cr>", {noremap = true})

-- kill current buf
vim.keymap.set("n", "<leader>x", "<cmd>bwipeout!<cr>", {noremap = true})

-- swap windows
vim.keymap.set("n", "<leader>'", "<cmd>wincmd r<cr>", {noremap = true})
vim.keymap.set("n", "<leader>;", "<cmd>wincmd R<cr>", {noremap = true})

-- move windows
vim.keymap.set("n", "<s-m-left>", "<cmd>wincmd H<cr>", {noremap = true})
vim.keymap.set("n", "<s-m-right>", "<cmd>wincmd L<cr>", {noremap = true})
vim.keymap.set("n", "<s-m-up>", "<cmd>wincmd K<cr>", {noremap = true})
vim.keymap.set("n", "<s-m-down>", "<cmd>wincmd J<cr>", {noremap = true})

-- resize windows
vim.keymap.set("n", "+", "<cmd>wincmd =<cr>", {noremap = true})
vim.keymap.set("n", "<s-left>", "<cmd>wincmd <<cr>", {noremap = true})
vim.keymap.set("n", "<s-right>", "<cmd>wincmd ><cr>", {noremap = true})
vim.keymap.set("n", "<s-up>", "<cmd>wincmd +<cr>", {noremap = true})
vim.keymap.set("n", "<s-down>", "<cmd>wincmd -<cr>", {noremap = true})

vim.api.nvim_create_autocmd({"VimResized"}, {command = [[wincmd =]]})
