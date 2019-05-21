local Task = {}
Task.__index = Task
module = Task

--- Instantiates a new task.
-- @param func Function
function Task:new(func)
  if type(func) ~= "function" then error("Task needs a function") end

  local o = {
    co = coroutine.create(func),
    calls = 0,
    data = {}
  }

  setmetatable(o, self)
  return o
end

--- Resumes the task.
-- @param ... Coroutine arguments. Should be a reference to the task.
function Task:resume(...)
  if coroutine.status(self.co) == "dead" then
    self.finished = true; return;
  end
  self.calls = self.calls + 1
  local passed, ret = coroutine.resume(self.co, ...)
  if not passed then error(ret) end
  return ret
end

--- Continues the task.
-- The task object is passed to the function.
-- @see Task:resume
function Task:update()
  self:resume(self)
end
