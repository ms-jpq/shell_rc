local server = vim.env.NVIM_SERVERNAME or vim.fn.serverstart()

vim.keymap.set(
  "n",
  [[<leader>u]],
  function()
    local cmd = {
      "tmux",
      "display-popup",
      "-EE",
      "-d",
      "#{pane_current_path}",
      "-w",
      "95%",
      "-h",
      "95%",
      "-e",
      "NVIM_SERVERNAME=" .. server,
      "--"
    }
    vim.system(cmd):wait(666)
  end,
  {noremap = true}
)
