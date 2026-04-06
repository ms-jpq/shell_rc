vim.g.coq_settings = {
  xdg = true,
  auto_start = true,
  display = {
    ["statusline.helo"] = false,
    mark_applied_notify = false,
  },
  clients = {
    ["registers.lines"] = { "z" },
    ["lsp.ignored_servers"] = { "tabby_ml" },
    ["snippets.user_path"] = "~/.cache/helix-rt/nvim/pack/start/snips",
  },
  keymap = {
    jump_to_mark = [[<c-y>]],
  },
}
