local async = require "go.async"
local lib = require "go.lib"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- noskip backup
vim.opt.backupskip = ""

local wall = function()
  vim.cmd [[silent! wall! ++p]]
end

vim.api.nvim_create_autocmd({ "VimLeavePre" }, { group = lib.group, once = true, callback = wall })

local alive = lib.generation "checktime"

do
  local cycle = 1888
  local delay = 300
  local focused = true

  local check = function()
    vim.cmd.checktime { mods = { silent = true, emsg_silent = true } }
  end

  local pending = {}
  local drain = lib.throttle(delay, function()
    local fns = pending
    pending = {}

    lib.report(function()
      for _, fn in pairs { check, wall } do
        if fns[fn] then
          fn()
        end
      end
    end)
  end)

  local schedule = function(...)
    for _, fn in pairs { ... } do
      pending[fn] = true
    end
    drain()
  end

  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume", "WinEnter" }, {
    group = lib.group,
    callback = function()
      focused = true
      schedule(check)
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusLost" }, {
    group = lib.group,
    callback = function()
      focused = false
      schedule(wall, check)
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = lib.group,
    callback = function()
      schedule(wall)
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(cycle)

      if not focused or not vim.startswith(vim.api.nvim_get_mode().mode, "i") then
        schedule(check)
      end
    end
  end)
end
