--- UNLICENSED: FEEL FREE TO USE THIS CODE WITH OR WITHOUT THIS HEADER.
-- https://gist.github.com/Silverfeelin/3a6286d443d829eed58fa781790e2de5
-- Usage: hook("init", myTable.myInit)

-- Prevent loading if another scriptHooks has been loaded (i.e. same script in a different folder)
if hook then return end

local hooks = {}

--- Loops over all functions in hook.
-- Returns the first non-nil value after calling all hooks.
local function loop(hook, ...)
  local ret
  for k,v in pairs(hook) do
    if v then
      local r = k(...)
      if type(ret) == "nil" then ret = r end
    end
  end
  return ret
end

--- Creates a new empty hook for the given global function.
-- The return hook is a key-based table for functions to call.
local function createHook(name)
  if hooks[name] then return hooks[name] end
  local hook = {}
  hooks[name] = hook

  if _ENV[name] then
    local old = _ENV[name]
    _ENV[name] = function(...)
      old(...)
      return loop(hook, ...)
    end
  else
    _ENV[name] = function(...)
      return loop(hook, ...)
    end
  end

  return hook
end

--- Hook a function to the global function.
-- @param name Global function name.
-- @param func Function to hook.
function hook(name, func)
  local hook = createHook(name)
  hook[func] = true
end
