require "/scripts/set.lua"

local positionLocker = include("/scripts/wedit/helpers/positionLocker.lua").instance
local taskManager = include("/scripts/wedit/helpers/taskManager.lua").instance
local Config = include("/scripts/wedit/helpers/config.lua")

-- Module
local ModHelper = {}
module = ModHelper

function ModHelper.place(pos, layer, mod)
  if mod then
    world.placeMod(pos, layer, mod, nil, false)
  elseif mod == false then
    ModHelper.remove(pos, layer)
  end
end

function ModHelper.remove(pos, layer)
  local mod = world.mod(pos, layer)
  if not mod then return end
  local mat = world.material(pos, layer)

  if not ModHelper.breakMods[mod] then
    world.damageTiles({pos}, layer, pos, "blockish", 0, 0)
    return
  end

  if positionLocker:lock(layer, pos) then
    taskManager:startNew(function()
      world.placeMod(pos, layer, "grass", nil, false)
      util.waitFor(function() return world.mod(pos, layer) == "grass" end)
      world.damageTiles({pos}, layer, pos, "blockish", 0, 0)
      positionLocker:unlock(layer, pos)
    end)
  end
end

-- #region Area

function ModHelper.fill(shape, layer, mod)
  for p in shape:each() do
    ModHelper.place(p, layer, mod)
  end
end

function ModHelper.clear(shape, layer)
  for p in shape:each() do
    ModHelper.remove(p, layer)
  end
end

-- #endregion

hook("init", function()
  ModHelper.breakMods = set.new(Config.fromFile("/scripts/wedit/wedit.config", true).data.breakMods)
end)