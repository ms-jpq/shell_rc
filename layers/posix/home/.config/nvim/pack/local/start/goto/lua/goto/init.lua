local M = {}

M.setup = function()
  require "goto.fs_reconcile"
  require "goto.conceal"
  require "goto.repl"
end

return M
