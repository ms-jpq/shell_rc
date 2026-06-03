vim.g.coq_v2 = 1

vim.g.coq_settings = {
  auto_start = true,
  display = {
    ["statusline.helo"] = false,
    mark_applied_notify = false,
  },
  clients = {
    ["registers.lines"] = { "z" },
    ["snippets.user_path"] = "~/.cache/helix-rt/nvim/pack/opt/snips",
  },
  keymap = {
    jump_to_mark = [[<c-y>]],
  },
}
