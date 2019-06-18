require "/scripts/wedit/libs/scriptHooks.lua"

local Task = include("/scripts/wedit/objects/task.lua")
local Logger = include("/scripts/wedit/helpers/logger.lua")

--- Manager class that tracks an indefinite amount of task objects.
-- All task objects are updated when the manager is updated.
local TaskManager = {}
TaskManager.__index = TaskManager
module = TaskManager

--- Instantiates a new task manager.
-- @return Coroutine manager.
function TaskManager:new()
  local instance = { items = {} }
  setmetatable(instance, self)
  return instance
end

--- Updates the manager.
-- This will continue all running tasks.
function TaskManager:update()
  for i = #self.items, 1, -1 do
    local task = self.items[i]

    if task.finished then
      table.remove(self.items, i)
    else
      task:update()
    end
  end
end

--- Returns the amount of running tasks.
-- @return Amount of running tasks.
function TaskManager:count()
  return #self.items
end

function TaskManager:start(task)
  table.insert(self.items, task)
end

function TaskManager:startNew(...)
  local task = Task:new(...)
  self:start(task)
  return task
end

function TaskManager:remove(task)
  for i=1,#self.items do
    if self.items[i] == task then
      table.remove(self.items, i)
      return true
    end
  end

  return false
end

--- Clears all tasks. Unsafe!
-- Clearing tasks during execution can have undesired effects.
function TaskManager:clear()
  self.items = {}
end

-- Shared instance
TaskManager.instance = TaskManager:new()

hook("update", function()
  TaskManager.instance:update()
  Logger.instance:setLogMap("Tasks", string.format("(%s) running.", TaskManager.instance:count()))
end)
