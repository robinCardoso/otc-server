-- @docclass string

function string:split(delim)
  local start = 1
  local results = {}
  while true do
    local pos = string.find(self, delim, start, true)
    if not pos then
      break
    end
    table.insert(results, string.sub(self, start, pos-1))
    start = pos + string.len(delim)
  end
  table.insert(results, string.sub(self, start))
  table.removevalue(results, '')
  return results
end

function string:starts(start)
  return string.sub(self, 1, #start) == start
end

function string:ends(test)
   return test =='' or string.sub(self,-string.len(test)) == test
end

function string:trim()
  return string.match(self, '^%s*(.*%S)') or ''
end

function string:explode(sep, limit)
  if type(sep) ~= 'string' or tostring(self):len() == 0 or sep:len() == 0 then
    return {}
  end

  local i, pos, tmp, t = 0, 1, "", {}
  for s, e in function() return string.find(self, sep, pos) end do
    tmp = self:sub(pos, s - 1):trim()
    table.insert(t, tmp)
    pos = e + 1

    i = i + 1
    if limit ~= nil and i == limit then
      break
    end
  end

  tmp = self:sub(pos):trim()
  table.insert(t, tmp)
  return t
end

function string:contains(str, checkCase, start, plain)
  if(not checkCase) then
    self = self:lower()
    str = str:lower()
  end
  return string.find(self, str, start and start or 1, plain == nil and true or false)
end

-- Converte UTF-8 para Latin-1/CP1252 (fontes bitmap do OTC nao renderizam UTF-8 multi-byte).
-- Espelha stdext::utf8_to_latin1 em src/framework/stdext/string.cpp
function string:utf8ToLatin1()
  if not self:find('[\192-\244][\128-\191]') then
    return self
  end

  local out = {}
  local i = 1
  local len = #self
  while i <= len do
    local c = self:byte(i)
    i = i + 1
    if (c >= 32 and c < 128) or c == 0x0d or c == 0x0a or c == 0x09 then
      out[#out + 1] = string.char(c)
    elseif c == 0xc2 or c == 0xc3 then
      local c2 = self:byte(i)
      if c2 then
        i = i + 1
        if c == 0xc2 then
          if c2 > 0xa1 and c2 < 0xbb then
            out[#out + 1] = string.char(c2)
          end
        elseif c == 0xc3 then
          out[#out + 1] = string.char(64 + c2)
        end
      end
    elseif c >= 0xc4 and c <= 0xdf then
      i = i + 1
    elseif c >= 0xe0 and c <= 0xed then
      i = i + 2
    elseif c >= 0xf0 and c <= 0xf4 then
      i = i + 3
    end
  end
  return table.concat(out)
end
