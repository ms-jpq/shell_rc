local T = require "tests.lib"

T.test({ "read ctrl z", timeout = 10000 }, function()
  local util = require "goto.fs_reconcile.util"
  local path = vim.fn.tempname()

  for _, format in ipairs { "dos", "unix" } do
    for _, binary in ipairs { false, true } do
      for _, text in ipairs { "dog\026", "dog\026\026", "dog\026body" } do
        local fd = assert(vim.uv.fs_open(path, "w", 384))
        assert(vim.uv.fs_write(fd, text, 0))
        assert(vim.uv.fs_close(fd))
        vim.cmd("edit! ++" .. (binary and "bin" or "nobin") .. " ++ff=" .. format .. " " .. vim.fn.fnameescape(path))
        local observed = assert(util.read_file(0, path))
        local native = util.buffer(0)
        assert(
          util.same_buffer(observed, native),
          vim.inspect {
            format = format,
            binary = binary,
            text = text,
            observed = observed,
            native = native,
          }
        )
      end
    end
  end
end)
