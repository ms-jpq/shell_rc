-- https://github.com/luvit/luv/blob/master/docs/docs.md

return {
  is_win = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1,
  read_json = function(path)
    local json = vim.fn.readblob(path)
    return vim.json.decode(json, {luanil = {object = true, array = true}})
  end
}
