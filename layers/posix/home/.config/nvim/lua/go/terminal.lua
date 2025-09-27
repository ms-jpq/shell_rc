vim.env.NVIM_SERVERNAME = vim.env.NVIM_SERVERNAME or vim.fn.serverstart()

vim.api.nvim_create_autocmd({"TermOpen"}, {command = [[startinsert]]})

vim.api.nvim_create_autocmd({"TermLeave"}, {command = [[set nomodified]]})

local termstart = function(cmd, env)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_call(
    buf,
    function()
      vim.fn.jobstart(
        cmd,
        {
          term = true,
          env = env,
          on_exit = function()
            vim.cmd.bwipeout(buf)
          end
        }
      )
    end
  )

  vim.api.nvim_win_set_buf(0, buf)
end

local lfcmd = function()
  return {{"lf"}, {"-config", vim.fs.joinpath(vim.fn.stdpath("config"), "lfrc.2")}}
end

vim.keymap.set(
  "n",
  [[<c-t>]],
  function()
    local cmd = lfcmd()
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(path) == 0 then
      path = vim.fn.getcwd()
    end
    table.insert(cmd, {"--", path})

    termstart(vim.iter(cmd):flatten():totable(), vim.empty_dict())
  end
)
