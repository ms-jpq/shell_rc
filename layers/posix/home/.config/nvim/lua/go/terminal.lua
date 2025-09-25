local server = vim.env.NVIM_SERVERNAME or vim.fn.serverstart()

local command = function()
  return {
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
    "NVIM_SERVERNAME=" .. server
  }
end

vim.keymap.set(
  "n",
  [[<leader>t]],
  function()
    local cmd = vim.iter({command(), "--", "env", "--", "EDITOR=nvim-remote.sh", "lf"}):flatten():totable()
    vim.system(cmd):wait(666)
  end,
  {noremap = true}
)
