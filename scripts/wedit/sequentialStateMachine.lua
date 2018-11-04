--- Sequential State Machine
-- A class for sequential coroutines.
-- .. or you could just use a single coroutine.
--
-- LICENSE
-- MIT License. https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

SSM = {}

--- Instantiates a new sequential state machine
-- @param ... States
function SSM:new(...)
  local args = {...}
  local states = {}
  for _,v in ipairs(args) do
    if type(v) == "table" then
      for _,f in ipairs(v) do table.insert(states, f) end
    elseif type(v) == "function" then
      table.insert(states, v)
    end
  end
  local c = #states

  -- Error checking
  if c == 0 then error("SSM must have at least one state") end
  for _,f in ipairs(states) do
    if type(f) ~= "function" then error("SSM only supports functions as states") end
  end

  local o = {
    states = states, -- States
    index = 0, -- State index
    calls = 0, -- Amount of times this state has been called
    count = c, -- Amount of states
    data = {} -- User data
  }

  setmetatable(o, { __index = self })
  return o
end

--- Resumes the current state.
-- If the state has finished, start the next state.
-- @param ... Coroutine arguments.
function SSM:resume(...)
  if not self.state or coroutine.status(self.state) == "dead" then
    self:nextState(...)
  end

  if self.state then
    self.calls = self.calls + 1
    local passed, ret = coroutine.resume(self.state, ...)
    if not passed then error(ret) end
    return ret
  end
end

--- Process to the next state.
-- If all states have finished, sets finished to true.
function SSM:nextState(...)
  self.index = self.index + 1
  self.state = self.states[self.index] -- Can be nil (no next state).
  self.calls = 0

  if self.state then
    self.state = coroutine.create(self.state, ...)
  else
    self.finished = true
  end
end

--- Continues the current state.
-- The state machine object is passed to the state function.
-- @see SSM:resume
function SSM:update()
  self:resume(self)
end
