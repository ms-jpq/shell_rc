-- https://github.com/luvit/luv/blob/master/docs/docs.md

local group = [[lv_go]]
vim.api.nvim_create_augroup(group, { clear = true })

local is_win = vim.fn.has [[win64]] == 1
  or vim.fn.has [[win64unix]] == 1
  or vim.fn.has [[win32]] == 1
  or vim.fn.has [[win32unix]] == 1
local is_linux = vim.fn.has [[linux]] == 1

return {
  group = group,
  is_win = is_win,
  os = {
    sep = is_win and [[\]] or [[/]],
  },
  scope = function(fn)
    local defers = {}
    local ok, ret = pcall(fn, function(defer)
      table.insert(defers, defer)
    end)

    for defer in vim.iter(defers):rev() do
      local ok, err = pcall(defer)
      if not ok then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end

    if ok then
      return ret
    else
      error(ret, 0)
    end
  end,
  read_json = function(path)
    local json = vim.fn.readblob(path)
    return vim.json.decode(json)
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
  sandbox = function(workdir, opts)
    if is_win or false then
      return {}
    end

    local oom = is_linux and { "choom", "--adjust", "1000", "--" } or {}
    local exec = vim.fs.joinpath(vim.env.HOME, ".local", "opt", "sandbox", "libexec", "dispatch.sh")
    local net = opts.network and { "--network" } or {}
    return vim.iter({ { "nice", "-n", "19", "--" }, oom, { exec }, net, { "--dir", workdir, "--" } }):flatten():totable()
  end,
}
