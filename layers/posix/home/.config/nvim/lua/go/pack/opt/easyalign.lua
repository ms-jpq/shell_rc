for _, mode in pairs {"n", "v"} do
  vim.keymap.set(mode, "gw", [[<plug>(EasyAlign)]])
end
