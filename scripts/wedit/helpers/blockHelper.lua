local HueshiftHelper = include("/scripts/wedit/helpers/hueshiftHelper.lua")
local positionLocker = include("/scripts/wedit/helpers/positionLocker.lua").instance
local taskManager = include("/scripts/wedit/helpers/taskManager.lua").instance

-- Module
local BlockHelper = {}
module = BlockHelper

--- Draws a block. If there is already a block, replace it.
-- @param pos World position to place the block at.
-- @param layer foreground or background
-- @param block Material name.
-- @param [hueshift=wedit.materialHueshift] Hueshift for the block. Determined by nearest blocks if omitted.
function BlockHelper.place(pos, layer, block, hueshift)
  -- Skip needless tasks.
  local old = world.material(pos, layer)
  if not old and not block then return end
  if old == block and (type(hueshift) == "nil" or world.materialHueShift(pos, layer) == hueshift) then return end

  -- Prevent multiple tasks
  if not positionLocker:lock(layer, pos) then return end

  hueshift = hueshift or HueshiftHelper.neighbor(pos, layer, block) or 0
  local mod = world.mod(pos, layer)

  return taskManager:startNew(function()
    -- Remove old block
    if not block or old then
      -- TODO: Force break (i.e. grass fails on one damage tick).
      world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
      util.waitFor(function() return not world.material(pos, layer) end)
    end

    -- Place new block
    if block then
      world.placeMaterial(pos, layer, block, hueshift, true)
      util.waitFor(function() return world.material(pos, layer) end)
    end

    -- Place mod
    if mod then
      world.placeMod(pos, layer, mod)
      util.waitFor(function() return world.mod(pos, layer) end)
    end

    -- Unlock block position.
    positionLocker:unlock(layer, pos)
  end)
end

function BlockHelper.remove(pos, layer)
  world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
end

-- #region Area

function BlockHelper.fill(shape, layer, block)
  for p in shape:each() do
    world.placeMaterial(p, layer, block, 0, true)
  end
end

function BlockHelper.replace(shape, layer, block, fromBlock)
  local tasks = {}
  for p in shape:each() do
    local mat = world.material(p, layer)

    -- Skip
    if not mat or mat == block then goto continue end
    if fromBlock and mat ~= fromBlock then goto continue end

    -- Replace
    local task = taskManager:startNew(function()
      BlockHelper.remove(p, layer)
      util.waitFor(function() return not world.material(p, layer) end)
      BlockHelper.place(p, layer, block)
    end)
    table.insert(tasks, task)

    ::continue::
  end
  return tasks
end

function BlockHelper.clear(shape, layer)
  -- TODO: Clear multiple times for matmods (& objects for foreground).
  for p in shape:each() do
    world.damageTiles({p}, layer, p, "blockish", 9999, 0)
  end
end

-- #endregion
