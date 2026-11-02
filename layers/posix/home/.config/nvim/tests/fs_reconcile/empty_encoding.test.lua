local T = require "tests.lib"

T.test({ "empty encoding", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local path = vim.fn.tempname()
  for _, fileencoding in pairs { "", "utf-8", "latin1" } do
    vim.bo.fileencoding = fileencoding
    local expected = fileencoding ~= "" and fileencoding or vim.o.encoding
    assert(util.empty(0).encoding == expected)
    assert(assert(util.read_file(0, path)).encoding == expected)
  end
end)
