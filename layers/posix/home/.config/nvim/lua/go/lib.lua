-- https://github.com/luvit/luv/blob/master/docs/docs.md

local M = {}

do
  M.group = vim.api.nvim_create_augroup([[lv_go]], { clear = true })
end

M.is_win = vim.fn.has [[win64]] == 1
  or vim.fn.has [[win64unix]] == 1
  or vim.fn.has [[win32]] == 1
  or vim.fn.has [[win32unix]] == 1

M.is_linux = vim.fn.has [[linux]] == 1

M.os = {
  sep = M.is_win and [[\]] or [[/]],
}

M.report = function(fn, ...)
  local ok, err = xpcall(fn, debug.traceback, ...)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return ok
end

M.scope = function(fn)
  local defers = {}
  local ok, ret = xpcall(fn, debug.traceback, function(defer)
    table.insert(defers, defer)
  end)

  for defer in vim.iter(defers):rev() do
    M.report(defer)
  end

  if ok then
    return ret
  else
    error(ret, 0)
  end
end

M.read_json = function(path)
  local json = vim.fn.readblob(path)
  return vim.json.decode(json)
end

M.buf_linefeed = function(buf)
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
end

M.sandbox = function(workdir, opts)
  if M.is_win or false then
    return {}
  end

  local oom = M.is_linux and { "choom", "--adjust", "1000", "--" } or {}
  local exec = vim.fs.joinpath(vim.env.HOME, ".local", "libexec", "sandbox", "libexec", "dispatch.sh")
  local net = opts.network and { "--network" } or {}
  return vim.iter({ { "nice", "-n", "19", "--" }, oom, { exec }, net, { "--dir", workdir, "--" } }):flatten():totable()
end

M.pack = function(name)
  if _G.Go.pack[name] ~= false then
    M.report(require, "go.pack." .. name)
  end
end

return M
