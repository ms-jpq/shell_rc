local M = {}

M.filetypes = function()
  return vim
    .iter(vim.filetype.inspect().extension)
    :filter(function(_, filetype)
      return type(filetype) == "string"
    end)
    :fold({}, function(acc, filetype, ext)
      acc[filetype] = acc[filetype] or {}
      table.insert(acc[filetype], ext)
      return acc
    end)
end

M.json_encode = function(data)
  return vim.json.encode(data, { indent = [[  ]], sort_keys = true })
end

M.json_decode = function(json)
  return vim.json.decode(json, { luanil = { object = true, array = true } })
end

return M
