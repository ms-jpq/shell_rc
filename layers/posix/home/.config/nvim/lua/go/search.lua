local lib = require "go"

-- offscreen previewing of commands
vim.opt.inccommand = "split"

-- use ripgrep
vim.opt.grepprg = [[rg\ --vimgrep]]

-- clear hlsearch result
vim.keymap.set("n", "<leader>h", [[<cmd>call setreg('/', '')<cr>]])

do
  Go.findfunc = function(arg)
    local cwd = vim.fn.getcwd()
    local proc = vim.system({ "fd", "--hidden", "--no-ignore-parent", "--print0", "--", arg }, { cwd = cwd }):wait()
    return vim.split(proc.stdout, "\0", { plain = true, trimempty = true })
  end

  vim.opt.findfunc = [[v:lua.Go.findfunc]]
end

-- search without moving
vim.keymap.set("n", "*", "*N")
vim.keymap.set("n", "#", "#N")
vim.keymap.set("n", "g*", "g*N")
vim.keymap.set("n", "g#", "g#N")

-- use no magic
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = lib.group,
  pattern = { "/", [[\?]] },
  callback = function()
    vim.fn.setcmdline [[\V]]
  end,
})

do
  local function with_redraw(wrapped)
    local l = [[<cmd>set lazyredraw<cr><cmd>set noincsearch<cr>]]
    local r = [[<cmd>nohlsearch<cr><cmd>set incsearch<cr><cmd>set nolazyredraw<cr>]]
    return l .. wrapped .. r
  end

  -- () search next params
  vim.keymap.set({ "n", "v" }, "(", with_redraw [[?(\|[\|{<cr>]])
  vim.keymap.set({ "n", "v" }, ")", with_redraw [[/)\|]\|}<cr>]])
end
