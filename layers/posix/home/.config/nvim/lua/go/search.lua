-- search results shown on side
vim.opt.inccommand = "nosplit"
-- use ripgrep
vim.opt.grepprg = [[rg\ --vimgrep]]

-- clear hlsearch result
vim.keymap.set("n", "<leader>h", [[<cmd>call setreg('/', '')<cr>]], {noremap = true})

-- search without moving
vim.keymap.set("n", "*", "*N", {noremap = true})
vim.keymap.set("n", "#", "#N", {noremap = true})
vim.keymap.set("n", "g*", "g*N", {noremap = true})
vim.keymap.set("n", "g#", "g#N", {noremap = true})

-- centre on search result
vim.keymap.set("n", "n", "n", {noremap = true})
vim.keymap.set("n", "N", "N", {noremap = true})

local function with_redraw(wrapped)
  local l = [[<cmd>set lazyredraw<cr><cmd>set noincsearch<cr>]]
  local r = [[<cmd>nohlsearch<cr><cmd>set incsearch<cr><cmd>set nolazyredraw<cr>]]
  return l .. wrapped .. r
end

for _, mode in pairs {"n", "v"} do
  -- use no magic
  vim.keymap.set(mode, "/", [[/\V]], {noremap = true})
  vim.keymap.set(mode, "?", [[?\V]], {noremap = true})

  -- () search next params
  vim.keymap.set(mode, "(", with_redraw [[?(\|[\|{<cr>]], {noremap = true})
  vim.keymap.set(mode, ")", with_redraw [[/)\|]\|}<cr>]], {noremap = true})
end
