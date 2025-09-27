vim.env.NVIM_SERVERNAME = vim.env.NVIM_SERVERNAME or vim.fn.serverstart()

vim.api.nvim_create_autocmd({"TermOpen"}, {command = [[startinsert]]})

vim.api.nvim_create_autocmd({"TermLeave"}, {command = [[set nomodified]]})

vim.keymap.set(
  "n",
  [[<c-t>]],
  function()
    local buf = vim.api.nvim_create_buf(false, true)

    local cmd = {{"lf"}}
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(path) == 0 then
      path = vim.fn.getcwd()
    end
    table.insert(cmd, {"--", path})

    vim.api.nvim_buf_call(
      buf,
      function()
        vim.fn.jobstart(
          vim.iter(cmd):flatten():totable(),
          {
            term = true,
            on_exit = function()
              vim.cmd.bwipeout(buf)
            end
          }
        )
      end
    )

    vim.api.nvim_win_set_buf(0, buf)
  end
)
