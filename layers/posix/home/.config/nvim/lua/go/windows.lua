local lib = require "go.lib"

-- hide background buffers
vim.opt.hidden = true
-- reuse buf
vim.opt.switchbuf:append { "useopen", "usetab" }

-- modern split direction
-- vim.opt.splitright = true
vim.opt.splitbelow = true

-- move between windows
for _, key in pairs { "<c-up>", "<c-k>" } do
  vim.keymap.set({ "n" }, key, [[<cmd>wincmd k<cr>]])
end
for _, key in pairs { "<c-down>", "<c-j>" } do
  vim.keymap.set({ "n" }, key, [[<cmd>wincmd j<cr>]])
end
for _, key in pairs { "<c-left>", "<c-h>" } do
  vim.keymap.set({ "n" }, key, [[<cmd>wincmd h<cr>]])
end
for _, key in pairs { "<c-right>", "<c-l>" } do
  vim.keymap.set({ "n" }, key, [[<cmd>wincmd l<cr>]])
end

-- kill current buf
vim.keymap.set({ "n" }, [[<leader>x]], "<cmd>bwipeout!<cr>")

-- kill current win
vim.keymap.set({ "n" }, [[<c-w><c-q>]], "<cmd>wincmd c<cr>")

-- kill current tab
vim.keymap.set({ "n" }, [[<leader>q]], "<cmd>tabclose<cr>")

-- swap windows
vim.keymap.set({ "n" }, [[<leader>']], [[<cmd>wincmd r<cr>]])
vim.keymap.set({ "n" }, [[<leader>;]], [[<cmd>wincmd R<cr>]])

-- move windows
vim.keymap.set({ "n" }, [[<s-m-left>]], [[<cmd>wincmd H<cr>]])
vim.keymap.set({ "n" }, [[<s-m-right>]], [[<cmd>wincmd L<cr>]])
vim.keymap.set({ "n" }, [[<s-m-up>]], [[<cmd>wincmd K<cr>]])
vim.keymap.set({ "n" }, [[<s-m-down>]], [[<cmd>wincmd J<cr>]])

-- resize windows
vim.keymap.set({ "n" }, [[+]], [[<cmd>wincmd =<cr>]])
vim.keymap.set({ "n" }, [[<s-left>]], [[<cmd>wincmd <<cr>]])
vim.keymap.set({ "n" }, [[<s-right>]], [[<cmd>wincmd ><cr>]])
vim.keymap.set({ "n" }, [[<s-up>]], [[<cmd>wincmd +<cr>]])
vim.keymap.set({ "n" }, [[<s-down>]], [[<cmd>wincmd -<cr>]])

-- cycle between tabs
vim.keymap.set({ "n" }, "<leader>[", [[<cmd>tabprevious<cr>]])
vim.keymap.set({ "n" }, "<leader>]", [[<cmd>tabnext<cr>]])

-- pick tab
vim.keymap.set({ "n" }, "<leader>0", "g<tab>")
for i = 1, 9 do
  vim.keymap.set({ "n" }, [[<leader>]] .. i, [[<cmd>tabnext ]] .. i .. [[<cr>]])
end

vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = lib.group,
  callback = lib.throttle(100, function()
    vim.cmd.wincmd "="
  end),
})

-- pin quickfix to window
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = lib.group,
  pattern = { "qf" },
  command = [[setlocal winfixbuf]],
})

do
  local find_qfs = function(lo)
    local key = lo and "loclist" or "quickfix"
    local wins = vim.api.nvim_tabpage_list_wins(0)

    local acc = {}
    for _, win in pairs(wins) do
      local info = unpack(vim.fn.getwininfo(win))
      if info and info[key] == 1 then
        acc[win] = info
      end
    end

    return acc
  end

  -- quickfix & loclist
  vim.keymap.set({ "n" }, [[<c-p>]], function()
    if not vim.tbl_isempty(find_qfs(true)) then
      vim.cmd.lprevious { mods = { silent = true, emsg_silent = true } }
    else
      vim.cmd.cprevious { mods = { silent = true, emsg_silent = true } }
    end
  end)
  vim.keymap.set({ "n" }, [[<c-n>]], function()
    if not vim.tbl_isempty(find_qfs(true)) then
      vim.cmd.lnext { mods = { silent = true, emsg_silent = true } }
    else
      vim.cmd.cnext { mods = { silent = true, emsg_silent = true } }
    end
  end)

  local toggle_qf = function(lo)
    return function()
      local closed = false
      for win, _ in pairs(find_qfs(lo)) do
        vim.api.nvim_win_close(win, true)
        closed = true
      end

      if not closed then
        local height = vim.o.previewheight
        if lo then
          vim.cmd.lopen(height)
        else
          vim.cmd.copen(height)
        end
      end
    end
  end

  vim.keymap.set({ "n" }, [[<leader>l]], toggle_qf(false))
end

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = lib.group,
  pattern = { "*.txt" },
  callback = function()
    if vim.bo.filetype == "help" and #vim.api.nvim_list_wins() > 1 then
      vim.cmd.wincmd { "T" }
    end
  end,
})
