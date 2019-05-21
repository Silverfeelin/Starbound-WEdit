--- WEdit library (https://github.com/Silverfeelin/Starbound-WEdit)
-- The brain of WEdit. This script won't function on it's own, but exposes the functions to a controller.
-- WEdit must be initialized with wedit.init() and updated every tick with wedit.update(args).
--
-- LICENSE
-- This file falls under an MIT License, which is part of this project.
-- An online copy can be viewed via the following link:
-- https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE
-- The bresemham function (wedit.bresenham) falls under a different license; refer to its documentation for licensing information.

require "/scripts/set.lua"
require "/scripts/vec2.lua"
require "/scripts/wedit/libs/utilExt.lua"
require "/scripts/wedit/libs/include.lua"

--- WEdit table, variables and functions accessed with 'wedit.' are stored here.
-- Configuration values should be accessed with 'wedit.getUserConfigData(key'.
-- Variables in wedit.user are prioritized over wedit.default.
_ENV.wedit = _ENV.wedit or {}

local Rectangle = include("/scripts/wedit/objects/shapes/rectangle.lua")
local Circle = include("/scripts/wedit/objects/shapes/circle.lua")

local Block = include("/scripts/wedit/objects/block.lua")
local Object = include("/scripts/wedit/objects/object.lua")

local Config = include("/scripts/wedit/helpers/config.lua")
local debugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua"):new()
local TaskManager = include("/scripts/wedit/helpers/taskManager.lua")
local Task = include("/scripts/wedit/objects/task.lua")
local PositionLocker = include("/scripts/wedit/helpers/positionLocker.lua")
local Logger = include("/scripts/wedit/helpers/logger.lua")

local shapes = include("/scripts/wedit/shapes.lua")
local stamp = include("/scripts/wedit/helpers/stamp.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")

local cfg = {}

function wedit.init()
  -- Load config
  cfg = root.assetJson("/scripts/wedit/wedit.config")

  wedit.default = wedit.getConfigData("defaultConfig")
  wedit.user = wedit.user or {}

  ---  Mods that require breaking the tile to remove them.
  -- These mods can still be removed by overwriting them with a mod such as grass
  -- before damaging the tile.
  wedit.breakMods = set.new(wedit.getConfigData("breakMods"))

  wedit.positionLocker = PositionLocker.new()
  wedit.logger = Logger.new("WEdit: ", "^cyan;WEdit ")
  wedit.taskManager = TaskManager.instance

  wedit.liquidNames = {}
end

function wedit.update(...)
  wedit.taskManager:update()
  wedit.logger:setLogMap("Tasks", string.format("(%s) running.", wedit.taskManager:count()))
end

function wedit.getConfigData(key)
  return cfg[key]
end

function wedit.getUserConfigData(key)
  local v = wedit.user[key]
  if v == nil then v = wedit.default[key] end
  if v == nil then
    wedit.logger:logError("The configuration key '%s' does not exist!", k)
  end
  return v
end

---  Draws debug text below the user's character, or with an offset relative to it.
-- @param str Text to draw.
-- @param[opt={0,0}] offset {x,y} Offset relative to the feet of the player's character.
function wedit.info(str, offset)
  if type(offset) == "nil" then offset = {0,0} end
  if wedit.getUserConfigData("lineSpacing") and wedit.getUserConfigData("lineSpacing") ~= 1 then offset[2] = offset[2] * wedit.getUserConfigData("lineSpacing") end
  debugRenderer:drawText(str, {mcontroller.position()[1] + offset[1], mcontroller.position()[2] - 3 + offset[2]})
end

--- Returns a copy of the given {x,y} point.
-- Generally used to prevent having a bunch of references to the same points,
-- meaning tasks will have undesired effects when changing your selection mid-task.
-- @param point Point to clone.
-- @return Cloned point.
function wedit.clonePoint(point)
  return {point[1], point[2]}
end

--- Quick attempt to lessen the amount of iterations needed to complete tasks such as filling an area.
-- For each block, see if there's a foreground material. If there is, see how far it's away from the furthest edge.
-- If this number is smaller than than the current amount of iterations, less iterations are needed.
-- Problem: Since every block is compared to the furthest edge and not other blocks, this generally misses a lot of skippable iterations.
-- @param bottomLeft - {X, Y}, representing the bottom left corner of the rectangle.
-- @param size - {X, Y}, representing the dimensions of the rectangle.
-- @param layer - "foreground" or "background", representing the layer to calculate iterations needed to fill for.
--  Note: The algorithm will check the OPPOSITE layer for blocks, as it assumes the given layer will be emptied before filling.
function wedit.calculateIterations(bottomLeft, size, layer)
  local oppositeLayer = layer == "foreground" and "background" or "foreground"
  local maxIterations = size[1] > size[2] and size[1] or size[2]
  local iterations = maxIterations
  local airFound = false
  for i=0, size[1]-1 do
    for j=0, size[2]-1 do
      local mat = world.material({bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}, oppositeLayer)
      if mat then
        local hPercentage = i / size[1]
        local vPercentage = j / size[2]

        hPercentage = math.max(1 - hPercentage, hPercentage)
        vPercentage = math.max(1 - vPercentage, vPercentage)
        local maxPercentage = math.max(hPercentage,vPercentage)

        iterations = math.min(iterations, math.ceil(maxPercentage * maxIterations))
      else
        airFound = true
      end
    end
  end

  if iterations and wedit.getUserConfigData("doubleIterations") then iterations = iterations * 2 end
  return airFound and iterations or 1
end

--- Starts a task that fills an area with blocks.
-- Existing blocks are not replaced.
-- @param bottomLeft Bottom left corner of the area.
-- @param topRight Top right corner of the area.
-- @param layer foreground or background.
-- @param block to fill the area with. Only
-- @return Copy of the area before the task starts.
function wedit.fillBlocks(bottomLeft, topRight, layer, block)
  if not block or block == "air" then return wedit.breakBlocks(bottomLeft, topRight, layer) end

  local copyOptions = {
    foreground = false, foregroundMods = false,
    background = false, backgroundMods = false,
    liquids = true, objects = false, containerLoot = false
  }
  copyOptions[layer] = true

  local copy = stamp.copy(bottomLeft, topRight, copyOptions)

  local rect = Rectangle:create(bottomLeft, topRight)
  BlockHelper.fill(rect, layer, block)

  return copy
end

function wedit.breakBlocks(bottomLeft, topRight, layer)
  local copyOptions = {
    foreground = false, foregroundMods = false,
    background = false, backgroundMods = false,
    liquids = false, objects = false, containerLoot = false
  }
  copyOptions[layer] = true
  copyOptions[layer .. "Mods"] = true

  local copy = stamp.copy(bottomLeft, topRight, copyOptions)

  local rect = Rectangle:create(bottomLeft, topRight)
  BlockHelper.clear(rect, layer)

  return copy
end

--- Paints a block.
-- @param pos World position of the block to paint.
-- @param layer foreground or background
-- @param[opt=0] colorIndex Index of the paint color. 0 to remove the color.
-- Counting up from 0: none, red, blue, green, yellow, orange, pink, black, white.
function wedit.dye(pos, layer, colorIndex)
  world.setMaterialColor(pos, layer, colorIndex or 0)
end

--- Flips a copy horizontally or vertically.
-- Does not work well on objects when flipping vertically.
-- @param copy Copy to flip. Materials, mods, liquids and objects are flipped.
-- @param direction horizontal or vertical.
-- @return Copy. Note: Same as first parameter. The object is directly modified.
function wedit.flip(copy, direction)
  direction = direction:lower()

  if direction == "horizontal" then
    -- Flip blocks horizontally
    for i=1, math.floor(#copy.blocks / 2) do
      for j,v in ipairs(copy.blocks[i]) do
        v.offset[1] = copy.size[1] - i
      end
      for j,v in ipairs(copy.blocks[#copy.blocks - i + 1]) do
        v.offset[1] = i - 1
      end
      copy.blocks[i], copy.blocks[#copy.blocks - i + 1] = copy.blocks[#copy.blocks - i + 1], copy.blocks[i]
    end

    -- Flip objects horizontally
    for i,v in ipairs(copy.objects) do
      v.offset[1] = copy.size[1] - v.offset[1]
      if v.parameters and v.parameters.direction then
        v.parameters.direction = v.parameters.direction == "right" and "left" or "right"
      end
    end

    copy.flipX = not copy.flipX
  elseif direction == "vertical" then
    for _,w in ipairs(copy.blocks) do
      for i=1, math.floor(#w / 2) do
        for j,v in ipairs(w[i]) do
          v.offset[1] = copy.size[1] - i
        end
        for j,v in ipairs(w[#w- i + 1]) do
          v.offset[1] = i - 1
        end
        w[i], w[#w- i + 1] = w[#w - i + 1], w[i]
      end
    end

    for i,v in ipairs(copy.objects) do
      v.offset[2] = copy.size[2] - v.offset[2]
    end

    copy.flipY = not copy.flipY
  else
    wedit.logger:logInfo("Could not flip copy in direction '" .. direction .. "'.")
  end

  return copy
end

--- Applies a mod to the block.
-- Can overwrite existing mods.
-- @param pos World position of the block.
-- @param layer foreground or background.
-- @param mod Matmod to place.
function wedit.placeMod(pos, layer, mod)
  world.placeMod(pos, layer, mod, nil, false)
end

--- Removes a mod from a block.
-- If the block requires breaking to remove the mod, the mod is overwritten first.
-- @param pos World position of the mod.
-- @param layer foreground or background.
function wedit.removeMod(pos, layer)
  local mod = world.mod(pos, layer)
  local mat = world.material(pos, layer)
  if not mod or not mat then return end

  if not wedit.breakMods[mod] then
    world.damageTiles({pos}, layer, pos, "blockish", 0, 0)
  elseif wedit.positionLocker:lock(layer, pos) then
    wedit.taskManager:start(Task.new({function(task)
      world.placeMod(pos, layer, "grass", nil, false)
      task:nextStage()
    end, function(task)
      world.damageTiles({pos}, layer, pos, "blockish", 0, 0)
      wedit.positionLocker:unlock(layer, pos)
      task:complete()
    end}, wedit.getUserConfigData("delay")))
  end
end

--- Drain any liquid in a selection.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
function wedit.drain(bottomLeft, topRight)
  shapes.rectangle(bottomLeft, topRight, function(pos)
    world.destroyLiquid(pos)
  end)
end

--- Fills a selection with a liquid.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
-- @param liquidId ID of the liquid.
function wedit.hydrate(bottomLeft, topRight, liquidId)
  shapes.rectangle(bottomLeft, topRight, function(pos)
    world.spawnLiquid(pos, liquidId, 1)
  end)
end

--- Calculates an optimal 'delay'.
-- A block is placed, modified and broken a total of 5 times.
-- The time each step takes is used to determine the minimum delay WEdit can get away with.
-- @param pos Position to calibrate on. Should have a background but no foreground.
-- @param [maxTicks=60] Maximum delay. If calibration times out, this value is used.
function wedit.calibrate(pos, maxTicks)
  if world.tileIsOccupied(pos, true) or not world.material(pos, "background") then return end

  local attempts = maxTicks or 60 -- 1 sec.
  local times = {}

  local placeBlock = function(task)
    if task.stageProgress == 0 then
      world.placeMaterial(pos, "foreground", "hazard")
    end
    task.stageProgress = task.stageProgress + 1
    if world.material(pos, "foreground") or task.stageProgress > attempts then
      table.insert(times, task.stageProgress)
      task:nextStage()
    end
  end

  local placeMod = function(task)
    if task.stageProgress == 0 then
      world.placeMod(pos, "foreground", "coal")
    end
    task.stageProgress = task.stageProgress + 1
    if world.mod(pos, "foreground") or task.stageProgress > attempts then
      table.insert(times, task.stageProgress)
      task:nextStage()
    end
  end

  local breakMod = function(task)
    if task.stageProgress == 0 then
      world.damageTiles({pos}, "foreground", pos, "blockish", 9999, 0)
    end
    task.stageProgress = task.stageProgress + 1
    if not world.mod(pos, "foreground") or task.stageProgress > attempts then
      table.insert(times, task.stageProgress)
      task:nextStage()
    end
  end

  local breakBlock = function(task)
    if task.stageProgress == 0 then
      world.damageTiles({pos}, "foreground", pos, "blockish", 9999, 0)
    end
    task.stageProgress = task.stageProgress + 1
    if not world.material(pos, "foreground") or task.stageProgress > attempts then
      table.insert(times, task.stageProgress)
      task:nextStage()
    end
  end

  local finalize = function(task)
    local delay = 1
    for _,v in ipairs(times) do
      if v > delay then delay = v end
    end

    wedit.controller.setUserConfig("delay", delay + 1)
    task:complete()
  end

  local stages = {
    placeBlock, placeMod, breakMod, breakBlock,
    placeBlock, placeMod, breakMod, breakBlock,
    placeBlock, placeMod, breakMod, breakBlock,
    placeBlock, placeMod, breakMod, breakBlock,
    placeBlock, placeMod, breakMod, breakBlock,
    finalize
  }
  wedit.taskManager:start(Task.new(stages, 1))
end

--- Places a block at every position on a line between two points.
-- @param startPos First position of the line.
-- @param endPos Second position of the line.
-- @param layer foreground or background
-- @param block Material name. If "air" or "none", breaks blocks instead.
-- @see shapes.bresenham
function wedit.line(startPos, endPos, layer, block)
  if block ~= "air" and block ~= "none" then
    shapes.line(startPos, endPos, function(x, y) world.placeMaterial({x, y}, layer, block, 0, true) end)
  else
    shapes.line(startPos, endPos, function(x, y) world.damageTiles({{x,y}}, layer, {x,y}, "blockish", 9999, 0) end)
  end
end

function wedit.liquidName(liquidId)
  if not wedit.liquidNames[liquidId] then
    local cfg = root.liquidConfig(liquidId)
    if cfg then
      wedit.liquidNames[liquidId] = cfg.config.name
    end
  end

  return wedit.liquidNames[liquidId]
end
