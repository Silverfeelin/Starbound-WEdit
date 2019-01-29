--- Simple manager for (multiple) SM objects.
--
-- LICENSE
-- MIT License. https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

require "/scripts/wedit/stateMachine.lua"

--- Manager class that tracks an indefinite amount of SM objects.
-- All SM objects are updated when the manager is updated.
SMManager = {}
SMManager.__index = SMManager

--- Instantiates a new coroutine manager.
-- @return Coroutine manager.
function SMManager:new()
  local instance = { items = {} }
  setmetatable(instance, self)
  return instance
end

--- Updates the manager.
-- This will continue all running tasks.
function SMManager:update()
  for i = #self.items, 1, -1 do
    local sm = self.items[i]

    if sm.finished then
      table.remove(self.items, i)
    else
      sm:update()
    end
  end
end

--- Returns the amount of running tasks.
-- @return Amount of running tasks.
function SMManager:count()
  return #self.items
end

--- Starts updating an SM object.
-- @param sm SM object.
function SMManager:start(sm)
  table.insert(self.items, sm)
end

function SMManager:startNew(...)
  local sm = SM:new(...)
  self:start(sm)
  return sm
end

--- Removes an SM object.
-- @param sm SM object to remove.
-- @return True if the sm was removed, false if the sm wasn't found.
function SMManager:remove(sm)
  for i=1,#self.items do
    if self.items[i] == sm then
      table.remove(self.items, i)
      return true
    end
  end

  return false
end

--- Clears all SM objects. Unsafe!
-- Clearing SM objects during execution can have undesired effects.
function SMManager:clear()
  self.items = {}
end
