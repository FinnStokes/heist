--- Entity representing a player character

local action = require("action")
local entity = require("entity")
local event = require("event")
local level = require("level")
local resource = require("resource")
local sprite = require("sprite")
local system = require("system")

local SIGHT_RANGE = 4

local M = {}

entity.addTemplate("guard", function (self, args)
  self.location = { --Logical integer position
    x = args.x or 0,
    y = args.y or 0,
  }
  self.ai = { -- FSM with states: patrol, caution, alert, returning
    state = "patrol"
  }
  self.route = {} -- Polygonal path to follow
  if args.polygon then
    for _,pos in ipairs(args.polygon) do
      table.insert(self.route, {
        x = self.location.x + pos.x,
        y = self.location.y + pos.y,
      })
    end
  end
  self.route.next = 2 -- Index of next vertex in path to move to
  self.location.x = self.route[1].x
  self.location.y = self.route[1].y
  self.position = { --Fractional measure of your current position
    x = self.location.x,
    y = self.location.y,
  }
  self.facing = args.facing or {x = 0, y = 1} --Unit vector of players facing direction
  self.action = {type = "idle"}
  sprite.new(self, {
    image = resource.getImage("data/img/guard"),
    width = 16,
    height = 16,
    animations = {
      idle_down = {
        frames = {1},
        fps = 1,
      },
      idle_right = {
        frames = {17},
        fps = 1,
      },
      idle_left = {
        frames = {33},
        fps = 1,
      },
      idle_up = {
        frames = {49},
        fps = 1,
      },
      down = {
        frames = {0,1,2,3},
        fps = 5,
      },
      right = {
        frames = {16,17,18,19},
        fps = 5,
      },
      left = {
        frames = {32,33,34,35},
        fps = 5,
      },
      up = {
        frames = {48,49,50,51},
        fps = 5,
      },
    },
    playing = "idle_" .. action.facing[self.facing.x][self.facing.y],
  })
  entity.group(self, "guards")
  return self
end)

local move = function (e, dir)
  if e.facing.x ~= dir.x or e.facing.y ~= dir.y then
    e.action = action.newTurn({
      x = dir.x,
      y = dir.y,
    })
  else
    e.action = action.newMove({
      x = e.location.x + dir.x,
      y = e.location.y + dir.y,
    })
  end
end

local followRoute = function (dt, entities, e)
  if e.route then
    if e.action then
      if e.action.type == "idle" and #e.route > 0 then
        if e.route[e.route.next].x > e.location.x then
          move(e, {x = 1, y = 0})
        elseif e.route[e.route.next].x < e.location.x then
          move(e, {x = -1, y = 0})
        elseif e.route[e.route.next].y > e.location.y then
          move(e, {x = 0, y = 1})
        elseif e.route[e.route.next].y < e.location.y then
          move(e, {x = 0, y = -1})
        else
          e.route.next = e.route.next + 1
          if e.route.next > #e.route then
            e.route.next = 1
          end
        end
      end
    end
  end
end

local spot = function (dt, entities, e)
  local players = entity.getGroup("players")
  if players == nil or #players == 0 then
    return false
  end
  -- Check for collisions with guard's cones of vision
  for _,p in ipairs(players) do
    local dx = p.location.x - e.location.x
    local dy = p.location.y - e.location.y
    
    -- Convert to u,v cooardinates, which are facing-independent
    local u = (dx * e.facing.x) + (dy * e.facing.y)
    local v = (dy * e.facing.x) - (dx * e.facing.y)

    if u >= 0 and u <= SIGHT_RANGE and
        math.abs(v) <= u and math.abs(v) < SIGHT_RANGE then
      -- They are in the cone, check occlusion
      local occluded = false
      for i = 1, u do
        local j = (v / u) * i
        local j1 = math.floor(j)
        local j2 = math.ceil(j)
        -- Check both inner and outer rasterized rays
        for j = j1, j2 do
          local x = (i * e.facing.x) - (j * e.facing.y) + e.location.x
          local y = (i * e.facing.y) + (j * e.facing.x) + e.location.y
          if level.getTileProperties{x=x,y=y}.opaque then
            occluded = true
            break
          end
        end
      end
      if not occluded then
        -- The player has been spotted
        return true
      end
    end
  end
  
  -- We didn't see any players
  return false
end

local states = {
  alert = function (dt, entities, e)
  
  end,
  caution = function (dt, entities, e)
    
  end,
  patrol = function (dt, entities, e)
    local spotting, x, y = spot(dt, entities, e)
    if spotting then
      return "caution"
    end
    followRoute(dt, entities, e)
  end,
  returning = function (dt, entities, e)
  
  end,
}

local M = {}

system.add(M)

--- Updates the guards based on current AI state
M.step = function (dt, entities)
  local guards = entity.getGroup("guards")
  if guards and #guards > 0 then
    for _,e in ipairs(entities) do
      if e.ai then
        local newState = states[e.ai.state](dt, entities, e)
        if newState then
          e.ai.state = newState
        end
      end
    end
  end
end

return M
