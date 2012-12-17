-- path.lua
-- A* pathfinding algorithm

local level = require("level")

M = {}

local heuristic = function(src, dst)
  return math.abs(dst.x - src.x) + math.abs(dst.y - src.y)
end

local directions = function (from, last)
  if last == nil then
    return {
      x = from.x + 1,
      y = from.y,
    }
  elseif last.x > from.x then
    return {
      x = from.x,
      y = from.y + 1,
    }
  elseif last.y > from.y then
    return {
      x = from.x - 1,
      y = from.y,
    }
  elseif last.x < from.x then
    return {
      x = from.x,
      y = from.y - 1,
    }
  else
    return nil
  end
end

M.get = function (src, dst)
  local spt = {}
  local sf = {}
  local costs = {}
  local pq = {}
  
  costs[src.x] = {}
  costs[src.x][src.y] = 0
  pq[1] = {0, src}
  while #pq > 0 do
    table.sort(pq, function(a,b)
      return a[1] > b[1]
    end)
    local next = table.remove(pq)
    local cost = next[1]
    local node = next[2]
    if sf[node.x] and sf[node.x][node.y] then
      if spt[node.x] == nil then
        spt[node.x] = {}
      end
      spt[node.x][node.y] = sf[node.x][node.y]
    end
    
    if node.x == dst.x and node.y == dst.y then
      local path = {dst}
      while path[#path].x ~= src.x or path[#path].y ~= src.y do
        table.insert(path, spt[path[#path].x][path[#path].y])
      end
      path.cost = costs[dst.x][dst.y]
      return path
    end
    
    if not level.getTileProperties(node).solid then
      for pos in directions,node,nil do
        local newCost = costs[node.x][node.y] + 1
        local adjustedCost = newCost + heuristic(pos, dst)
        if sf[pos.x] == nil or sf[pos.x][pos.y] == nil then
          if costs[pos.x] == nil then
            costs[pos.x] = {}
          end
          costs[pos.x][pos.y] = newCost
          table.insert(pq, {adjustedCost,pos})
          if sf[pos.x] == nil then
            sf[pos.x] = {}
          end
          sf[pos.x][pos.y] = node
        elseif newCost < costs[pos.x][pos.y] then
          costs[pos.x][pos.y] = newCost
          for k,v in ipairs(pq) do
            if v[2].x == pos.x and v[2].y == pos.y then
              pq[k][1] = adjustedCost
              break
            end
          end
          sf[pos.x][pos.y] = node
        end
      end
    end
  end
  
  return nil
end

return M
