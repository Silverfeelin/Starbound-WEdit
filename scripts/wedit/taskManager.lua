--- Task managers can be used to run asynchronous tasks.
TaskManager = {}
TaskManager.__index = TaskManager

--- Instantiates a new task manager.
-- @return Task manager.
function TaskManager.new()
  local instance = {}
  setmetatable(instance, TaskManager)
  instance.tasks = {}
  return instance
end

function TaskManager:update()
  local toRemove = {}

  -- Check and update tasks.
  for i=1, #self.tasks do
    local task = self.tasks[i]
    if coroutine.status(task.coroutine) == "dead" then
      -- Remove completed task.
      table.insert(toRemove, i)
    else
      -- Update incomplete task.
      local a, b = coroutine.resume(task.coroutine)
      if b then error(b) end

      if task.callback then
        task.callback()
      end
    end

  end
  -- Remove completed tasks.
  for i=#toRemove, 1, -1 do
    table.remove(self.tasks, i)
  end
end

--- Returns the amount of running tasks.
-- @return Amount of running tasks.
function TaskManager:count()
  return #self.tasks
end

--- Starts a task.
-- @param task Task to start.
-- @return True if the task started. False if the task was already running or completed.
function TaskManager:start(task)
  if task.running or task.completed then return false end
  task.running = true
  table.insert(self.tasks, task)
  return true
end

--- Removes a task.
-- @param task Task to remove.
-- @return True if the task was removed, false if the task wasn't running.
function TaskManager:remove(task)
  for i=1,#self.tasks do
    if self.tasks[i] == task then
      table.remove(self.tasks, i)
      return true
    end
  end

  return false
end

--- Clears all tasks. Unsafe!
-- Clearing tasks during execution can have undesired effects.
function TaskManager:clear()
  self.tasks = {}
end

--- Tasks are actions that take time to complete.
-- Tasks consist of one or more stages that can each take one or more iterations to complete.
-- When all stages are completed, the task is done.
-- A TaskManager should be used to run tasks.
Task = {}
Task.__index = Task
Task.__tostring = function() return "task" end

Task.defaultDelay = 15

--- Instantiates a new task.
-- @param stages Table of functions, each representing a stage of the task.
-- The functions are passed the task object, so you can access the task parameters from within the functions.
--  task:nextStage():  Increases task.stage by 1. The next TaskManager update will move the task to the next stage.
--  task.progress: Can be used to keep track of task progress. Starts at 0.
--  task.stageProgress: Can be used to keep track of progress. Starts at 0 and resets every stage.
--  task.parameters: Table that can be used to save and read parameters.
--  task.complete(): Sets task.completed to true. Does not abort remaining code when called in a stage function.
--  task.callback: Function called every tick, regardless of delay and stage. Can be used to display (debug) information.
-- Yes I know this system would be better and less complicated without the stages but reworking it would take me too long.
-- I made this system a long time ago when thinking of a way to dynamically include/exclude stages from a task.
-- @param[opt=Task.defaultDelay] delay Amount of frames between each time the stages are resumed.
-- @return Task
function Task.new(stages, delay)
  local task = {}
  setmetatable(task, Task)

  task.stages = type(stages) == "table" and stages or {stages}
  task.delay = delay or task.defaultDelay

  task.stage = 1
  task.stageProgress = 0
  task.progress = 0
  task.completed = false
  task.parameters = {}

  task.coroutine = coroutine.create(function()
    while not task.completed do
      util.wait(task.delay / 60)
      task.stages[task.stage](task)
    end

    -- Reset task so it can be repeated.
    task.completed = false
    task.stage = 1
    task.stageProgress = 0
    task.progress = 0
    task.parameters = {}
  end)

  return task
end

--- Proceeds to the next stage.
-- If there is no next stage, mark the task complete.
function Task:nextStage()
  self.stage = self.stage + 1
  if self.stage > #self.stages then
    self:complete()
    return
  end

  self.stageProgress = 0
end

--- Marks the task as complete.
function Task:complete()
  self.completed = true
end

--- Simple task example
--[[
local testTask = Task.new({
  function(task)
    task.stageProgress = task.stageProgress + 1
    sb.logInfo("First stage progress: %s", task.stageProgress)
    if task.stageProgress >= 5 then
      task:nextStage()
    end
  end,
  function(task)
    task.stageProgress = task.stageProgress + 1
    if math.random(5) == 3 then
      sb.logInfo("Rolling 3 took %s rolls!", task.stageProgress)
      task:nextStage()
    end
  end
}, 2)

taskManager:start(testTask)
--]]
