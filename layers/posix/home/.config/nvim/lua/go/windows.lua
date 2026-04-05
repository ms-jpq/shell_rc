local lib = require("go")

-- hide background buffers
vim.opt.hidden = true
-- reuse buf
vim.opt.switchbuf:append("useopen", "usetab")

-- modern split direction
vim.opt.splitright = true
vim.opt.splitbelow = true

-- move between windows
for _, key in pairs {"<c-up>", "<c-k>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd k<cr>]])
end
for _, key in pairs {"<c-down>", "<c-j>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd j<cr>]])
end
for _, key in pairs {"<c-left>", "<c-h>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd h<cr>]])
end
for _, key in pairs {"<c-right>", "<c-l>"} do
  vim.keymap.set("n", key, [[<cmd>wincmd l<cr>]])
end

-- kill current buf
vim.keymap.set("n", [[<leader>x]], "<cmd>bwipeout!<cr>")

-- kill current win
vim.keymap.set("n", [[<c-w><c-q>]], "<cmd>wincmd c<cr>")

-- kill current tab
vim.keymap.set("n", [[<leader>q]], "<cmd>tabclose<cr>")

-- swap windows
vim.keymap.set("n", [[<leader>']], [[<cmd>wincmd r<cr>]])
vim.keymap.set("n", [[<leader>;]], [[<cmd>wincmd R<cr>]])

-- move windows
vim.keymap.set("n", [[<s-m-left>]], [[<cmd>wincmd H<cr>]])
vim.keymap.set("n", [[<s-m-right>]], [[<cmd>wincmd L<cr>]])
vim.keymap.set("n", [[<s-m-up>]], [[<cmd>wincmd K<cr>]])
vim.keymap.set("n", [[<s-m-down>]], [[<cmd>wincmd J<cr>]])

-- resize windows
vim.keymap.set("n", [[+]], [[<cmd>wincmd =<cr>]])
vim.keymap.set("n", [[<s-left>]], [[<cmd>wincmd <<cr>]])
vim.keymap.set("n", [[<s-right>]], [[<cmd>wincmd ><cr>]])
vim.keymap.set("n", [[<s-up>]], [[<cmd>wincmd +<cr>]])
vim.keymap.set("n", [[<s-down>]], [[<cmd>wincmd -<cr>]])

-- cycle between tabs
vim.keymap.set("n", "<leader>[", [[<cmd>tabprevious<cr>]])
vim.keymap.set("n", "<leader>]", [[<cmd>tabnext<cr>]])

-- pick tab
vim.keymap.set("n", "<leader>0", "g<tab>")
for i = 1, 9 do
  vim.keymap.set("n", [[<leader>]] .. i, [[<cmd>tabnext ]] .. i .. [[<cr>]])
end

vim.api.nvim_create_autocmd(
  {"VimResized"},
  {
    group = lib.group,
    command = [[wincmd =]]
  }
)

-- pin quickfix to window
vim.api.nvim_create_autocmd(
  {"FileType"},
  {
    group = lib.group,
    pattern = {"qf"},
    command = [[setlocal winfixbuf]]
  }
)

-- locallist
-- vim.keymap.set("n", [[<c-a>]], [[<cmd>lprevious<cr>]])
-- vim.keymap.set("n", [[<c-e>]], [[<cmd>lnext<cr>]])

-- quickfix
vim.keymap.set("n", [[<c-p>]], [[<cmd>cprevious<cr>]])
vim.keymap.set("n", [[<c-n>]], [[<cmd>cnext<cr>]])

do
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

  vim.keymap.set("n", [[<leader>l]], toggle_qf(true))
end
