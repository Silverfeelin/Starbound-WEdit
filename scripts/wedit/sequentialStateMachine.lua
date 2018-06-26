--- A simple state machine class used for sequential states.
SSM = {}

--- Instantiates a new sequential state machine
-- @param ... States
function SSM:new(...)
  local args = {...}
  local states = {}
  for _,v in pairs(args) do
    if type(v) == "table" then
      for _,f in ipairs(v) do table.insert(states, f) end
    else
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
    states = states,
    index = 0,
    count = c
  }

  setmetatable(o, { __index = self })
  return o
end

function SSM:resume(...)
  if not self.state or coroutine.status(self.state) == "dead" then
    self:nextState(...)
  end

  if self.state then
    local passed, ret = coroutine.resume(self.state, ...)
    if not passed then error(ret) end
    return ret
  end
end

function SSM:nextState(...)
  self.index = self.index + 1
  self.state = self.states[self.index] -- Can be nil (no next state).
  if self.state then
    self.state = coroutine.create(self.state, ...)
  else
    self.finished = true
  end
end

function SSM:update()
  self:resume()
end
