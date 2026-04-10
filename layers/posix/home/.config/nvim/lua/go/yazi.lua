local termstart = function(cmd, env, die)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_call(buf, function()
    vim.fn.jobstart(cmd, {
      term = true,
      env = env,
      on_exit = function()
        vim.api.nvim_buf_delete(buf, { force = true })
        if die then
          die()
        end
      end,
    })
  end)

  vim.api.nvim_win_set_buf(0, buf)
end

local file_exp_die = function()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if vim.fn.filereadable(name) == 1 then
        bufs[buf] = name
      end
    end
  end

  local current = vim.api.nvim_get_current_buf()
  local cur_name = vim.api.nvim_buf_get_name(current)
  local alt = vim.fn.getreg "#"

  return function()
    local dead = {}
    for buf, name in pairs(bufs) do
      if vim.fn.filereadable(name) == 0 then
        table.insert(dead, buf)
      end
    end

    for _, buf in pairs(dead) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    local altfile = vim.api.nvim_get_current_buf() == current and alt or cur_name
    pcall(vim.fn.setreg, "#", altfile)
  end
end

local spawn_yz = function(use_cwd)
  return function()
    local tmp = vim.fn.tempname()
    local path = use_cwd(vim.fn.getcwd())

    local cmd = { "yazi", "--chooser-file", tmp, "--", path }
    local die = file_exp_die()
    termstart(cmd, vim.empty_dict(), function()
      if vim.fn.filereadable(tmp) == 1 then
        local select = vim.fn.readblob(tmp)
        local escaped = vim.fn.fnameescape(select)
        if vim.fn.isdirectory(select) == 1 then
          vim.cmd.cd(escaped)
        else
          vim.cmd.edit(escaped)
        end
      end
      die()
    end)
  end
end

vim.keymap.set(
  "n",
  [[<c-t>]],
  spawn_yz(function(cwd)
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(path) == 0 then
      path = cwd
    end
    return path
  end)
)

vim.keymap.set(
  "n",
  [[<leader>t]],
  spawn_yz(function(cwd)
    return cwd
  end)
)
