local lib = require "go.lib"

-- offscreen previewing of commands
vim.opt.inccommand = "split"

-- use ripgrep
vim.opt.grepprg = [[rg\ --vimgrep]]

-- clear hlsearch result
vim.keymap.set({ "n" }, "<leader>h", function()
  vim.fn.setreg("/", "")
end)

do
  Go.findfunc = function(search, init)
    local cwd = vim.fn.getcwd()
    if init then
      search = string.gsub(search, ".", ".*%0") .. ".*"
    end

    local argv = { "fd", "--hidden", "--no-ignore-parent", "--full-path", "--print0", "--", search }
    local proc = vim.system(argv, { cwd = cwd }):wait()
    return vim.split(proc.stdout, "\0", { plain = true, trimempty = true })
  end

  vim.opt.findfunc = [[v:lua.Go.findfunc]]
end

-- search without moving
vim.keymap.set({ "n" }, "*", "*N")
vim.keymap.set({ "n" }, "#", "#N")
vim.keymap.set({ "n" }, "g*", "g*N")
vim.keymap.set({ "n" }, "g#", "g#N")

-- use no magic
vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
  group = lib.group,
  pattern = { "/", [[\?]] },
  callback = function()
    vim.fn.setcmdline [[\V]]
  end,
})

do
  -- local function with_redraw(wrapped)
  --   local l = [[<cmd>set lazyredraw<cr><cmd>set noincsearch<cr>]]
  --   local r = [[<cmd>nohlsearch<cr><cmd>set incsearch<cr><cmd>set nolazyredraw<cr>]]
  --   return l .. wrapped .. r
  -- end

  -- () search next params
  -- vim.keymap.set({ "n", "x" }, "(", with_redraw [[?(\|[\|{<cr>]])
  -- vim.keymap.set({ "n", "x" }, ")", with_redraw [[/)\|]\|}<cr>]])
end
