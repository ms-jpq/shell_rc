local preview = "%w"
local ql = "%q"
local name = "%f"
local modified = "%m"
local lsp_status = "%{v:lua.vim.lsp.status()}"
local ft = "%y"
local tabs = "%{&tabstop .. (&expandtab ? 'S' : 'T')}"
local linefeed = "%{&fileformat}"
local pos = "%5l:%-3c"
local scroll = "%3p%%"

local lhs = preview .. ql .. name .. modified
local rhs = lsp_status .. "|" .. ft .. " " .. tabs .. " " .. linefeed .. " @ " .. pos .. "≡ " .. scroll
vim.opt.statusline = lhs .. " %= " .. rhs
