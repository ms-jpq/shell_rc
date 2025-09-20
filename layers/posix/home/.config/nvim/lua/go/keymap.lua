vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Prevent macro recording
vim.keymap.set("n", "q", "<nop>", {noremap = true})

for _, mode in pairs {"n", "v"} do
  -- quit
  vim.keymap.set(mode, "Q", "<nop>", {noremap = true})
  vim.keymap.set(mode, "QQ", "<cmd>quitall!<cr>", {noremap = true})
end

-- dont go into ex mode
vim.keymap.set("c", "<c-f>", "", {noremap = true})

-- quit
vim.keymap.set("c", "<c-q>", "<esc>", {noremap = true})

-- enable paste
vim.keymap.set("c", "<c-v>", '<c-r>"', {noremap = true})

-- leave terminal
vim.keymap.set("t", "<c-g>", [[<c-\><c-n>]], {noremap = true})

-- dont shift move too much
vim.keymap.set("v", "<s-up>", "g<up>", {noremap = true})
vim.keymap.set("v", "<s-down>", "g<down>", {noremap = true})

-- keep selected when indenting
vim.keymap.set("v", "<", "<gv", {noremap = true})
vim.keymap.set("v", ">", ">gv", {noremap = true})

-- add emacs key binds
vim.keymap.set("i", "<c-a>", "<c-o>^", {noremap = true})
vim.keymap.set("i", "<c-x><c-a>", "<c-a>", {noremap = true})
vim.keymap.set(
  "i",
  "<c-e>",
  function()
    return (vim.fn.pumvisible() and "<c-e>" or "") .. "<end>"
  end,
  {expr = true, noremap = true}
)

vim.keymap.set("c", "<c-a>", "<home>", {noremap = true})
vim.keymap.set("c", "<c-x><c-a>", "<c-a>", {noremap = true})
vim.keymap.set("c", "<c-e>", "<end>", {noremap = true})

-- insert movement keys do not enter
for _, key in pairs {"<left>", "<right>"} do
  vim.keymap.set(
    "i",
    key,
    function()
      return (vim.fn.pumvisible() and "<C-e>" or "") .. key
    end,
    {expr = true, noremap = true}
  )
end

local function with_redraw(wrapped)
  local l = [[<cmd>set lazyredraw<cr><cmd>set noincsearch<cr>]]
  local r = [[<cmd>nohlsearch<cr><cmd>set incsearch<cr><cmd>set nolazyredraw<cr>]]
  return l .. wrapped .. r
end

for _, mode in pairs {"n", "v"} do
  -- scroll fixed lines
  vim.keymap.set(mode, "{", "5g<up>zz", {noremap = true})
  vim.keymap.set(mode, "}", "5g<down>zz", {noremap = true})

  -- re-center
  for _, key in pairs {"o", "O", "c", "C", "a", "A", "v", "x", "X", "m", "M", "r", "R"} do
    vim.keymap.set(mode, "z" .. key, "z" .. key .. "zz", {noremap = true})
  end

  -- re-center
  for _, key in pairs {"d", "n", "N", "[c", "]c", "<c-f>", "<c-b>"} do
    vim.keymap.set(mode, key, key .. "zz", {noremap = true})
  end

  -- move relative to window size
  for key, val in pairs {["<c-u>"] = "<up>", ["<c-d>"] = "<down>"} do
    vim.keymap.set(
      mode,
      key,
      function()
        local rel = math.floor(vim.fn.winheight(0) / 4)
        return math.max(5, math.min(rel, 9)) .. "g" .. val .. "zz"
      end,
      {expr = true, noremap = true}
    )
  end

  -- () search next params
  vim.keymap.set(mode, "(", with_redraw [[?(\|[\|{<cr>]], {noremap = true})
  vim.keymap.set(mode, ")", with_redraw [[/)\|]\|}<cr>]], {noremap = true})

  -- move w linewrap

  for _, key in pairs {"<up>", "<down>", "j", "k"} do
    vim.keymap.set(
      mode,
      key,
      function()
        return (vim.v.count ~= 0 and "m'" .. vim.v.count or "g") .. key
      end,
      {expr = true, noremap = true}
    )
  end
end
