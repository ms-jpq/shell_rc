-- limit session restoration info
vim.opt.sessionoptions:remove("blank", "buffers", "curdir")
vim.opt.sessionoptions:append("skiprtp")

local cache = vim.fn.stdpath("cache")

local session_path = function()
  local cwd = vim.fs.normalize(vim.fn.getcwd(), {expand_env = false})
  local name = vim.re.gsub(cwd, "[/\\]", ".")
  local path = vim.fs.joinpath(cache, "sessions", name)
  local norm = vim.fs.normalize(path, {expand_env = false})
  local escaped = vim.fn.fnameescape(norm)
  return {norm .. ".vim", escaped}
end

local mk_session = function()
  local path, escaped = unpack(session_path())
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p", 0755)

  vim.cmd([[mksession! ]] .. escaped)
end

vim.api.nvim_create_autocmd(
  {"SessionWritePost"},
  {
    callback = function()
      vim.cmd [[doautocmd User CHADSave]]
    end
  }
)

vim.api.nvim_create_autocmd({"VimLeavePre", "VimSuspend", "FocusLost", "CursorHold"}, {callback = mk_session})

vim.api.nvim_create_autocmd(
  {"VimEnter"},
  {
    callback = vim.schedule_wrap(
      function()
        if vim.env.NO_SESSION then
          return
        end

        local bufs = vim.api.nvim_list_bufs()
        for _, buf in ipairs(bufs) do
          if vim.api.nvim_buf_get_name(buf) ~= "" then
            return
          end
        end

        local path, escaped = unpack(session_path())
        if vim.fn.filereadable(path) then
          vim.cmd([[silent! source ]] .. escaped)
        end
      end
    )
  }
)

vim.api.nvim_create_user_command(
  "KillSession",
  function()
    vim.cmd [[%bwipeout!]]
    mk_session()
  end,
  {}
)
