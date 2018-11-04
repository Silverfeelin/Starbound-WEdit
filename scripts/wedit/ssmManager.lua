--- Simple manager for (multiple) SSM objects.
--
-- LICENSE
-- MIT License. https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

require "/scripts/wedit/sequentialStateMachine.lua"

--- Manager class that tracks an indefinite amount of SSM objects.
-- All SSM objects are updated when the manager is updated.
SSMManager = {}
SSMManager.__index = SSMManager

--- Instantiates a new coroutine manager.
-- @return Coroutine manager.
function SSMManager:new()
  local instance = { items = {} }
  setmetatable(instance, self)
  return instance
end

--- Updates the manager.
-- This will continue all running tasks.
function SSMManager:update()
  for i = #self.items, 1, -1 do
    local ssm = self.items[i]

    if ssm.finished then
      table.remove(self.items, i)
    else
      ssm:update()
    end
  end
end

--- Returns the amount of running tasks.
-- @return Amount of running tasks.
function SSMManager:count()
  return #self.items
end

--- Starts updating an SSM object.
-- @param ssm SSM object.
function SSMManager:start(ssm)
  table.insert(self.items, ssm)
end

function SSMManager:startNew(...)
  local ssm = SSM:new(...)
  self:start(ssm)
  return ssm
end

--- Removes an SSM object.
-- @param ssm SSM object to remove.
-- @return True if the ssm was removed, false if the ssm wasn't found.
function SSMManager:remove(ssm)
  for i=1,#self.items do
    if self.items[i] == ssm then
      table.remove(self.items, i)
      return true
    end
  end

  return false
end

--- Clears all SSM objects. Unsafe!
-- Clearing SSM objects during execution can have undesired effects.
function SSMManager:clear()
  self.items = {}
end
