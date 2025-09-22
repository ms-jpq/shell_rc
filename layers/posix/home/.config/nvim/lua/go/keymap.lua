vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- prevent macro recording
vim.keymap.set("n", "q", [[<nop>]], {noremap = true})

-- manaul save
vim.keymap.set("n", [[<c-s>]], [[<cmd>w<cr>]], {noremap = true})

-- dont go into ex mode
vim.keymap.set("c", [[<c-f>]], "", {noremap = true})

-- quit
vim.keymap.set("c", [[<c-q>]], [[<esc>]], {noremap = true})

-- enable paste
vim.keymap.set("c", [[<c-v>]], [[<c-r>"]], {noremap = true})

-- leave terminal
vim.keymap.set("t", [[<c-g>]], [[<c-\><c-n>]], {noremap = true})

-- dont shift move too much
vim.keymap.set("v", [[<s-up>]], [[g<up>]], {noremap = true})
vim.keymap.set("v", [[<s-down>]], [[g<down>]], {noremap = true})

-- keep selected when indenting
vim.keymap.set("v", "<", "<gv", {noremap = true})
vim.keymap.set("v", ">", ">gv", {noremap = true})

-- previous, next, line, file, omnifunc
for _, key in pairs {"p", "n", "l", "f", "o"} do
  vim.keymap.set("i", key, [[<c-x>]] .. key, {noremap = true})
end

local ce = vim.api.nvim_replace_termcodes([[<c-e>]], true, true, true)

-- insert movement keys do not enter
for _, key in pairs {"<left>", "<right>"} do
  vim.keymap.set(
    "i",
    key,
    function()
      return (vim.fn.pumvisible() == 1 and ce or "") .. key
    end,
    {expr = true, noremap = true}
  )
end

-- add emacs key binds
vim.keymap.set("i", [[<c-a>]], [[<c-o>^]], {noremap = true})
vim.keymap.set("i", [[<c-x><c-a>]], [[<c-a>]], {noremap = true})
vim.keymap.set(
  "i",
  "<c-e>",
  function()
    return (vim.fn.pumvisible() == 1 and ce or "") .. [[<end>]]
  end,
  {expr = true, noremap = true}
)

-- emacs arrow movements
vim.keymap.set("c", [[<c-a>]], [[<home>]], {noremap = true})
vim.keymap.set("c", [[<c-x><c-a>]], [[<c-a>]], {noremap = true})
vim.keymap.set("c", [[<c-e>]], [[<end>]], {noremap = true})

-- emacs arrow movements
vim.keymap.set("i", [[<m-left>]], [[<c-o>b]], {noremap = true})
vim.keymap.set("i", [[<m-right>]], [[<c-o>e<right>]], {noremap = true})
vim.keymap.set("c", [[<m-left>]], [[<s-left>]], {noremap = true})
vim.keymap.set("c", [[<m-right>]], [[<s-right>]], {noremap = true})

for _, mode in pairs {"n", "o", "v"} do
  -- add emacs key binds
  vim.keymap.set(mode, [[<m-left>]], "b", {noremap = true})
  vim.keymap.set(mode, [[<m-right>]], [[e<right>]], {noremap = true})
end

for _, mode in pairs {"n", "v"} do
  -- quit
  vim.keymap.set(mode, "Q", [[<nop>]], {noremap = true})
  vim.keymap.set(mode, "QQ", [[<cmd>quitall!<cr>]], {noremap = true})

  -- delete dont copy
  for _, key in pairs {"c", "C", "d", "D", "s", "S", "x", "X"} do
    vim.keymap.set(mode, key, '"_' .. key, {noremap = true})
  end

  -- leave cursor 1 behind instead of before
  for _, key in pairs {"p", "P"} do
    vim.keymap.set(mode, key, "g" .. key, {noremap = true})
  end

  -- scroll fixed lines
  vim.keymap.set(mode, "{", [[5g<up>zz]], {noremap = true})
  vim.keymap.set(mode, "}", [[5g<down>zz]], {noremap = true})

  -- re-center
  for _, key in pairs {"o", "O", "c", "C", "a", "A", "v", "x", "X", "m", "M", "r", "R"} do
    vim.keymap.set(mode, "z" .. key, "z" .. key .. "zz", {noremap = true})
  end

  -- re-center
  for _, key in pairs {"n", "N", "[c", "]c", "<c-f>", "<c-b>"} do
    vim.keymap.set(mode, key, key .. "zz", {noremap = true})
  end

  -- movement relative to window size
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

  -- movement w linewrap
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

-- cut to clipboard
vim.keymap.set("v", "X", "d", {noremap = true})
