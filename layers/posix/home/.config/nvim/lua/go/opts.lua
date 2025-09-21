local lib = require("go")

-- do not exec arbitrary code
vim.opt.modeline = false

-- limit .vim exec rights
vim.opt.secure = true

-- use bash as shell
vim.opt.shell = vim.env.COMSPEC or "bash"

vim.g.python3_host_prog = lib.is_win and "python.exe" or "/usr/bin/python3"

-- min lines changed to report
vim.opt.report = 0

-- no swap files
vim.opt.swapfile = false

-- wrap
vim.opt.wrap = true

-- no hex or binary parsing
vim.opt.nrformats = ""

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

-- ui for cmd auto complete
vim.opt.wildmenu = true
vim.opt.wildmode = "list:longest,full"
vim.opt.wildignorecase = true
vim.opt.wildoptions = "tagfile"

-- more history
vim.opt.history = 10000

-- ignore case
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- dont follow tags
vim.opt.complete:remove("i")
