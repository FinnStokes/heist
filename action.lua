--- System for managigng player and guard actions

local system = require("system")
local timing = require("timing")

local M = {}

system.add(M)

--- Update actions for entities that have them
-- @param dt (number) Time delta in seconds.
-- @param ents (table) A list of entities with sprites (ignored if no sprite).
M.step = function (dt, ents)
  for _,e in ipairs(ents) do
    if e.action then
      if e.action.type == "moveTo" then
        if e.location and e.position then
          if timing.getTime() >= e.action.timestamp then
            e.location = {x = e.location.x + e.action.delta.x, y = e.location.y + e.action.delta.y}
            e.position = {x = e.location.x, y = e.location.y}
            e.action = nil
          else
            local frac =  1 - (e.action.timestamp - timing.getTime()) / e.action.dt
            e.position = {
              x = e.location.x + e.action.delta.x * frac,
              y = e.location.y + e.action.delta.y * frac,
            }
          end
        else
          e.action = nil
        end
      elseif e.action.type == "turnTo" then
        if e.facing then
          e.facing = e.action.facing
          if timing.getTime() >= e.action.timestamp then
            e.action = nil
          end
        else
          e.action = nil
        end
      else
        error("Undefined action " .. e.action.type)
        e.action = nil
      end
    end
  end
end

M.newMove = function (delta, time)
  time = time or 0.3
  local newAction = {
    type = "moveTo",
    timestamp = timing.getTime() + time,
    delta = {x = delta.x, y = delta.y},
    dt = time,
  }
  return newAction
end

M.newTurn = function (facing)
  local newAction = {
    type = "turnTo",
    timestamp = timing.getTime() + 0.1,
    facing = {x = facing.x, y = facing.y},
  }
  return newAction
end

return M
