local T = require "tests.lib"
local autocmd = require "goto.autocmd"

for _, key in ipairs { "<C-c>", "<Esc>" } do
  T.test({ "insert-mode callbacks observe entry and exit through " .. key }, function()
    local group = vim.api.nvim_create_augroup("test_insert_mode", { clear = true })
    T.cleanup(function()
      vim.api.nvim_del_augroup_by_id(group)
    end)
    local entered, left = 0, 0
    autocmd.insert_mode({ group = group }, function()
      entered = entered + 1
    end, function()
      left = left + 1
    end)
    for count = 1, 2 do
      vim.api.nvim_feedkeys("i" .. vim.keycode(key), "xt", false)
      T.eventually(function()
        return entered == count and left == count
      end)
    end
  end)
end
