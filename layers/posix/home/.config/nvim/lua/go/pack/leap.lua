local leap = require "leap"

vim.keymap.set({ "n", "x", "o" }, "s", [[<Plug>(leap)]])

leap.opts.preview_filter = function(ch0, ch1, ch2)
  return not (ch1:match "%s" or ch0:match "%a" and ch1:match "%a" and ch2:match "%a")
end
