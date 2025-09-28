vim.g.copilot_assume_mapped = true
vim.g.copilot_hide_during_completion = false
vim.g.copilot_no_maps = true

vim.keymap.set(
  "i",
  [[<c-f>]],
  function()
    local esc_pum = vim.fn.pumvisible() == 1 and vim.api.nvim_replace_termcodes("<c-e>", true, true, true) or ""
    return esc_pum .. vim.fn["copilot#Accept"]()
  end,
  {
    noremap = true,
    nowait = true,
    expr = true
  }
)

vim.fs.find([[copilot.vim]])
