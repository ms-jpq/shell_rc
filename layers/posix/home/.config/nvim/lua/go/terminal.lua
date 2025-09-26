vim.env.NVIM_SERVERNAME = vim.env.NVIM_SERVERNAME or vim.fn.serverstart()

vim.api.nvim_create_autocmd({"TermOpen"}, {command = [[startinsert]]})

vim.keymap.set(
  "n",
  [[<c-t>]],
  function()
    local cmd = {{"lf"}}
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(path) == 0 then
      path = vim.fn.getcwd()
    end
    table.insert(cmd, {"--", path})

    local on_exit = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.cmd.bwipeout(buf)
    end

    vim.fn.jobstart(
      vim.iter(cmd):flatten():totable(),
      {term = true, env = {LC_ALL = [[en_CA.UTF-8]]}, on_exit = on_exit}
    )
  end
)
