local lib = require "goto.lib"

local gs = require "gitsigns"

gs.setup {
  current_line_blame = true,
  -- word_diff = true
  on_attach = function(buf)
    local opt = { noremap = true, buffer = buf }

    vim.keymap.set({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>", opt)

    vim.keymap.set({ "n" }, "[g", function()
      gs.nav_hunk "prev"
    end, opt)
    vim.keymap.set({ "n" }, "]g", function()
      gs.nav_hunk "next"
    end, opt)

    vim.keymap.set({ "n" }, [[<leader>i]], gs.preview_hunk_inline, opt)
    vim.keymap.set({ "n" }, [[<leader>I]], gs.diffthis, opt)

    vim.keymap.set({ "n" }, [[<leader>e]], gs.stage_hunk, opt)

    vim.keymap.set({ "n", "x" }, [[<leader>c]], gs.reset_hunk, opt)

    vim.api.nvim_create_autocmd({ "FocusGained" }, {
      group = lib.group,
      buffer = buf,
      callback = function()
        gs.refresh(buf)
      end,
    })
  end,
}
