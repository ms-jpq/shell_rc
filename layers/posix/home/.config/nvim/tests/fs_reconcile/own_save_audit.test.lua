local T = require "tests.lib"

T.test({ "own save audit", timeout = 10000 }, function()
  local async = require "goto.async"
  local hunks = require "goto.fs_reconcile.hunks"
  local util = require "goto.fs_reconcile.util"
  local scenario = vim.env.FS_RECONCILE_AUDIT or "ordinary"
  local filename = vim.fn.tempname()
  local prefix = "so i think there is something really imporatnt, which is we"
  local typo = prefix .. " have all the skilsl right?"
  local corrected = prefix .. " have all the skills right?"
  vim.fn.writefile({ prefix }, filename)
  vim.cmd.edit(filename)
  require "goto.fs_reconcile"
  vim.api.nvim_exec_autocmds({ "VimEnter" }, {})
  async.sleep(100)

  local merges = {}
  local merge = hunks.merge
  T.patch(hunks, "merge", function(base, current, disk)
    table.insert(merges, { base = base.text, current = current.text, disk = disk.text })
    return merge(base, current, disk)
  end)

  local read_file = util.read_file
  local command = vim.cmd
  local fail_read = false
  T.patch(vim, "cmd", function(source)
    local result = command(source)
    if scenario == "unreadable" and string.find(source, "noautocmd silent! write!", 1, true) then
      fail_read = true
    end
    return result
  end)
  T.patch(util, "read_file", function(...)
    if fail_read then
      fail_read = false
      return nil, util.READ.UNSTABLE
    end
    return read_file(...)
  end)

  local saved = false
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = 0,
    once = true,
    callback = function()
      saved = true
      vim.api.nvim_buf_set_lines(0, 0, -1, true, { corrected })
      if scenario == "post_error" then
        error "injected post-write hook failure"
      elseif scenario == "unmodifiable" then
        vim.bo.modifiable = false
        vim.defer_fn(function()
          vim.bo.modifiable = true
        end, 50)
      end
    end,
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { typo })
  async.sleep(1800)
  vim.cmd = command
  util.read_file = read_file
  hunks.merge = merge
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  assert(saved, scenario .. ": no save")
  assert(
    #merges == 0 and vim.deep_equal(actual, { corrected }),
    vim.inspect {
      scenario = scenario,
      merges = merges,
      actual = actual,
      disk = vim.fn.readfile(filename),
    }
  )
end)
