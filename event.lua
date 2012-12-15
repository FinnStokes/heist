-- event.lua
-- The event manager majiga

local M = {}

local subQueue = {}
local noteQueue = {}
local subbed = {}

--Called to put into action anything corresponding to a particular event
M.notify = function (event, data)
  table.insert(noteQueue, {event, data})
end

--Subscribe a certain action to a particular event
M.subscribe = function (event, action)
  table.insert(subQueue, {event, action, true})
end

--Remove an action from a particular event
M.unsubscribe = function (event, action)
  table.insert(subQueue, {event, action, false})
end

--The update method called each tick which deals with the events
M.update = function (dt)
  --Deal with the subscribe queue wrt the subscribed list
  for _,t in ipairs(subQueue) do
    if t[3] then
      --Make sure the index exists
      if not subbed[t[1]] then
        subbed[t[1]] = {}
      end

      --Add new subscriptions to the subbed list
      table.insert(subbed[t[1]], t[2])
    else
      if subbed[t[1]] then
        --Remove un-subscriptions from subbed lists
        for key,s in ipairs(subbed[t[1]]) do
          if s == t[2] then
            table.remove(subbed[t[1]], key)
            break
          end
        end
      end
    end
  end
  --Clear the subscription queue
  subQueue = {}

  --Actually perform the required actions for a specific event
  local queue = noteQueue
  noteQueue = {}
  for _,t in ipairs(queue) do
    for _,a in ipairs(subbed[t[1]]) do
      a(t[2])
    end
  end
end