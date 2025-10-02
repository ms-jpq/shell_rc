-- use ripgrep
vim.opt.grepprg = [[rg\ --vimgrep]]

-- clear hlsearch result
vim.keymap.set("n", "<leader>h", [[<cmd>call setreg('/', '')<cr>]])

-- search without moving
vim.keymap.set("n", "*", "*N")
vim.keymap.set("n", "#", "#N")
vim.keymap.set("n", "g*", "g*N")
vim.keymap.set("n", "g#", "g#N")

-- centre on search result
for _, key in pairs {"n", "N"} do
  vim.keymap.set("n", key, key .. "zz")
end

local function with_redraw(wrapped)
  local l = [[<cmd>set lazyredraw<cr><cmd>set noincsearch<cr>]]
  local r = [[<cmd>nohlsearch<cr><cmd>set incsearch<cr><cmd>set nolazyredraw<cr>]]
  return l .. wrapped .. r
end

-- use no magic
vim.keymap.set({"n", "v"}, "/", [[/\V]])
vim.keymap.set({"n", "v"}, "?", [[?\V]])

-- () search next params
vim.keymap.set({"n", "v"}, "(", with_redraw [[?(\|[\|{<cr>]])
vim.keymap.set({"n", "v"}, ")", with_redraw [[/)\|]\|}<cr>]])
