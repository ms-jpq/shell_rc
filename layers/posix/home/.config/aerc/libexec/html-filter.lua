---@diagnostic disable: undefined-global, global-element
_G.remove_attr = function(x)
  if x.attr then
    x.attr = pandoc.Attr()
    return x
  end
end

return { { Inline = remove_attr, Block = remove_attr } }
