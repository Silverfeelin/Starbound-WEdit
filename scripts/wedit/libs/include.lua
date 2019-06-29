--- Module loader
--
-- USING MODULES
-- Modules will load once and can be included multiple times.
-- local shapes = include("/scripts/shapes.lua")
--
-- CREATING MODULES
-- To write a module, export to _ENV.module.
-- module = myLibrary
-- module = myFunction

local modules = {}

local loaded = {}

local req = function(script)
  table.insert(loaded, script)

  local old, m
  old, _ENV.module = _ENV.module, nil
  require(script)
  m, _ENV.module = _ENV.module, old
  modules[script] = m
  return m
end

--- Loads a module
-- @param script Absolute path to script file
-- @param [global] If present, exposes the module under _ENV[global].
-- @returns exported module
function include(script, global)
  local m = _SBLOADED[script] and modules[script] or req(script)
  if global and not _ENV[global] then _ENV[global] = m end
  return m
end
