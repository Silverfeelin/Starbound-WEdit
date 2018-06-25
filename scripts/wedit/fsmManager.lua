--- Simple manager for (multiple) FSM objects.
-- State functions are passed the FSM object so that the state can easily be changed with fsm:set(newState, fsm)
--
-- LICENSE
-- This file falls under an MIT License, which is part of this project.
-- An online copy can be viewed via the following link:
-- https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

require "/scripts/util.lua"

--- util.wait, but in ticks (updates) rather than seconds.
-- @param ticks Amount of update ticks to wait.
-- @param [action] Function called every tick. If the function returns a value the wait ends early.
function util.waitTicks(ticks, action)
  local t = 0
  while t < ticks do
    if action ~= nil and action(dt) then return end
    t = t + 1
    coroutine.yield(false)
  end
end

--- util.wait, but waits until predicate returns true.
-- @param predicate Function that determines if the delay should continue (by returning false).
-- @param [timeout=60] Timeout in amount of coroutine.resume calls.
function util.waitFor(predicate, timeout)
  timeout = timeout or 60

  local t = 0
  while not predicate() and t < timeout do
    t = t + 1
    coroutine.yield(false)
  end
end

--- Manager class that tracks an indefinite amount of FSM objects.
-- All FSM objects are updated when the manager is updated.
FSMManager = {}
FSMManager.__index = FSMManager

--- Instantiates a new coroutine manager.
-- @return Coroutine manager.
function FSMManager.new()
  local instance = { items = {} }
  setmetatable(instance, FSMManager)
  return instance
end

--- Updates the manager.
-- This will continue all running tasks.
function FSMManager:update()
  for i = #self.items, 1, -1 do
    local fsm = self.items[i]

    if not fsm.state or coroutine.status(fsm.state) == "dead" then
      table.remove(self.items, i)
    else
      fsm:update()
    end
  end
end

--- Returns the amount of running tasks.
-- @return Amount of running tasks.
function FSMManager:count()
  return #self.items
end

--- Starts updating an FSM object.
-- @param fsm FSM object.
function FSMManager:start(fsm)
  table.insert(self.items, fsm)
end

function FSMManager:startNew(initialState)
  local fsm = FSM:new()
  fsm:set(initialState, fsm)
  self:start(fsm)
  return fsm
end

--- Removes an FSM object.
-- @param fsm FSM object to remove.
-- @return True if the fsm was removed, false if the fsm wasn't found.
function TaskManager:remove(fsm)
  for i=1,#self.items do
    if self.items[i] == fsm then
      table.remove(self.items, i)
      return true
    end
  end

  return false
end

--- Clears all FSM objects. Unsafe!
-- Clearing FSM objects during execution can have undesired effects.
function FSMManager:clear()
  self.items = {}
end
