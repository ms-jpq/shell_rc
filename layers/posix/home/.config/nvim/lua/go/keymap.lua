-- quit
vim.keymap.set({ "n", "v" }, "Q", [[<nop>]])
vim.keymap.set({ "n", "v" }, "QQ", [[<cmd>quitall!<cr>]])

-- prevent macro recording
vim.keymap.set("n", "q", [[<nop>]])

-- manual save
vim.keymap.set("n", [[<c-s>]], [[<cmd>w<cr>]])

-- dont go into ex mode
vim.keymap.set("c", [[<c-f>]], "")

-- quit
vim.keymap.set("c", [[<c-q>]], [[<esc>]])

-- enable paste
vim.keymap.set("c", [[<c-v>]], [[<c-r>"]])

-- leave terminal
vim.keymap.set("t", [[<c-g>]], [[<c-\><c-n>]])

-- dont shift move too much
vim.keymap.set("v", [[<s-up>]], [[g<up>]])
vim.keymap.set("v", [[<s-down>]], [[g<down>]])

-- keep selected when indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- previous, next, line, file, omnifunc
for _, key in pairs { "p", "n", "l", "f", "o" } do
  vim.keymap.set("i", [[<c-]] .. key .. [[>]], [[<c-x><c-]] .. key .. [[>]])
end

do
  local ce = vim.keycode [[<c-e>]]

  -- add emacs key binds
  vim.keymap.set("i", [[<c-a>]], [[<c-o>^]])
  vim.keymap.set("i", [[<c-x><c-a>]], [[<c-a>]])

  vim.keymap.set("i", [[<c-e>]], function()
    return (vim.fn.pumvisible() == 1 and ce or "") .. [[<end>]]
  end, { expr = true, noremap = true })
end

-- emacs arrow movements
vim.keymap.set("c", [[<c-a>]], [[<home>]])
vim.keymap.set("c", [[<c-x><c-a>]], [[<c-a>]])
vim.keymap.set("c", [[<c-e>]], [[<end>]])

-- emacs arrow movements
vim.keymap.set("i", [[<m-left>]], [[<c-o>b]])
vim.keymap.set("i", [[<m-right>]], [[<c-o>e<right>]])
vim.keymap.set("c", [[<m-left>]], [[<s-left>]])
vim.keymap.set("c", [[<m-right>]], [[<s-right>]])

-- add emacs key binds
vim.keymap.set({ "n", "o", "v" }, [[<m-left>]], "b")
vim.keymap.set({ "n", "o", "v" }, [[<m-right>]], [[e<right>]])

-- delete dont copy
for _, key in pairs { "c", "C", "d", "D", "x", "X" } do
  vim.keymap.set({ "n", "v" }, key, [["_]] .. key)
end

-- leave cursor 1 behind instead of before
for _, key in pairs { "p", "P" } do
  vim.keymap.set("n", key, "g" .. key)
  vim.keymap.set("v", key, [["_dg]] .. key)
end

-- scroll fixed lines
vim.keymap.set({ "n", "v" }, "{", [[5g<up>zz]])
vim.keymap.set({ "n", "v" }, "}", [[5g<down>zz]])

-- re-center
for _, key in pairs { "o", "O", "c", "C", "a", "A", "v", "x", "X", "m", "M", "r", "R" } do
  vim.keymap.set({ "n", "v" }, "z" .. key, "z" .. key .. "zz")
end

-- re-center
for _, key in pairs { "n", "N", "[c", "]c", "<c-f>", "<c-b>" } do
  vim.keymap.set({ "n", "v" }, key, key .. "zz")
end

-- movement relative to window size
for key, val in pairs { ["<c-u>"] = "<up>", ["<c-d>"] = "<down>" } do
  vim.keymap.set({ "n", "v" }, key, function()
    local rel = math.floor(vim.fn.winheight(0) / 4)
    return math.max(5, math.min(rel, 9)) .. "g" .. val .. "zz"
  end, { expr = true, noremap = true })
end

-- movement w linewrap
for _, key in pairs { "<up>", "<down>", "j", "k" } do
  vim.keymap.set({ "n", "v" }, key, function()
    return (vim.v.count ~= 0 and "m'" .. vim.v.count or "g") .. key
  end, { expr = true, noremap = true })
end

-- cut to clipboard
vim.keymap.set("v", "X", "d")

-- go to file
vim.keymap.set({ "n", "v" }, "gx", "gF")
