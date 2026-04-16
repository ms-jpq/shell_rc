return function()
  local push, pop = {}, {}

  return {
    push = function(val)
      table.insert(push, val)
    end,
    pop = function()
      if #pop == 0 then
        while #push ~= 0 do
          table.insert(pop, table.remove(push))
        end
      end
      return table.remove(pop)
    end,
    len = function()
      return #push + #pop
    end,
  }
end
