local M = {}

M.filetypes = function()
  return vim.iter(vim.filetype.inspect().extension):fold({}, function(acc, ext, raw)
    local ft = type(raw) == "string" and raw or vim.filetype.match { filename = "_." .. ext } or ext
    acc[ft] = acc[ft] or {}
    table.insert(acc[ft], ext)
    return acc
  end)
end

M.json_encode = function(data)
  return vim.json.encode(data, { indent = [[  ]], sort_keys = true })
end

M.json_decode = function(json)
  return vim.json.decode(json)
end

return M
