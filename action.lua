--- System for managigng player and guard actions

local level = require("level")
local sprite = require("sprite")
local system = require("system")
local timing = require("timing")

local M = {}

M.facing = {}
M.facing[0] = {}
M.facing[1] = {}
M.facing[-1] = {}
M.facing[0][1] = "up"
M.facing[0][-1] = "down"
M.facing[1][0] = "right"
M.facing[-1][0] = "left"

system.add(M)

M.queue = function (e, action)
  if e.action and not e.actionQueue then
    e.actionQueue = {}
  end
  
  table.insert(e.actionQueue, action)
end

--- Update actions for entities that have them
-- @param dt (number) Time delta in seconds.
-- @param ents (table) A list of entities with sprites (ignored if no sprite).
M.step = function (dt, ents)
  for _,e in ipairs(ents) do
    if e.action then
      if e.actionQueue then
        while e.actionQueue[1] and e.action.type == "idle" do
          e.action = table.remove(e.actionQueue,1)
        end
      end
      if e.action.type == "moveTo" then
        if not e.action.delta then
          e.action.delta = {
            x = e.action.location.x - e.location.x,
            y = e.action.location.y - e.location.y,
          }
        end
        if e.facing then
          sprite.play(e, M.facing[e.facing.x][e.facing.y])
        end
        if e.location and e.position then
          local tile = level.getTileProperties({x = e.location.x + e.action.delta.x, y = e.location.y + e.action.delta.y})
          if tile.solid then
            e.position = {x = e.location.x, y = e.location.y}
            e.action = {type = "idle"}
          elseif timing.getTime() >= e.action.timestamp then
            e.location = {x = e.location.x + e.action.delta.x, y = e.location.y + e.action.delta.y}
            e.position = {x = e.location.x, y = e.location.y}
            e.action = {type = "idle"}
          else
            local frac =  1 - (e.action.timestamp - timing.getTime()) / e.action.dt
            e.position = {
              x = e.location.x + e.action.delta.x * frac,
              y = e.location.y + e.action.delta.y * frac,
            }
          end
        else
          e.action = {type = "idle"}
        end
      elseif e.action.type == "turnTo" then
        if e.facing then
          e.facing = e.action.facing
          sprite.play(e, "idle_" .. M.facing[e.facing.x][e.facing.y])
          if timing.getTime() >= e.action.timestamp then
            e.action = {type = "idle"}
          end
        else
          e.action = {type = "idle"}
        end
      elseif e.action.type == "idle" then
        sprite.play(e, "idle_" .. M.facing[e.facing.x][e.facing.y])
      else
        error("Undefined action " .. e.action.type)
        e.action = {type = "idle"}
      end
    end
  end
end

M.newMove = function (location, time)
  time = time or (timing.getTime() + 0.3)
  local newAction = {
    type = "moveTo",
    timestamp = time,
    location = {x = location.x, y = location.y},
    dt = time - timing.getTime(),
  }
  return newAction
end

M.newTurn = function (facing, time)
  local newAction = {
    type = "turnTo",
    timestamp = time or (timing.getTime() + 0.1),
    facing = {x = facing.x, y = facing.y},
  }
  return newAction
end

return M
