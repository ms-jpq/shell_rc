for _, mode in pairs {"n", "v"} do
  vim.keymap.set(mode, "ga", [[<plug>(EasyAlign)]])
end
