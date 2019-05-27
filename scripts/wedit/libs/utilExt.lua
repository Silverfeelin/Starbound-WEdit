require "/scripts/util.lua"

--- util.wait, but in ticks (updates) rather than seconds.
-- @param ticks Amount of update ticks to wait.
-- @param [action] Function called every coroutine resume.
-- If the function returns a truthy value the wait ends early.
-- @returns True if the action returned truthy, false otherwise.
function util.waitTicks(ticks, action)
  ticks = ticks or 60
  local t = 0
  while t < ticks do
    if action ~= nil and action(dt) then return true end
    t = t + 1
    coroutine.yield(false)
  end
  return false
end

--- util.wait, but waits until predicate returns true.
-- @param predicate Function that determines if the delay should continue (by returning false).
-- @param [timeout=60] Maximum amount of calls.
-- @returns True if the predicate succeeded, false otherwise
function util.waitFor(predicate, timeout)
  timeout = timeout or 60

  local t = 0
  while t < timeout do
    if predicate() then return true end
    t = t + 1
    coroutine.yield(false)
  end
  return false
end
