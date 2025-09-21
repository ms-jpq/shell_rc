return {
  is_win = vim.fn.has("win32") == 1 or vim.fn.has("win32unix")
}
