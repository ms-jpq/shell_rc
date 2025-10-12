local lib = require("go")

-- limit session restoration info
vim.opt.sessionoptions:remove("blank", "buffers", "curdir", "help", "terminal")
vim.opt.sessionoptions:append("skiprtp")

-- scratch buffer
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_get_name(buf) == "" then
    vim.bo[buf].buftype = "nofile"
  end
end

local no_session = (function()
  local cached = nil

  return function()
    if cached ~= nil then
      return cached
    end

    cached = vim.fn.getcwd() == vim.uv.os_homedir() or vim.fn.argc(-1) > 0 or (function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local stdin = vim.api.nvim_buf_line_count(buf) > 1 or (function()
              local lines = vim.api.nvim_buf_get_lines(buf, -2, -1, true)

              return #lines > 0 and #lines[1] > 0
            end)()

          if stdin then
            vim.opt.wrap = false
            return true
          end
        end
        return false
      end)()

    return cached
  end
end)()

local session_path = function()
  local cwd = vim.fn.getcwd()
  local name = vim.re.gsub(cwd, "[/\\]", ".")
  local path = vim.fs.joinpath(vim.fn.stdpath("cache"), "sessions", name)
  local norm = vim.fs.normalize(path, {expand_env = false})
  local escaped = vim.fn.fnameescape(norm)
  return norm .. ".vim", escaped
end

local mk_session = function(kill)
  if not kill and no_session() then
    return
  end

  local path, escaped = session_path()
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p", 0755)

  vim.cmd([[mksession! ]] .. escaped)
end

vim.api.nvim_create_user_command(
  "KillSession",
  function()
    vim.cmd [[silent! %bwipeout!]]
    mk_session(true)
  end,
  {}
)

vim.api.nvim_create_autocmd({"VimSuspend", "FocusLost", "CursorHold"}, {group = lib.group, callback = mk_session})

vim.api.nvim_create_autocmd(
  {"QuitPre"},
  {
    group = lib.group,
    once = true,
    callback = function()
      if no_session() then
        return
      end

      local dead = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted then
          local name = vim.api.nvim_buf_get_name(buf)
          if vim.fn.filereadable(name) == 0 then
            table.insert(dead, buf)
          end
        end
      end

      if #dead > 0 then
        vim.cmd([[bwipeout! ]] .. table.concat(dead, " "))
      end

      mk_session()
    end
  }
)

vim.api.nvim_create_autocmd(
  {"VimEnter"},
  {
    group = lib.group,
    once = true,
    callback = vim.schedule_wrap(
      function()
        if no_session() then
          return
        end

        local path, escaped = session_path()
        if vim.fn.filereadable(path) then
          vim.cmd([[silent! source ]] .. escaped)
        end
      end
    )
  }
)
