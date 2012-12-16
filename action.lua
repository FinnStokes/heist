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
        if e.location and e.position and e.velocity then
          e.location = e.action.pos
          e.position = {x = e.action.pos.x, y = e.action.pos.y}
          if timing.getTime() >= e.action.timestamp then
            e.action = nil
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

M.newMove = function (pos)
  local newAction = {
    type = "moveTo",
    timestamp = timing.getTime() + 0.3,
    pos = {x = pos.x, y = pos.y},
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
