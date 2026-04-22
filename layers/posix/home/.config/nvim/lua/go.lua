-- https://github.com/luvit/luv/blob/master/docs/docs.md

local group = [[lv_go]]
vim.api.nvim_create_augroup(group, { clear = true })

local is_win = vim.fn.has [[win32]] == 1 or vim.fn.has [[win32unix]] == 1

return {
  group = group,
  is_win = is_win,
  os = {
    sep = is_win and [[\]] or [[/]],
  },
  read_json = function(path)
    local json = vim.fn.readblob(path)
    return vim.json.decode(json, { luanil = { object = true, array = true } })
  end,
  buf_linefeed = function(buf)
    local ff = vim.bo[buf].fileformat

    if ff == "dos" then
      return "\r\n"
    elseif ff == "unix" then
      return "\n"
    else
      if ff == "mac" then
        return "\r"
      else
        assert(false, ff)
      end
    end
  end,
  sandbox = function(workdir)
    if is_win or false then
      return {}
    end

    local exec = vim.fs.joinpath(vim.env.HOME, ".local", "opt", "sandbox", "libexec", "dispatch.sh")
    return { exec, "--dir", workdir, "--" }
  end,
}
