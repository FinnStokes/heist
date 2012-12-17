--- A collection of useful utility functions.

math.sign = function (x)
  if x == 0 then
    return 0
  end
  return (x / math.abs(x))
end

string.split = function (self, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

string.trim = function (self)
  return self:match("^%s*(.-)%s*$")
end
