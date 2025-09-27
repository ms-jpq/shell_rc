vim.env.NVIM_SERVERNAME = vim.env.NVIM_SERVERNAME or vim.fn.serverstart()

vim.api.nvim_create_autocmd({"TermOpen"}, {command = [[startinsert]]})

vim.api.nvim_create_autocmd({"TermLeave"}, {command = [[set nomodified]]})

local termstart = function(cmd, env, die)
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
            if die then
              die()
            end
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

    local bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buflisted then
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.fn.filereadable(name) == 1 then
          bufs[buf] = name
        end
      end
    end
    local die = function()
      local dead = {}
      for buf, name in pairs(bufs) do
        if vim.fn.filereadable(name) == 0 then
          table.insert(dead, buf)
        end
      end

      if #dead > 0 then
        vim.cmd([[bwipeout! ]] .. table.concat(dead, " "))
      end
    end

    termstart(vim.iter(cmd):flatten():totable(), vim.empty_dict(), die)
  end
)
