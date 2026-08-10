local lib = require "goto.lib"

-- do not exec arbitrary code
vim.opt.modeline = false

-- limit .vim exec rights
vim.opt.secure = true

-- use bash as shell
vim.opt.shell = vim.env.COMSPEC or "bash"

if not lib.is_win then
  vim.g.python3_host_prog = "/usr/bin/python3"
end

-- min lines changed to report
vim.opt.report = 0

-- no swap files
vim.opt.swapfile = false

-- no hex or binary parsing
vim.opt.nrformats = ""

-- waiting time within a key sequence
vim.opt.timeoutlen = 500
-- cursor hold time
vim.opt.updatetime = 300
-- allow nav keys to wrap around
vim.opt.whichwrap:append "h,l,<,>,[,]"

-- enable mouse
vim.opt.mouse = "a"
-- right click behaviour
vim.opt.mousemodel = "popup_setpos"
-- double-click time
vim.opt.mousetime = 250

-- scroll bound windows scroll horizontally as well
vim.opt.scrollopt:append { "hor" }

-- scroll activation margin
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 16
vim.opt.smoothscroll = true

-- browser-like jumplist; restore view on navigation
vim.opt.jumpoptions:append { "stack", "view" }

-- rounded borders on all floating windows
vim.opt.winborder = "rounded"

-- keep on-screen text stable across split open/close
vim.opt.splitkeep = "screen"

-- ui for cmd auto complete
vim.opt.wildcharm = vim.fn.char2nr "\t"
vim.opt.wildignorecase = true
vim.opt.wildmenu = true
vim.opt.wildmode:append { "longest:full" }

-- more history
vim.opt.history = 10000

-- ignore case
vim.opt.ignorecase = true
vim.opt.smartcase = true
