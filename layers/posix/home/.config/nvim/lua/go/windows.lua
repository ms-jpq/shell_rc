-- hide background buffers
vim.opt.hidden = true
-- reuse buf
vim.opt.switchbuf:append("useopen", "usetab")

-- modern split direction
vim.opt.splitright = true
vim.opt.splitbelow = true

-- move between windows
for _, key in pairs {"<c-up>", "<c-k>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd k<cr>]], {noremap = true})
end
for _, key in pairs {"<c-down>", "<c-j>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd j<cr>]], {noremap = true})
end
for _, key in pairs {"<c-left>", "<c-h>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd h<cr>]], {noremap = true})
end
for _, key in pairs {"<c-right>", "<c-l>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd l<cr>]], {noremap = true})
end

-- kill current buf
vim.keymap.set("n", [[<leader>x]], "<cmd>bwipeout!<cr>", {noremap = true})

-- kill current tab
vim.keymap.set("n", [[<leader>q]], "<cmd>tabclose<cr>", {noremap = true})

-- swap windows
vim.keymap.set("n", [[<leader>']], [[<cmd>wincmd r<cr>]], {noremap = true})
vim.keymap.set("n", [[<leader>;]], [[<cmd>wincmd R<cr>]], {noremap = true})

-- move windows
vim.keymap.set("n", [[<s-m-left>]], [[<cmd>wincmd H<cr>]], {noremap = true})
vim.keymap.set("n", [[<s-m-right>]], [[<cmd>wincmd L<cr>]], {noremap = true})
vim.keymap.set("n", [[<s-m-up>]], [[<cmd>wincmd K<cr>]], {noremap = true})
vim.keymap.set("n", [[<s-m-down>]], [[<cmd>wincmd J<cr>]], {noremap = true})

-- resize windows
vim.keymap.set("n", [[+]], [[<cmd>wincmd =<cr>]], {noremap = true})
vim.keymap.set("n", [[<s-left>]], [[<cmd>wincmd <<cr>]], {noremap = true})
vim.keymap.set("n", [[<s-right>]], [[<cmd>wincmd ><cr>]], {noremap = true})
vim.keymap.set("n", [[<s-up>]], [[<cmd>wincmd +<cr>]], {noremap = true})
vim.keymap.set("n", [[<s-down>]], [[<cmd>wincmd -<cr>]], {noremap = true})

-- cycle between tabs
vim.keymap.set("n", "<leader>[", [[<cmd>tabprevious<cr>]], {noremap = true})
vim.keymap.set("n", "<leader>]", [[<cmd>tabnext<cr>]], {noremap = true})

-- pick tab
vim.keymap.set("n", "<leader>0", "g<tab>", {noremap = true})
for i = 1, 9 do
  vim.keymap.set("n", [[<leader>]] .. i, [[<cmd>tabnext ]] .. i .. [[<cr>]], {noremap = true})
end

vim.api.nvim_create_autocmd({"VimResized"}, {command = [[wincmd =]]})

-- locallist
-- vim.keymap.set("n", [[<c-a>]], [[<cmd>lprevious<cr>]], {noremap = true})
-- vim.keymap.set("n", [[<c-e>]], [[<cmd>lnext<cr>]], {noremap = true})

-- quickfix
vim.keymap.set("n", [[<c-p>]], [[<cmd>cprevious<cr>]], {noremap = true})
vim.keymap.set("n", [[<c-n>]], [[<cmd>cnext<cr>]], {noremap = true})

local toggle_qf = function(lo)
  return function()
    local closed = false
    local wins = vim.api.nvim_tabpage_list_wins(0)

    for _, win in pairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      if ft == "qf" then
        vim.api.nvim_win_close(win, true)
        closed = true
      end
    end

    if not closed then
      local height = vim.o.previewheight
      vim.cmd([[copen ]] .. height)
    end
  end
end

vim.keymap.set("n", [[<leader>l]], toggle_qf(true), {noremap = true})
