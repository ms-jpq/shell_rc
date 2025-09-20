vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Prevent macro recording
vim.keymap.set("n", "q", "<nop>", {noremap = true})

for _, mode in pairs({"n", "v"}) do
  vim.keymap.set(mode, "Q", "<nop>", {noremap = true})
  vim.keymap.set(mode, "QQ", "<cmd>quitall!<cr>", {noremap = true})

  -- -- re-center
  for _, key in pairs({"o", "O", "c", "C", "a", "A", "v", "x", "X", "m", "M", "r", "R"}) do
    vim.keymap.set(mode, "z" .. key, "z" .. key .. "zz", {noremap = true})
  end
end
