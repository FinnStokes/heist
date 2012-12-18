--- Entity representing a player character

local action = require("action")
local entity = require("entity")
local event = require("event")
local level = require("level")
local path = require("path")
local resource = require("resource")
local sprite = require("sprite")
local system = require("system")
local timing = require("timing")

local SIGHT_RANGE = 4

local M = {}

system.add(M)

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
      attack_down = {
        frames = {4,5,6,7},
        fps = 5,
      },
      attack_right = {
        frames = {20,21,22,23},
        fps = 5,
      },
      attack_left = {
        frames = {36,37,38,39},
        fps = 5,
      },
      attack_up = {
        frames = {52,53,54,55},
        fps = 5,
      },
    },
    playing = "idle_" .. action.facing[self.facing.x][self.facing.y],
  })
  sprite.new(self, {
    image = resource.getImage("data/img/question"),
    width = 16,
    height = 16,
    originY = 16,
    animations = {
      question_hide = {
        frames = {0},
        fps = 1,
      },
      question_show = {
        frames = {4},
        fps = 1,
      },
      question = {
        frames = {1,2,3,4},
        fps = 5,
        goto = "question_show",
      },
      noquestion = {
        frames = {4,3,2,1},
        fps = 5,
        goto = "question_hide",
      },
    },
    playing = "question_hide",
  })
  sprite.new(self, {
    image = resource.getImage("data/img/exclamation"),
    width = 16,
    height = 16,
    originY = 16,
    animations = {
      exclamation_hide = {
        frames = {0},
        fps = 1,
      },
      exclamation_show = {
        frames = {4},
        fps = 1,
      },
      exclamation = {
        frames = {1,2,3,4},
        fps = 5,
        goto = "exclamation_show",
      },
      noexclamation = {
        frames = {4,3,2,1},
        fps = 5,
        goto = "exclamation_hide",
      },
    },
    playing = "exclamation_hide",
  })
  entity.group(self, "guards")
  return self
end)

local move = function (e, dir, fast)
  if e.facing.x ~= dir.x or e.facing.y ~= dir.y then
    e.action = action.newTurn({
      x = dir.x,
      y = dir.y,
    })
  else
    if fast then
      e.action = action.newMove({
        x = e.location.x + dir.x,
        y = e.location.y + dir.y,
      })
    else
      e.action = action.newGuardMove({
        x = e.location.x + dir.x,
        y = e.location.y + dir.y,
      })
    end
  end
end

local goto = function (e, pos, fast)
  if e.action and e.action.type == "idle" and
      (not e.actionQueue or #e.actionQueue == 0)then
    if pos.x > e.location.x then
      move(e, {x = 1, y = 0}, fast)
    elseif pos.x < e.location.x then
      move(e, {x = -1, y = 0}, fast)
    elseif pos.y > e.location.y then
      move(e, {x = 0, y = 1}, fast)
    elseif pos.y < e.location.y then
      move(e, {x = 0, y = -1}, fast)
    else
      return true
    end
  end
  return false
end

local followRoute = function (dt, entities, e)
  if e.route and #e.route > 0 then
    while goto(e, e.route[e.route.next]) do
      -- finished
      e.route.next = e.route.next + 1
      if e.route.next > #e.route then
        e.route.next = 1
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
    if p.active then
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
          return true, p
        end
      end
    end
  end
  
  -- We didn't see any players
  return false
end

local states = {
  alert = function (dt, entities, e)
    if e.ai.target.active then
      e.ai.target.active = false
      event.notify("stop", e.ai.target)
    end
    if not e.ai.path or #e.ai.path <= 1 then
      e.ai.path = path.get(e.location, e.ai.target.location)
      table.remove(e.ai.path)
    end
    if e.ai.path and #e.ai.path > 1 then
      while #e.ai.path > 1 and goto(e, e.ai.path[#e.ai.path], true) do
        table.remove(e.ai.path)
      end
    else
      if e.action.type == "idle" then
        e.action = action.newAttack(e.ai.target)
        e.ai.path = nil
        return "returning"
      end
    end
  end,
  caution = function (dt, entities, e)
    for _,p in ipairs(entity.getGroup("players")) do
      if p.active and
          p.location.x <= e.location.x + 1 and
          p.location.y <= e.location.y + 1 and
          p.location.x >= e.location.x - 1 and
          p.location.y >= e.location.y - 1 then
        e.ai.target = p
        e.ai.path = nil
        action.queue(e, {type = "alert"})
        return "alert"
      end
    end
    local spotting, target = spot(dt, entities, e)
    if spotting then
      e.ai.target = target
      e.ai.targetPos = {x = target.location.x, y = target.location.y}
      e.ai.spotTime = e.ai.spotTime + dt
      if e.ai.spotTime > 1 then
        e.ai.path = nil
        action.queue(e, {type = "alert"})
        return "alert"
      end
    else
      e.ai.spotTime = 0
    end
    if not e.ai.path or
        (#e.ai.path > 0 and 
         (e.ai.path[1].x ~= e.ai.targetPos.x or
          e.ai.path[1].y ~= e.ai.targetPos.y or
          e.ai.path[#e.ai.path].x ~= e.location.x or
          e.ai.path[#e.ai.path].y ~= e.location.y)) then
      e.ai.path = path.get(e.location, e.ai.targetPos)
    end
    if #e.ai.path > 0 then
      while #e.ai.path > 0 and goto(e, e.ai.path[#e.ai.path], true) do
        table.remove(e.ai.path)
      end
    else
      e.ai.path = nil
      action.queue(e, action.newTurn({x = e.facing.y, y = -e.facing.x}, timing.getTime()+0.3))
      action.queue(e, action.newTurn({x = -e.facing.y, y = e.facing.x}, timing.getTime()+0.6))
      action.queue(e, action.newTurn({x = -e.facing.x, y = -e.facing.y}, timing.getTime()+0.9))
      return "searching"
    end
  end,
  patrol = function (dt, entities, e)
    if e.action.type == "idle" then
      local spotting, target = spot(dt, entities, e)
      if spotting then
        e.ai.spotTime = 0
        e.ai.target = target
        e.ai.targetPos = {x = target.location.x, y = target.location.y}
        action.queue(e, {type = "caution"})
        return "caution"
      end
    end
    followRoute(dt, entities, e)
  end,
  returning = function (dt, entities, e)
    if not e.ai.path then
      e.ai.path = path.get(e.location, e.route[e.route.next])
    end
    if #e.ai.path > 0 then
      while #e.ai.path > 0 and goto(e, e.ai.path[#e.ai.path]) do
        table.remove(e.ai.path)
      end
    else
      e.ai.path = nil
      return "patrol"
    end
  end,
  searching = function (dt, entities, e)
    for _,p in ipairs(entity.getGroup("players")) do
      if p.active and
          p.location.x <= e.location.x + 1 and
          p.location.y <= e.location.y + 1 and
          p.location.x >= e.location.x - 1 and
          p.location.y >= e.location.y - 1 then
        e.ai.target = p
        e.ai.path = nil
        e.actionQueue = {}
        action.queue(e, {type = "alert"})
        return "alert"
      end
    end
    local spotting, target = spot(dt, entities, e)
    if spotting then
      e.ai.target = target
      e.ai.targetPos = {x = target.location.x, y = target.location.y}
      e.ai.spotTime = e.ai.spotTime + dt
      if e.ai.spotTime > 1 then
        e.ai.path = nil
        e.actionQueue = {}
        action.queue(e, {type = "alert"})
        return "alert"
      else
        e.actionQueue = {}
        return "caution"
      end
    else
      e.ai.spotTime = 0
    end
    if e.action.type == "idle" then
      action.queue(e, {type = "patrol"})
      return "returning"
    end
  end
}

--- Updates the guards based on current AI state (if server)
M.step = function (dt, entities)
  if isServer ~= true then
    return
  end
  local guards = entity.getGroup("guards")
  if guards and #guards > 0 then
    for _,e in ipairs(guards) do
      local action = e.action
      local newState = states[e.ai.state](dt, entities, e)
      if newState then
        e.ai.state = newState
      end
      if action ~= e.action then
        event.notify("newAction", e)
      end
    end
  end
end

return M
