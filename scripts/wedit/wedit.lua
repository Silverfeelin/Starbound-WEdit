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

require "/scripts/wedit/utilExt.lua"
require "/scripts/wedit/debugRenderer.lua"
require "/scripts/wedit/logger.lua"
require "/scripts/wedit/positionLocker.lua"
require "/scripts/wedit/taskManager.lua"
require "/scripts/wedit/ssmManager.lua"

--- WEdit table, variables and functions accessed with 'wedit.' are stored here.
-- Configuration values should be accessed with 'wedit.getUserConfigData(key'.
-- Variables in wedit.user are prioritized over wedit.default.
if not wedit then
  wedit = {}
end

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
  wedit.debugRenderer = DebugRenderer.new()
  wedit.logger = Logger.new("WEdit: ", "^cyan;WEdit ")
  wedit.taskManager = TaskManager.new()
  wedit.ssmManager = SSMManager:new()

  wedit.colorLevel = { orange = 1, yellow = 2, red = 3}

  wedit.liquidNames = {}
end

function wedit.update(...)
  wedit.taskManager:update()
  wedit.ssmManager:update()

  wedit.logger:setLogMap("Tasks", string.format("(%s) running.", wedit.ssmManager:count()))
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

--- Recolors the info text to use a color scheme.
-- @param str A string of text.
-- @return String with the recolors applied.
-- @see wedit.colors
function wedit.colorText(str)
  if not wedit.colors then return str;
  else
    return str:gsub("%^(.-);",function(code)
      return wedit.controller.colors[wedit.colorLevel[code]]
    end)
  end
end

---  Draws debug text below the user's character, or with an offset relative to it.
-- @param str Text to draw.
-- @param[opt={0,0}] offset {x,y} Offset relative to the feet of the player's character.
function wedit.info(str, offset)
  if type(offset) == "nil" then offset = {0,0} end
  if wedit.getUserConfigData("lineSpacing") and wedit.getUserConfigData("lineSpacing") ~= 1 then offset[2] = offset[2] * wedit.getUserConfigData("lineSpacing") end
  wedit.debugRenderer:drawText(wedit.colorText(str), {mcontroller.position()[1] + offset[1], mcontroller.position()[2] - 3 + offset[2]})
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

--- Starbound Block Class.
-- Identifiable with tostring(obj).
wedit.Block = {}
wedit.Block.__index = wedit.Block
wedit.Block.__tostring = function() return "starboundBlock" end

--- Creates and returns a block object.
-- The block values (i.e. material) are copied when the object is created.
-- Further changes to the block in the world don't modify the instantiated Block.
-- @param position - Original position of the block.
-- @param offset - Offset from the bottom left corner of the copied area.
function wedit.Block.create(position, offset)
  if not position then error("WEdit: Attempted to create a Block object for a block without a valid original position.") end
  if not offset then error(string.format("WEdit: Attempted to create a Block object for a block at (%s, %s) without a valid offset.", position[1], position[2])) end

  local block = {
    position = position,
    offset = offset
  }

  setmetatable(block, wedit.Block)

  block.foreground = {
    material = block:getMaterial("foreground"),
    mod = block:getMod("foreground"),
  }
  if block.foreground.material then
    block.foreground.materialColor = block:getMaterialColor("foreground")
    block.foreground.materialHueshift = block:getMaterialHueshift("foreground")
  end

  block.background = {
    material = block:getMaterial("background"),
    mod = block:getMod("background")
  }
  if block.background.material then
    block.background.materialColor = block:getMaterialColor("background")
    block.background.materialHueshift = block:getMaterialHueshift("background")
  end

  block.liquid = block:getLiquid()

  return block
end

--- Returns the material name of this block, if any.
-- @param layer "foreground" or "background".
-- @return Material name in the given layer.
function wedit.Block:getMaterial(layer)
  return world.material(self.position, layer)
end

--- Returns the matmod name of this block, if any.
-- @param layer "foreground" or "background".
-- @return Matmod name in the given layer.
function wedit.Block:getMod(layer)
  return world.mod(self.position, layer)
end

function wedit.Block:getMaterialColor(layer)
  local color = world.materialColor(self.position, layer)
  return color ~= 0 and color
end

--- Returns the hueshift of this block.
-- If the material doesn't exist, this will still return 0.
-- @param layer "foreground" or "background".
-- @return Material hueshift.
function wedit.Block:getMaterialHueshift(layer)
  return world.materialHueShift(self.position, layer)
end

--- Returns the liquid datas of this block, if any.
-- @return Nil or liquid data: {liquidID, liquidAmnt}.
function wedit.Block:getLiquid()
  return world.liquidAt(self.position)
end

--- Starbound Object Class. Contains data of a placeable object.
-- Identifiable with tostring(obj).
wedit.Object = {}
wedit.Object.__index = wedit.Object
wedit.Object.__tostring = function() return "starboundObject" end

--- Creates and returns a Starbound object.. object.
-- The object values (i.e. parameters) are copied when the object is created.
-- Further changes to the object in the world won't change this Object.
-- @param id Entity id of the source object.
-- @param offset Offset from the bottom left corner of the copied area.
-- @return Starbound Object data. Contains id, offset, name, parameters, [items].
function wedit.Object.create(id, offset, name)
  if not id then error("WEdit: Attempted to create a Starbound Object object without a valid entity id") end
  if not offset then error(string.format("WEdit: Attempted to create a Starbound Object for (%s) without a valid offset", id)) end

  local object = {
    id = id,
    offset = offset
  }

  setmetatable(object, wedit.Object)

  object.name = name or object:getName()
  object.parameters = parameters or object:getParameters()
  object.items = object:getItems(true)

  return object
end

--- Returns the identifier of the object.
-- @return Object name.
function wedit.Object:getName()
  return world.entityName(self.id)
end

--- Returns the full parameters of the object.
-- @return Object parameters.
function wedit.Object:getParameters()
  return world.getObjectParameter(self.id, "", nil)
end

--- Returns the items of the container object, or nil if the object isn't a container.
-- @param clearTreasure If true, sets the treasurePools parameter to nil, to avoid random loot after breaking the object.
-- @return Contained items, or nil.
function wedit.Object:getItems(clearTreasure)
  if clearTreasure then
    self.parameters.treasurePools = nil
  end

  if self.parameters.objectType == "container" then
    return world.containerItems(self.id)
  else
    return nil
  end
end

--- Starts a task that fills an area with blocks.
-- Existing blocks are not replaced.
-- @param bottomLeft Bottom left corner of the area.
-- @param topRight Top right corner of the area.
-- @param layer foreground or background.
-- @param block to fill the area with. Only
-- @return Copy of the area before the task starts.
function wedit.fillBlocks(bottomLeft, topRight, layer, block)
  bottomLeft = wedit.clonePoint(bottomLeft)
  topRight = wedit.clonePoint(topRight)

  if not block or block == "air" then return wedit.breakBlocks(bottomLeft, topRight, layer) end

  local width = topRight[1] - bottomLeft[1]
  local height = topRight[2] - bottomLeft[2]

  if width < 0 or height < 0 then error(string.format("WEdit: Attempted to fill an area smaller than 0 blocks: (%s, %s) > (%s, %s).", bottomLeft[1], bottomLeft[2], topRight[1], topRight[2])) end

  local copyOptions = {
    ["foreground"] = false,
    ["foregroundMods"] = false,
    ["background"] = false,
    ["backgroundMods"] = false,
    ["liquids"] = true,
    ["objects"] = false,
    ["containerLoot"] = false
  }
  copyOptions[layer] = true

  local copy = wedit.copy(bottomLeft, topRight, copyOptions)

  wedit.ssmManager:startNew(function()
    local iterations = wedit.calculateIterations(bottomLeft, {width, height}, layer)
    for i=1, iterations do
      -- Clear blocks
      wedit.forEach(bottomLeft, topRight, function(pos)
        world.placeMaterial(pos, layer, block, 0, true)
      end)

      -- Wait
      util.waitTicks(wedit.getUserConfigData("delay"), function()
        wedit.debugRenderer:drawRectangle(bottomLeft, topRight, "orange")
        world.debugText(string.format("^shadow;WEdit Fill (%s-%s) %s/%s", layer, block, i, iterations), {bottomLeft[1], topRight[2] - 1}, "orange")
      end)
    end
  end)

  wedit.logger:setLogMap("Fill", string.format("Task started with %s!", block))

  return copy
end

--- Breaks all blocks in in area.
-- @param bottomLeft Bottom left corner of the area.
-- @param topRight Top right corner of the area.
-- @param layer foreground or background.
function wedit.breakBlocks(bottomLeft, topRight, layer)
  bottomLeft = wedit.clonePoint(bottomLeft)
  topRight = wedit.clonePoint(topRight)

  local width = topRight[1] - bottomLeft[1]
  local height = topRight[2] - bottomLeft[2]

  if width < 0 or height < 0 then error(string.format("WEdit: Attempted to break an area smaller than 0 blocks: (%s, %s) > (%s, %s).", bottomLeft[1], bottomLeft[2], topRight[1], topRight[2])) end

  local copyOptions = {
    ["foreground"] = false,
    ["foregroundMods"] = false,
    ["background"] = false,
    ["backgroundMods"] = false,
    ["liquids"] = false,
    ["objects"] = false,
    ["containerLoot"] = false
  }
  copyOptions[layer] = true
  copyOptions[layer .. "Mods"] = true

  local copy = wedit.copy(bottomLeft, topRight, copyOptions)

  wedit.forEach(bottomLeft, topRight, function(pos)
    world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
  end)

  wedit.logger:setLogMap("Break", "Task executed!")

  return copy
end

--- Draws a block. If there is already a block, replace it.
-- Only replaces blocks if the block or hueshift is different.
-- @param pos World position to place the block at.
-- @param layer foreground or background
-- @param block Material name.
-- @param[opt=wedit.neighborHueshift] hueshift Hueshift for the block. Determined by nearest blocks if omitted.
function wedit.pencil(pos, layer, block, hueshift)
  -- Prevent needless tasks.
  local old = world.material(pos, layer)
  if (not old and not block) then return end
  if old == block and (type(hueshift) == "nil" or world.materialHueShift(pos, layer) == hueshift) then return end

  -- Prevent multiple tasks.
  if not wedit.positionLocker:lock(layer, pos) then return end

  -- Attempt to clone hueshift of neighbouring tiles.
  if not hueshift then
    hueshift = wedit.neighborHueshift(pos, layer, block) or 0
  end

  -- Start (re)placing
  wedit.ssmManager:startNew(function()
    local mod = world.mod(pos, layer)

    -- Remove old block
    if not block or old then
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
    wedit.positionLocker:unlock(layer, pos)
  end)

  wedit.logger:setLogMap("Pencil", string.format("Drawn %s.", block))
end

--- Gets the hueshift of a neighbouring same block.
-- Checks adjacent blocks above, to the left, right, below, behind or in front of the given block.
-- If the block matches the given block (or block at the position and layer), return the hueshift of the block.
-- This can be used by tools such as the pencil, to fill in terrain that uses the natural world block colors.
-- @param pos Block position.
-- @param layer "foreground" or "background".
-- @param[opt] Material name. If omitted, uses the block at pos in layer.
-- @return Hueshift of same neighboring block, or 0.
function wedit.neighborHueshift(pos, layer, block)
  if type(block) == "nil" then block = world.material(pos, layer) end
  if not block then return 0 end -- air

  local positions = {
    {pos[1], pos[2] - 1},
    {pos[1] - 1, pos[2]},
    {pos[1] + 1, pos[2]},
    {pos[1], pos[2] + 1}
  }

  -- Adjacent
  for _,position in ipairs(positions) do
    if world.material(position, layer) == block then
      return world.materialHueShift(position, layer)
    end
  end

  -- Opposite layer
  local oLayer = layer == "foreground" and "background" or "foreground"
  if world.material(pos, oLayer) == block then
    return world.materialHueShift(pos, oLayer)
  end

  return 0
end

--- Paints a block.
-- @param pos World position of the block to paint.
-- @param layer foreground or background
-- @param[opt=0] colorIndex Index of the paint color. 0 to remove the color.
-- Counting up from 0: none, red, blue, green, yellow, orange, pink, black, white.
function wedit.dye(pos, layer, colorIndex)
  world.setMaterialColor(pos, layer, colorIndex or 0)
end

--- Copies a selection.
-- @param bottomLeft Bottom left corner of the selection to copy.
-- @param topRight Top right corner of the selection to copy.
-- @param copyOptions Table containing options to copy. Missing keys will be
-- automatically determined. When pasting a copy, these options are also used.
--   foreground - Copies materials in the foreground layer.
--   background - ..
--   foregroundMods - Copies matmods in the foreground layer.
--   backgroundMods - ..
--   liquids - Copies liquids (block based, not density based).
--   objects - Copies objects with all parameters.
--   containerLoot - Copies items in copied containers.
--   materialColors - Copies painted material colors.
-- @param[opt=false] logMaterials If true, logs the materials found in the copy.
-- @see wedit.paste
function wedit.copy(bottomLeft, topRight, copyOptions, logMaterials)
  bottomLeft = wedit.clonePoint(bottomLeft)
  topRight = wedit.clonePoint(topRight)

  local width = topRight[1] - bottomLeft[1]
  local height = topRight[2] - bottomLeft[2]

  if width <= 0 or height <= 0 then
    sb.logInfo("WEdit: Failed to copy area at (%s, %s) sized %sx%s.", bottomLeft[1], bottomLeft[2], width, height)
    return
  end

  -- Default copy options
  if not copyOptions then
    copyOptions = {
      ["foreground"] = true,
      ["foregroundMods"] = true,
      ["background"] = true,
      ["backgroundMods"] = true,
      ["liquids"] = true,
      ["objects"] = true,
      ["containerLoot"] = true,
      ["materialColors"] = true -- Material color is always saved (see wedit.Block), but can be ignored when pasting.
    }
  end

  local copy = {
    options = copyOptions,
    origin = bottomLeft,
    size = {width, height},
    blocks = {},
    objects = {}
  }

  -- Table set containing objects in the selection.
  -- objectIds[id] = true
  local objectIds = {}

  local materialCount = {}
  local matmodCount = {}
  local liquidCount = {}

  local increaseCount = function(tbl, key)
    if not tbl or not key then return end
    if not tbl[key] then tbl[key] = 1 else tbl[key] = tbl[key] + 1 end
  end

  -- Iterate over every block
  for i=0,width-1 do
    copy.blocks[i+1] = {}

    for j=0,height-1 do
      -- Block coordinate
      local pos = {bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}

      -- Object check
      if copy.options.objects ~= false then
        local objects = world.objectQuery(pos, 1, {order="nearest"})
        if objects and objects[1] then
          objectIds[objects[1]] = true

          if copy.options.objects == nil then copy.options.objects = true end
        end
      end

      -- Block check
      local block = wedit.Block.create(pos, {i, j})
      copy.blocks[i+1][j+1] = block

      -- Count materials.
      if logMaterials then
        increaseCount(materialCount, block.foreground.material)
        increaseCount(materialCount, block.background.material)
        increaseCount(matmodCount, block.foreground.mod)
        increaseCount(matmodCount, block.background.mod)
        if block.liquid then
          local liqName = wedit.liquidName(block.liquid[1]) or "unknown"
          increaseCount(liquidCount, liqName)
        end
      end

      if copy.options.foreground == nil and block.foreground.material then copy.options.foreground = true end
      if copy.options.foregroundMods == nil and block.foreground.mod then copy.options.foregroundMods = true end
      if copy.options.background == nil and block.background.material then copy.options.background = true end
      if copy.options.backgroundMods == nil and block.background.mod then copy.options.backgroundMods = true end
      if copy.options.liquids == nil and block.liquid then copy.options.liquids = true end
      if copy.options.materialColors == nil and block.foreground.materialColor or block.background.materialColor then copy.options.materialColors = true end
    end
  end

  if copy.options.objects == nil and #objectIds > 0 then copy.options.objects = true end

  local objectCount = {}
  -- Iterate over every found object
  for id,_ in pairs(objectIds) do
    local offset = world.entityPosition(id)
    offset = {
      offset[1] - bottomLeft[1],
      offset[2] - bottomLeft[2]
    }

    local object = wedit.Object.create(id, offset)

    -- Count objects.
    if logMaterials then
      increaseCount(objectCount, object.name)
    end

    -- Set undefined containerLoot option to true if containers with items have been found.
    if copy.options.containerLoot == nil and object.items then copy.options.containerLoot = true end

    table.insert(copy.objects, object)
  end

  if logMaterials then
    -- Logging materials found in the copy.
    local sLog = "WEdit: A new copy has been made. Copy details:\nBlocks: %s\nMatMods: %s\nObjects: %s\nLiquids: %s"
    local formatString = function(list)
      local s = ""
      for i,v in pairs(list) do
        s = s .. i .. " x" .. v .. ", "
      end
      if s ~= "" then s = s:sub(1, -3) .. "." end
      return s
    end

    local sMaterials = formatString(materialCount)
    local sObjects = formatString(objectCount)
    local sMatmods = formatString(matmodCount)
    local sLiquids = formatString(liquidCount)

    sb.logInfo(sLog, sMaterials, sMatmods, sObjects, sLiquids)
  end
  return copy
end

--- Starts a task that pastes a selection.
-- @copy Copy to paste. The copy options are used for the paste.
-- @param position Bottom left corner of the paste.
function wedit.paste(copy, position)
  if not copy then return end

  position = vec2.floor(position)
  local topRight = { position[1] + copy.size[1], position[2] + copy.size[2] }

  local paste = {
    copy = copy,
    placeholders = {}
  }

  local backup = wedit.copy(position, {position[1] + copy.size[1], position[2] + copy.size[2]})

  local stages = {}
  local debug = function(msg)
    wedit.debugRenderer:drawRectangle(position, topRight, "orange")
    wedit.debugRenderer:drawText(msg, {position[1], topRight[2]-1}, "orange")
  end

  -- Break background
  if copy.options.background then
    table.insert(stages, function()
      for i=1,3 do
        wedit.breakBlocks(position, topRight, "background")
        wedit.wait(function() debug(string.format("^shadow;Breaking background blocks (%s/%s).", i, 3)) end)
      end
    end)
  end

  local iterations = wedit.calculateIterations(position, copy.size)

  -- Place background
  if copy.options.background or copy.options.foreground then
    table.insert(stages, function(ssm)
      local it = iterations
      ssm.data.it = 0
      while it > 0 do
        ssm.data.it = ssm.data.it + 1
        it = it - 1
        local lessIterations = wedit.calculateIterations(position, copy.size, "foreground")

        if lessIterations < it then it = lessIterations end

        for i=0, copy.size[1]-1 do
          for j=0, copy.size[2]-1 do
            local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}
            -- Check if there's a background block here
            local block = copy.blocks[i+1][j+1]
            if block and copy.options.background and block.background.material then
              -- Place the background block.
              world.placeMaterial(pos, "background", block.background.material, block.background.materialHueshift, true)
            else
              if copy.options.foreground then
                -- Add a placeholder that reminds us later to remove the dirt placed here temporarily.
                if not paste.placeholders[i+1] then paste.placeholders[i+1] = {} end
                if not world.material(pos, "background") then
                  paste.placeholders[i+1][j+1] = true

                  world.placeMaterial(pos, "background", "hazard", 0, true)
                end
              end
            end
          end
        end

        wedit.wait(function() debug(string.format("^shadow;Placing background and placeholder blocks (%s/%s).", ssm.data.it, ssm.data.it + it)) end)
      end
    end)
  end

  if copy.options.foreground then
    -- Break foreground
    table.insert(stages, function(ssm)
      for i=1,3 do
        wedit.breakBlocks(position, topRight, "foreground")
        wedit.wait(function() debug(string.format("^shadow;Breaking foreground blocks (%s/%s).", i, 3)) end)
      end
    end)

    -- Place foreground
    table.insert(stages, function(ssm)
      for i=0, copy.size[1]-1 do
        for j=0, copy.size[2]-1 do
          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}

          -- Check if there's a background block here
          local block = copy.blocks[i+1][j+1]
          if block and block.foreground.material then
            -- Place the background block.
            world.placeMaterial(pos, "foreground", block.foreground.material, block.foreground.materialHueshift, true)
          end
        end
      end

      wedit.wait(function() debug("^shadow;Placing foreground blocks.") end)
    end)
  end

  -- #region Stage 5: If copy has liquids, place them.
  if copy.options.liquids then
    table.insert(stages, function()
      for i=0,copy.size[1]-1 do
        for j=0,copy.size[2]-1 do

          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}

          local block = copy.blocks[i+1][j+1]
          if block and block.liquid then
            world.spawnLiquid(pos, block.liquid[1], block.liquid[2])
          end
        end
      end

      wedit.wait(function() debug("^shadow;Placing liquids.") end)
    end)
  end
  -- #endregion

  -- #region Stage 6: If paste has foreground, and thus may need placeholders, remove the placeholders.
  if copy.options.foreground then
    table.insert(stages, function()
      for i,v in pairs(paste.placeholders) do
        for j,k in pairs(v) do
          local pos = {position[1] - 0.5 + i, position[2] - 0.5 + j}
          world.damageTiles({pos}, "background", pos, "blockish", 9999, 0)
        end
      end

      wedit.wait(function() debug("^shadow;Removing placeholder blocks.") end)
    end)
  end
  -- #endregion

  if copy.options.objects and #copy.objects > 0 then
    local hasItems = false

    -- #region Stage 7: If copy has objects, place them.
    table.insert(stages, function()
      local centerOffset = copy.size[1] / 2
      for _,v in pairs(copy.objects) do
        local dir = v.parameters and v.parameters.direction == "left" and -1 or
          v.parameters and v.parameters.direction == "right" and 1 or
          v.offset[1] < centerOffset and 1 or -1

        -- Create unique ID
        local tempId = nil
        if v.parameters and v.parameters.uniqueId then
          tempId, v.parameters.uniqueId = v.parameters.uniqueId, sb.makeUuid()
        end
        world.placeObject(v.name, {position[1] + v.offset[1], position[2] + v.offset[2]}, dir, v.parameters)

        -- Restore unique ID of original object.
        if tempId then v.parameters.uniqueId = tempId end

        if v.items ~= nil then hasItems = true end
      end

      wedit.wait(function() debug("^shadow;Placing objects.") end)
    end)
    -- #endregion

    -- #region Stage 8: If copy has containers, place items in them.
    if copy.options.containerLoot and hasItems then
      table.insert(stages, function()
        for i,v in pairs(copy.objects) do
          if v.items then
            local ids = world.objectQuery({position[1] + v.offset[1], position[2] + v.offset[2]}, 1, {order="nearest"})
            if ids and ids[1] then
              for j,k in ipairs(v.items) do
                world.containerAddItems(ids[1], k)
              end
            end
          end
        end

        wedit.wait(function() debug("^shadow;Placing items in containers.") end)
      end)
    end
    -- #endregion
  end

  -- #region Stage 9: If copy has matmods, place them
  if copy.options.foregroundMods or copy.options.backgroundMods then
    table.insert(stages, function()
      for i=0, copy.size[1]-1 do
        for j=0, copy.size[2]-1 do
          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}
          local block = copy.blocks[i+1][j+1]

          if copy.options.foregroundMods and block.foreground.mod then
            world.placeMod(pos, "foreground", block.foreground.mod, nil, false)
          end

          if copy.options.backgroundMods and block.background.mod then
            world.placeMod(pos, "background", block.background.mod, nil, false)
          end
        end
      end

      wedit.wait(function() debug("^shadow;Placing material mods.") end)
    end)
  end
  -- #endregion

  -- #region Stage 10: If copy has material colors, paint.
  if copy.options.materialColors then
    table.insert(stages, function()
      for i=0,copy.size[1]-1 do
        for j=0,copy.size[2]-1 do
          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}
          local block = copy.blocks[i+1][j+1]

          if block.foreground.materialColor then
            wedit.dye(pos, "foreground", block.foreground.materialColor)
          end
          if block.background.materialColor then
            wedit.dye(pos, "background", block.background.materialColor)
          end
        end
      end

      wedit.wait(function() debug("^shadow;Dyeing tiles.") end)
    end)
  end
  -- #endregion

  -- #region Stage 11: Done
  table.insert(stages, function()
    wedit.wait(function() debug("^shadow;Done pasting!") end)
  end)
  -- #endregion

  -- Create paste task, and start it.
  wedit.ssmManager:startNew(stages)

  wedit.logger:setLogMap("Paste", string.format("Beginning new paste at (%s,%s)", position[1], position[2]))

  return backup
end

--- Flips a copy horizontally or vertically.
-- Does not work well on objects when flipping vertically.
-- @param copy Copy to flip. Materials, mods, liquids and objects are flipped.
-- @param direction horizontal or vertical.
-- @return Copy. Note: Same as first parameter. The object is directly modified.
function wedit.flip(copy, direction)
  direction = direction:lower()

  if direction == "horizontal" then
    return wedit.flipHorizontal(copy)
  elseif direction == "vertical" then
    return wedit.flipVertical(copy)
  else
    wedit.logger:logWarn("Could not flip copy in direction '" .. direction .. "'.")
  end

  return copy
end

--- Flips a copy horizontally.
-- @param copy Copy to flip. Materials, mods, liquids and objects are flipped.
-- @return Copy. Note: Same as first parameter. The object is directly modified.
function wedit.flipHorizontal(copy)
  -- Flip blocks
  for i=1, math.floor(#copy.blocks / 2) do
    for j,v in ipairs(copy.blocks[i]) do
      v.offset[1] = copy.size[1] - i
    end
    for j,v in ipairs(copy.blocks[#copy.blocks - i + 1]) do
      v.offset[1] = i - 1
    end
    copy.blocks[i], copy.blocks[#copy.blocks - i + 1] = copy.blocks[#copy.blocks - i + 1], copy.blocks[i]
  end

  -- Flip objects
  for i,v in ipairs(copy.objects) do
    v.offset[1] = copy.size[1] - v.offset[1]
    if v.parameters and v.parameters.direction then
      v.parameters.direction = v.parameters.direction == "right" and "left" or "right"
    end
  end

  -- Mark flipped
  copy.flipX = not copy.flipX
  return copy
end

--- Flips a copy vertically.
-- Does not work well with objects.
-- @param copy Copy to flip. Materials, mods, liquids and objects are flipped.
-- @return Copy. Note: Same as first parameter. The object is directly modified.
function wedit.flipVertical(copy)
  -- Flip blocks
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

  -- Flip objects
  for i,v in ipairs(copy.objects) do
    v.offset[2] = copy.size[2] - v.offset[2]
  end

  -- Mark flipped
  copy.flipY = not copy.flipY

  return copy
end

--- Replaces blocks in a selection.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
-- @param toBlock New block to place.
-- @param[opt=nil] fromBlock Block to replace. If nil, replaces all blocks.
function wedit.replace(bottomLeft, topRight, layer, toBlock, fromBlock)
  bottomLeft = wedit.clonePoint(bottomLeft)
  topRight = wedit.clonePoint(topRight)

  local copyOptions = {
    ["foreground"] = true,
    ["foregroundMods"] = true,
    ["background"] = true,
    ["backgroundMods"] = true,
    ["liquids"] = false,
    ["objects"] = false,
    ["containerLoot"] = false
  }

  local copy = wedit.copy(bottomLeft, topRight, copyOptions)

  bottomLeft = wedit.clonePoint(bottomLeft)
  topRight = wedit.clonePoint(topRight)

  local size = {topRight[1] - bottomLeft[1], topRight[2] - bottomLeft[2]}
  local oppositeLayer = layer == "foreground" and "background" or "foreground"

  local placeholders = {}
  local replacing = {}

  wedit.ssmManager:startNew(
    -- Placeholders
    toBlock and function()
      local predicatePos
      wedit.forEach(bottomLeft, topRight, function(pos)
        if world.material(pos, layer) and not world.material(pos, oppositeLayer) then
          predicatePos = pos
          table.insert(placeholders, pos)
          world.placeMaterial(pos, oppositeLayer, "hazard", 0, true)
        end
      end)
      if predicatePos then util.waitFor(function() return world.material(predicatePos, oppositeLayer) end) end
    end,
    -- Break matching
    function()
      local predicatePos
      wedit.forEach(bottomLeft, topRight, function(pos)
        local block = world.material(pos, layer)
        if block and (not fromBlock or (block and block == fromBlock)) then
          predicatePos = pos
          table.insert(replacing, pos)
          world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
        end
      end)
      if predicatePos then util.waitFor(function() return not world.material(predicatePos, layer) end) end
    end,
    -- Place new
    toBlock and function()
      local predicatePos
      for _,pos in ipairs(replacing) do
        predicatePos = pos
        world.placeMaterial(pos, layer, toBlock, 0, true)
      end
      if predicatePos then util.waitFor(function() return world.material(predicatePos, layer) end) end
    end,
    -- Remove placeholders
    function()
      for _,pos in ipairs(placeholders) do
        world.damageTiles({pos}, oppositeLayer, pos, "blockish", 9999, 0)
      end
    end
  )

  wedit.logger:setLogMap("Replace", "Command started!")

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
  wedit.forEach(bottomLeft, topRight, function(pos)
    world.destroyLiquid(pos)
  end)
end

--- Fills a selection with a liquid.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
-- @param liquidId ID of the liquid.
function wedit.hydrate(bottomLeft, topRight, liquidId)
  wedit.forEach(bottomLeft, topRight, function(pos)
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
  local times = {0,0,0,0}

  wedit.ssmManager:startNew(
    -- Place block
    function()
      world.placeMaterial(pos, "foreground", "hazard")
      util.waitFor(function()
        times[1] = times[1] + 1
        return world.material(pos, "foreground")
      end)
    end,
    -- Place mod
    function()
      world.placeMod(pos, "foreground", "coal")
      util.waitFor(function()
        times[2] = times[2] + 1
        return world.mod(pos, "foreground")
      end)
    end,
    -- Break mod
    function()
      world.damageTiles({pos}, "foreground", pos, "blockish", 9999, 0)
      util.waitFor(function()
        times[3] = times[3] + 1
        return not world.mod(pos, "foreground")
      end)
    end,
    -- Break block
    function()
      world.damageTiles({pos}, "foreground", pos, "blockish", 9999, 0)
      util.waitFor(function()
        times[4] = times[4] + 1
        return not world.material(pos, "foreground")
      end)
    end,
    -- Finalize
    function()
      local delay = 1
      for _,v in ipairs(times) do
        if v > delay then delay = v end
      end

      wedit.controller.setUserConfig("delay", delay + 1)
      world.sendEntityMessage(entity.id(), "wedit.updateConfig")
    end
  )
end

--- For each block in a line between two points, calls the callback function.
-- This uses the bresenham algorithm implementation by kikito.
-- Licensed under the MIT license: https://github.com/kikito/bresenham.lua/blob/master/MIT-LICENSE.txt.
-- @param startPos First position of the line.
-- @param endPos Second position of the line.
-- @param callback Function called for each block with parameters (x, y).
function wedit.bresenham(startPos, endPos, callback)
  local x0, y0, x1, y1 = startPos[1], startPos[2], endPos[1], endPos[2]
  local sx,sy,dx,dy

  if x0 < x1 then
    sx = 1
    dx = x1 - x0
  else
    sx = -1
    dx = x0 - x1
  end

  if y0 < y1 then
    sy = 1
    dy = y1 - y0
  else
    sy = -1
    dy = y0 - y1
  end

  local err, e2 = dx-dy, nil

  callback(x0, y0)

  while not(x0 == x1 and y0 == y1) do
    e2 = err + err
    if e2 > -dy then
      err = err - dy
      x0  = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0  = y0 + sy
    end

    callback(x0, y0)

  end
end

--- Places a block at every position on a line between two points.
-- @param startPos First position of the line.
-- @param endPos Second position of the line.
-- @param layer foreground or background
-- @param block Material name. If "air" or "none", breaks blocks instead.
-- @see wedit.bresenham
function wedit.line(startPos, endPos, layer, block)
  if block ~= "air" and block ~= "none" then
    wedit.bresenham(startPos, endPos, function(x, y) world.placeMaterial({x, y}, layer, block, 0, true) end)
  else
    wedit.bresenham(startPos, endPos, function(x, y) world.damageTiles({{x,y}}, layer, {x,y}, "blockish", 9999, 0) end)
  end
end


--- For each block between bottomLeft and topRight, calls callback.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
-- @param callback Function called with {x,y} for every block.
function wedit.forEach(bottomLeft, topRight, callback)
  local bl, tr = vec2.floor(bottomLeft), vec2.floor(topRight)

  for i=0, math.ceil(tr[1] - bl[1]) - 1 do
    for j=0, math.ceil(tr[2] - bl[2]) - 1 do
      callback({bl[1] + i, bl[2] + j})
    end
  end
end

--- For each block in a rectangle around a center position, calls the callback function.
-- @param pos World center of the rectangle.
-- @param width Rectangle width.
-- @param height Rectangle height.
-- @param callback function called for each block with parameter {x, y}.
function wedit.rectangle(pos, width, height, callback)
  height = height or width
  local blocks = {}
  local left, bottom  = (width - 1) / 2, (height - 1) / 2
  for x=0,width-1 do
    for y=0, height-1 do
      local block = {pos[1] - left + x, pos[2] - bottom + y}
      table.insert(blocks, block)
      if callback then
        callback(block)
      end
    end
  end
  return blocks
end

-- For each block in a circle around a position and radius, calls the callback function.
-- @param pos World center of the circle.
-- @param[opt=1] radius Circle radius in blocks.
-- @param callback Function called for each block with parameter {x, y}.
function wedit.circle(pos, radius, callback)
  radius = radius and math.abs(radius) or 1
  local blocks = {}
  for y=-radius,radius do
    for x=-radius,radius do
      if (x*x)+(y*y) <= (radius*radius) then
        local block = {pos[1] + x, pos[2] + y}
        table.insert(blocks, block)
        callback(block)
      end
    end
  end
  return blocks
end

--- Returns the liquid name of a liquid id.
-- Caches previously called IDs.
-- @param liquidId ID of the liquid.
function wedit.liquidName(liquidId)
  if not wedit.liquidNames[liquidId] then
    local cfg = root.liquidConfig(liquidId)
    if cfg then
      wedit.liquidNames[liquidId] = cfg.config.name
    end
  end

  return wedit.liquidNames[liquidId]
end

--- util.waitTicks using the current iteration delay.
-- @param [cb] Function to call every tick while waiting. If the function returns true, cancels the waiting early.
function wedit.wait(cb)
  util.waitTicks(wedit.getUserConfigData("delay"), cb)
end
