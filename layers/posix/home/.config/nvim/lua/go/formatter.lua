local lib = require("go")

local data = nil

local fmt_command = function(buf)
  if data == nil then
    local loadpath = vim.fs.joinpath(vim.fn.stdpath("config"), "apriori", "fmt.json")
    data = lib.read_json(loadpath)
  end

  local filetype = vim.bo[buf].filetype
  return {"sed", "-E", "-e", [[:l1]], "-e", [[/./,$!d]], "-e", [[/^\n*$/{$d;N;}]], "-e", [[/\n$/bl1]]}
end

Go.run_fmt = function()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local cwd = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local timeout = 3000

  local cmd = fmt_command(buf)

  local handle = nil
  local on_exit = function(waited)
    vim.uv.timer_stop(handle)

    if waited.signal ~= 0 then
      vim.notify([[☠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR, {})
      return
    elseif waited.code ~= 0 then
      vim.notify([[⚠️ ]] .. vim.inspect(waited), waited.stderr, vim.log.levels.ERROR, {})
      return
    end

    if vim.api.nvim_get_current_buf() == buf then
      local lines = vim.split(waited.stdout, "\n", {plain = true})
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
      vim.notify([[✅...]], vim.log.levels.INFO, {})
    end
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local opts = {cwd = cwd, stdin = lines, text = true}
  local proc = vim.system(cmd, opts, vim.schedule_wrap(on_exit))

  handle =
    vim.defer_fn(
    function()
      proc:wait(0)
    end,
    timeout
  )
  vim.notify([[⏳...]], vim.log.levels.INFO, {})
end

vim.opt.formatexpr = "v:lua.Go.run_fmt()"

vim.keymap.set("n", "gq", Go.run_fmt, {noremap = true, nowait = true})
