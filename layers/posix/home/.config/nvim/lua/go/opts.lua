-- do not exec arbitrary code
vim.opt.modeline = false

-- limit .vim exec rights
vim.opt.secure = true

-- use bash as shell
vim.opt.shell = vim.env.COMSPEC or "bash"


local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win32unix")
vim.g.python3_host_prog = is_win and "python.exe" or "/usr/bin/python3"

-- waiting time within a key sequence
vim.opt.timeoutlen = 500
-- cursor hold time
vim.opt.updatetime = 300
-- allow nav keys to wrap around
vim.opt.whichwrap:append("h", "l", "<", ">", "[", "]")

-- enable mouse
vim.opt.mouse = "a"
-- right click behaviour
vim.opt.mousemodel = "popup_setpos"
-- doubleclick time
vim.opt.mousetime = 250

-- scroll activation margin
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 10
vim.opt.smoothscroll = true

-- normalize cursor pos
local vcol = {"onemore", "block"}
vim.opt.virtualedit = vcol

vim.api.nvim_create_autocmd(
  "InsertEnter",
  {
    callback = function()
      vim.opt.virtualedit = vcol
      vim.opt.cursorline = false
      vim.opt.cursorcolumn = false
    end
  }
)
vim.api.nvim_create_autocmd(
  "InsertLeave",
  {
    callback = function()
      vim.opt.cursorline = true
    end
  }
)

vim.keymap.set(
  "n",
  "<leader>f",
  function()
    if vim.opt.cursorcolumn then
      vim.opt.virtualedit = vcol
      vim.opt.cursorcolumn = false
    else
      vim.opt.virtualedit = "all"
      vim.opt.cursorcolumn = true
    end
  end,
  {
    noremap = true
  }
)

for _, mode in pairs({"n", "v"}) do
  vim.keymap.set(mode, "$", "$<right>", {noremap = true})
end

-- show cursor
vim.opt.cursorline = true
