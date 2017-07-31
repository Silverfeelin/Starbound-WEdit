--[[
  WEdit library (http://silvermods.com/WEdit/)

  The bresemham function falls under a different license; refer to it's documentation for licensing information.
]]

--- WEdit table, variables and functions accessed with 'wedit.' are stored here.
-- Configuration values should be accessed with 'wedit.config.key'.
-- Variables in wedit.user are prioritized over wedit.default.
wedit = {
  default = {
    delay = 15,
    -- Tasks with a blank description aren't logged.
    description = "",
    -- Note: synchronization is not optimized; setting this value to true will cause critical issues.
    synchronized = false,
    doubleIterations = false,
    clearSchematics = false,
    iterationDelay = 15,
    lineSpacing = 1,
    pencilSize = 1,
    blockSize = 1,
    matmodSize = 1,
    brushShape = "square",
    noclipBind = "g",
    noclipSpeed = 0.75,
    updateConfig = false
  },
  user = {},
  config = {}
}

--- Set wedit.config to return the value found in wedit.user or in wedit.default.
setmetatable(wedit.config, {
  __index = function(_, k)
    if wedit.user[k] ~= nil then
      return wedit.user[k]
    elseif wedit.default[k] ~= nil then
      return wedit.default[k]
    end
    wedit.logError("The configuration key '%s' does not exist!", k)
  end
})

---  Mods that require breaking the tile to remove them.
-- These mods can still be removed by overwriting them with a mod such as grass
-- before damaging the tile.
wedit.breakMods = {
  aegisalt = true,
  coal = true,
  copper = true,
  corefragment = true,
  crystal = true,
  diamond = true,
  durasteel = true,
  erchius = true,
  ferozium = true,
  gold = true,
  iron = true,
  lead = true,
  metal = true,
  moonstone = true,
  platinum = true,
  plutonium = true,
  prisilite = true,
  silver = true,
  solarium = true,
  sulphur = true,
  titanium = true,
  trianglium = true,
  tungsten = true,
  uranium = true,
  violium = true
}

--- Available liquids.
-- Has to be updated when game updates add or remove options.
wedit.liquids = {
  [1] = { name = "water", id = 1 },
  [2] = { name = "lava", id = 2 },
  [3] = { name = "poison", id = 3 },
  [4] = { name = "tarliquid", id = 5 },
  [5] = { name = "healingliquid", id = 6 },
  [6] = { name = "milk", id = 7 },
  [7] = { name = "corelava", id = 8 },
  [8] = { name = "fuel", id = 11 },
  [9] = { name = "swampwater", id = 12 },
  [10] = { name = "slimeliquid", id = 13 },
  [11] = { name = "jellyliquid", id = 17 }
}

--- Access liquids by their liquid ID.
wedit.liquidsByID = {}
for i,v in ipairs(wedit.liquids) do
  wedit.liquidsByID[v.id] = v.name
end

--- Holds positions that are locked and shouldn't be modified.
-- Storage for positions that should be ignored by certain tools, such as the pencil.
-- This is to prevent multiple tasks from being created for the same tile.
-- Regular usage: wedit.lockedPositions[x .. "-" .. y .. layer] = true to lock and = nil to unlock.
wedit.lockedPositions = {}

--- Locks the block at the given position.
-- This prevents the usage of the wedit.pencil and wedit.removeMod on this block.
-- These tools take multiple frames to run, and this prevents multiple tasks for the same block.
-- @param pos {X, Y}, representing the position of the block to lock.
-- @param layer "foreground" or "background".
-- @return True if locking succeeded, false if it's already locked.
function wedit.lockPosition(pos, layer)
  layer = layer or "foreground"
  local p = math.floor(pos[1]) .. "-" .. math.floor(pos[2]) .. layer
  if wedit.lockedPositions[p] then
    return false
  else
    wedit.lockedPositions[p] = true
    return true
  end
end

--- Unlocks the block at the given position.
-- This allows the usage of the wedit.pencil and wedit.removeMod on this block.
-- @param pos {X, Y}, representing the position of the block to lock.
-- @param layer "foreground" or "background".
-- @return True if unlocking succeeded, false if it's already unlocked.
function wedit.unlockPosition(pos, layer)
  layer = layer or "foreground"
  local p = math.floor(pos[1]) .. "-" .. math.floor(pos[2]) .. layer
  if wedit.lockedPositions[p] then
    wedit.lockedPositions[p] = nil
    return true
  else
    return false
  end
end

--- Draws debug lines on the edges of the given rectangle.
-- @param bottomLeft {X1, Y1}, representing the bottom left corner of the rectangle.
-- @param topRight {X2, Y2}, representing the top right corner of the rectangle.
-- @param[opt="green"] color "color" or {r, g, b}, where r/g/b are values between 0 and 255.
function wedit.debugRectangle(bottomLeft, topRight, color)
  color = type(color) == "table" and color or type(color) == "string" and color or "green"

  world.debugLine({bottomLeft[1], topRight[2]}, {topRight[1], topRight[2]}, color) -- top edge
  world.debugLine(bottomLeft, {bottomLeft[1], topRight[2]}, color) -- left edge
  world.debugLine({topRight[1], bottomLeft[2]}, {topRight[1], topRight[2]}, color) -- right edge
  world.debugLine({bottomLeft[1], bottomLeft[2]}, {topRight[1], bottomLeft[2]}, color) -- bottom edge
end

--- Calls wedit.debugRectangle for the block at the given position.
-- @param pos Position of the block, can be a floating-point number.
-- @param[opt="green"] color "color" or {r, g, b}, where r/g/b are values between 0 and 255.
function wedit.debugBlock(pos, color)
  local bl, tr = {math.floor(pos[1]), math.floor(pos[2])}, {math.ceil(pos[1]), math.ceil(pos[2])}
  if bl[1] == tr[1] then tr[1] = tr[1] + 1 end
  if bl[2] == tr[2] then tr[2] = tr[2] + 1 end
  wedit.debugRectangle(bl, tr, color)
end

wedit.colorLevel = { orange = 1, yellow = 2, red = 3}
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
  if wedit.config.lineSpacing and wedit.config.lineSpacing ~= 1 then offset[2] = offset[2] * wedit.config.lineSpacing end
  wedit.debugText(wedit.colorText(str), {mcontroller.position()[1] + offset[1], mcontroller.position()[2] - 3 + offset[2]})
end

--- Draws debug text at the given world position.
-- @param str Text to draw.
-- @param pos Position in blocks.
-- @param[opt="green"] color "color" or {r, g, b}, where r/g/b are values between 0 and 255.
function wedit.debugText(str, pos, color)
  color = type(color) == "table" and color or type(color) == "string" and color or "green"
  world.debugText(str, pos, color)
end

--- Logs the formattable string with a WEdit prefix.
-- @param str Text to log.
-- @param ... Format arguments.
function wedit.logInfo(str, ...)
  sb.logInfo("WEdit: " .. str, ...)
end

--- Logs the formattable error string with a WEdit prefix.
-- @param str Text to log.
-- @param ... Format arguments.
function wedit.logError(str, ...)
  sb.logError("WEdit: " .. str, ...)
end

---  Adds an entry to the debug log map, with a WEdit prefix.
-- @param key Log map key. 'WEdit ' is added in front of this key.
-- @param val Log map value.
function wedit.setLogMap(key, val)
  sb.setLogMap(string.format("^cyan;WEdit %s", key), val)
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

  if iterations and wedit.config.doubleIterations then iterations = iterations * 2 end
  return airFound and iterations or 1
end

--- List of all active or queued tasks.
-- Task are added by wedit.Task:start(), do not manually add entries.
wedit.tasks = {}

--- Inject task handling into the update function.
local oldUpdate = update
update = function(...)
  oldUpdate(...)

  wedit.setLogMap("", string.format("(%s) Tasks.", #wedit.tasks))

  local first = true
  for k,task in pairs(wedit.tasks) do
    if coroutine.status(task.coroutine) == "dead" then
      wedit.tasks[k] = nil
    else
      -- Allow first synchronized and all asynchronous tasks.
      if not task.synchronized or first then
        local a, b = coroutine.resume(task.coroutine)
        if b then error(b) end

        if task.callback then
          task.callback()
        end

        if task.synchronized then
          first = false
        end
      end
    end
  end
end

--- Task Class.
-- Used to run actions in multiple steps over time.
wedit.Task = {}
wedit.Task.__index = wedit.Task
wedit.Task.__tostring = function() return "weditTask" end

--- Creates and returns a wedit Task object.
-- @param stages - Table of functions, each function defining code for one stage of the task.
--  Stages are repeated until changed or the task is completed.
--  Each stage function is passed the task object as it's first argument, used to easily access the task properties.
--  task.stage: Stage index, can be set to switch between stages.
--  task:nextStage():  Increases task.stage by 1. Does not abort remaining code when called in a stage function.
--  task.progress: Can be used to manually keep track of progress. Starts at 0.
--  task.progressLimit: Can be used to manually keep track of progress. Starts at 1.
--  task.parameters: Empty table that can be used to save and read parameters, without having to worry about reserved names.
--  task.complete(): Sets task.completed to true. Does not abort remaining code when called in a stage function.
--  task.callback: Function called every tick, regardless of delay and stage.
-- @param[opt=wedit.config.delay] delay Delay, in game ticks, between each step.
-- @param[opt=wedit.config.synchronized] synchronized Value indicating whether this task should run synchronized (true) or asynchronous (false).
-- @param[opt=wedit.config.description] description Description used to log task details.
-- @return Task object.
function wedit.Task.create(stages, delay, synchronized, description)
  local task = {}

  task.stages = type(stages) == "table" and stages or {stages}

  task.delay = delay or wedit.config.delay
  if wedit.config.doubleIterations then task.delay = math.ceil(task.delay / 2) end

  if type(synchronized) == "boolean" then
    task.synchronized = synchronized
  else
    task.synchronized = wedit.config.synchronized
  end
  task.description = description or wedit.config.description
  task.stage = 1
  task.tick = 0
  task.progress = 0
  task.progressLimit = 1
  task.completed = false
  task.parameters = {}

  task.coroutine = coroutine.create(function()
    while not task.completed do
      task.tick = task.tick + 1
      if task.tick > task.delay then
        task.tick = 0

        task.stages[task.stage](task)
      end
      coroutine.yield()
    end

    -- Soft reset task to allow repetition.
    task.completed = false
    task.stage = 1
    task.progress = 0
    task.progressLimit = 1
    task.parameters = {}
  end)

  setmetatable(task, wedit.Task)

  return task
end

--- Queues the initialized task for execution.
-- If the task is asynchronous, starts it.
function wedit.Task:start()
  if self.description ~= "" then
    local msg = self.synchronized and "Synchronized task (%s) queued. It will automatically start." or "Asynchronous task (%s) started."
    wedit.logInfo(string.format(msg, self.description))
  end
  table.insert(wedit.tasks, self)
end

--- Increases the stage index of the task by one.
-- @param[opt=false] keepProgress Value indicating whether task.progress should be kept, or reset.
function wedit.Task:nextStage(keepProgress)
  self.stage = self.stage + 1
  if (self.stage > #self.stages) then self:complete() return end

  if not keepProgress then self.progress = 0 end
  if self.description ~= "" then
    wedit.logInfo(string.format("Task (%s) stage increased to %s.", self.description, self.stage))
  end
end

--- Sets the status of the task to complete.
function wedit.Task:complete()
  if self.description ~= "" then
    wedit.logInfo(string.format("Task (%s) completed.", self.description))
  end
  self.completed = true
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
  if block.foreground.material then block.foreground.materialColor = block:getMaterialColor("foreground") end

  block.background = {
    material = block:getMaterial("background"),
    mod = block:getMod("background")
  }
  if block.background.material then block.background.materialColor = block:getMaterialColor("background") end

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

--[[
  Returns the liquid datas of this block, if any.
  @return - Nil or liquid data: {liquidID, liquidAmnt}.
]]
function wedit.Block:getLiquid()
  return world.liquidAt(self.position)
end

--[[
  Starbound Object Class. Contains data of a placeable object.
  Identifiable with tostring(obj).
]]
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

  local iterations = wedit.calculateIterations(bottomLeft, {width, height}, layer)

  local task = wedit.Task.create({
    function(task)
      if task.progress < iterations then
        task.progress = task.progress + 1

        for i=0,width-1 do
          for j=0,height-1 do
            local pos = {bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}
            world.placeMaterial(pos, layer, block, 0, true)
          end
        end
      else
        task:complete()
      end
    end
  }, nil, false)

  task.callback = function()
    wedit.debugRectangle(bottomLeft, topRight, "orange")
    world.debugText(string.format("^shadow;WEdit Fill (%s-%s) %s/%s", layer, block, task.progress, iterations), {bottomLeft[1], topRight[2] - 1}, "orange")
  end

  task:start()

  wedit.setLogMap("Fill", string.format("Task started with %s!", block))

  return copy
end

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

  for i=0,width-1 do
    for j=0,height-1 do
      local pos = {bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}
      world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
    end
  end

  wedit.setLogMap("Break", "Task executed!")

  return copy
end

--- Draws a block. If there is already a block, replace it.
-- @param pos World position to place the block at.
-- @param layer foreground or background
-- @param block Material name.
function wedit.pencil(pos, layer, block)
  local mat = world.material(pos, layer)
  if (mat and mat ~= block) or not block then
    world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
    if block and wedit.lockPosition(pos, layer) then
      wedit.Task.create({function(task)
        world.placeMaterial(pos, layer, block, 0, true)
        wedit.unlockPosition(pos, layer)
        task:complete()
      end}, nil, false):start()
    end
  else
    world.placeMaterial(pos, layer, block, 0, true)
  end

  wedit.setLogMap("Pencil", string.format("Drawn %s.", block))
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
          local liqName = wedit.liquidsByID[block.liquid[1]] or "unknown"
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
  position = wedit.clonePoint(position)

  local paste = {
    copy = copy,
    placeholders = {}
  }

  local backup = wedit.copy(position, {position[1] + copy.size[1], position[2] + copy.size[2]})

  local stages = {}

  local topRight = { position[1] + copy.size[1], position[2] + copy.size[2] }

  -- #region Stage 1: If copy has a background, break original background
  if copy.options.background then
    table.insert(stages, function(task)
      task.progress = task.progress + 1

      local it = wedit.config.doubleIterations and 6 or 3
      task.parameters.message = string.format("^shadow;Breaking background blocks (%s/%s).", task.progress - 1, it)

      if task.progress <= it then
        wedit.breakBlocks(position, topRight, "background")
      else
        task:nextStage()
      end
    end)
  end
  -- #endregion

  local iterations = wedit.calculateIterations(position, copy.size)

  -- #region Stage 2: If copy has background OR foreground, place background and/or placeholders.
  if copy.options.background or copy.options.foreground then
    table.insert(stages, function(task)
      task.progress = task.progress + 1

      -- TODO: Fixed some issue here where pasting would cut off, but this hotfix resulted in messy code that has to be cleaned up.
      -- I should really figure out an alternative to calculateIterations.
      local lessIterations = wedit.calculateIterations(position, copy.size, "foreground")
      if lessIterations + task.progress - 1 < iterations then
        iterations = lessIterations + task.progress - 2
      end

      task.parameters.message = string.format("^shadow;Placing background and placeholder blocks (%s/%s).", task.progress - 1, iterations)

      if task.progress > iterations then
        task:nextStage()
        return
      end

      for i=0, copy.size[1]-1 do
        for j=0, copy.size[2]-1 do
          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}
          -- Check if there's a background block here
          local block = copy.blocks[i+1][j+1]
          if block and copy.options.background and block.background.material then
            -- Place the background block.
            world.placeMaterial(pos, "background", block.background.material, 0, true)
          else
            if copy.options.foreground then
              -- Add a placeholder that reminds us later to remove the dirt placed here temporarily.
              if not paste.placeholders[i+1] then paste.placeholders[i+1] = {} end
              if not world.material(pos, "background") then
                paste.placeholders[i+1][j+1] = true

                world.placeMaterial(pos, "background", "dirt", 0, true)
              end
            end
          end
        end
      end
    end)
  end
  -- #endregion

  if copy.options.foreground then
    -- #region Stage 3: If copy has foreground, break it.
    table.insert(stages, function(task)
      task.progress = task.progress + 1

      local it = wedit.config.doubleIterations and 6 or 3
      task.parameters.message = string.format("^shadow;Breaking foreground blocks (%s/%s).", task.progress - 1, it)

      if task.progress <= it then
        wedit.breakBlocks(position, topRight, "foreground")
      else
        task:nextStage()
      end
    end)
    -- #endregion

    -- #region Stage 4: If copy has foreground, place it.
    table.insert(stages, function(task)

      task.parameters.message = string.format("^shadow;Placing foreground blocks.")

      for i=0, copy.size[1]-1 do
        for j=0, copy.size[2]-1 do
          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}

          -- Check if there's a background block here
          local block = copy.blocks[i+1][j+1]
          if block and block.foreground.material then
            -- Place the background block.
            world.placeMaterial(pos, "foreground", block.foreground.material, 0, true)
          end
        end
      end

      task:nextStage()
    end)
    -- #endregion
  end

  -- #region Stage 5: If copy has liquids, place them.
  if copy.options.liquids then
    table.insert(stages, function(task)

      task.parameters.message = string.format("^shadow;Placing liquids.")

      for i=0,copy.size[1]-1 do
        for j=0,copy.size[2]-1 do

          local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}

          local block = copy.blocks[i+1][j+1]
          if block and block.liquid then
            world.spawnLiquid(pos, block.liquid[1], block.liquid[2])
          end
        end
      end
      task:nextStage()
    end)
  end
  -- #endregion

  -- #region Stage 6: If paste has foreground, and thus may need placeholders, remove the placeholders.
  if copy.options.foreground then
    table.insert(stages, function(task)
      task.parameters.message = "^shadow;Removing placeholder blocks."
      for i,v in pairs(paste.placeholders) do
        for j,k in pairs(v) do
          local pos = {position[1] - 0.5 + i, position[2] - 0.5 + j}
          world.damageTiles({pos}, "background", pos, "blockish", 9999, 0)
        end
      end
      task:nextStage()
    end)
  end
  -- #endregion

  if copy.options.objects and #copy.objects > 0 then
    local hasItems = false

    -- #region Stage 7: If copy has objects, place them.
    table.insert(stages, function(task)
      task.parameters.message = "^shadow;Placing objects."
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
      task:nextStage()
    end)
    -- #endregion

    -- #region Stage 8: If copy has containers, place items in them.
    if copy.options.containerLoot then
      table.insert(stages, function(task)
        task.parameters.message = "^shadow;Placing items in containers."
        if hasItems then
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
        end
        task:nextStage()
      end)
    end
    -- #endregion
  end

  -- #region Stage 9: If copy has matmods, place them
  if copy.options.foregroundMods or copy.options.backgroundMods then
    table.insert(stages, function(task)
      task.parameters.message = "^shadow;Placing material mods."
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

      task:nextStage()
    end)
  end
  -- #endregion

  -- #region Stage 10: If copy has material colors, paint.
  if copy.options.materialColors then
    table.insert(stages, function(task)
      task.parameters.message = "^shadow;Dyeing tiles."

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
      task:nextStage()
    end)
  end
  -- #endregion

  -- #region Stage 11: Done
  table.insert(stages, function(task)
    task.parameters.message = "^shadow;Done pasting!"
    task:complete()
  end)
  -- #endregion

  -- Create paste task, and start it.
  -- Add a callback to display a message every tick, rather than every step.
  local task = wedit.Task.create(stages, nil, nil, "Paste")
  task.parameters.message = ""
  task.callback = function()
    wedit.debugRectangle(position, topRight, "orange")
    if task.parameters.message then
      wedit.debugText(task.parameters.message, {position[1], topRight[2]-1}, "orange")
    end
  end

  task:start()

  wedit.setLogMap("Paste", string.format("Beginning new paste at (%s,%s)", position[1], position[2]))

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
    wedit.logInfo("Could not flip copy in direction '" .. direction .. "'.")
  end

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

  bottomLeft = wedit.clonePoint(bottomLeft)
  topRight = wedit.clonePoint(topRight)

  local size = {topRight[1] - bottomLeft[1], topRight[2] - bottomLeft[2]}
  local oppositeLayer = layer == "foreground" and "background" or "foreground"

  local placeholders = {}
  local replacing = {}

  wedit.Task.create({
    function(task)
      -- Placeholders
      if toBlock then
        for i=0, size[1]-1 do
          if not placeholders[i+1] then placeholders[i+1] = {} end
          for j=0, size[2]-1 do
            local pos = {bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}
            if not world.material(pos, oppositeLayer) then
              world.placeMaterial(pos, oppositeLayer, "dirt", 0, true)
              placeholders[i+1][j+1] = true
            end
          end
        end
      end
      task:nextStage()
    end,
    function(task)
      -- Break matching
      for i=0, size[1]-1 do
        if not replacing[i+1] then replacing[i+1] = {} end
        for j=0, size[2]-1 do
          local pos = {bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}
          local block = world.material(pos, layer)
          if block and (not fromBlock or (block and block == fromBlock)) then
            replacing[i+1][j+1] = true
            world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
          end
        end
      end
      task:nextStage()
    end,
    function(task)
      -- Place new
      if toBlock then
        for i,v in pairs(replacing) do
          for j,k in pairs(v) do
            local pos = {bottomLeft[1] - 0.5 + i, bottomLeft[2] - 0.5 + j}
            world.placeMaterial(pos, layer, toBlock, 0, true)
          end
        end
      end
      task:nextStage()
    end,
    function(task)
      -- Remove placeholders
      for i,v in pairs(placeholders) do
        for j,k in pairs(v) do
          local pos = {bottomLeft[1] - 0.5 + i, bottomLeft[2] - 0.5 + j}
          world.damageTiles({pos}, oppositeLayer, pos, "blockish", 9999, 0)
        end
      end
      task:complete()
    end
  }):start()

  wedit.setLogMap("Replace", "Command started!")

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
  elseif wedit.lockPosition(pos, layer) then
    wedit.Task.create({function(task)
      world.placeMod(pos, layer, "grass", nil, false)
      task:nextStage()
    end, function(task)
      world.damageTiles({pos}, layer, pos, "blockish", 0, 0)
      wedit.unlockPosition(pos, layer)
      task:complete()
    end}):start()
  end
end

--- Drain any liquid in a selection.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
function wedit.drain(bottomLeft, topRight)
  for i=0,math.ceil(topRight[1]-bottomLeft[1])-1 do
    for j=0,math.ceil(topRight[2]-bottomLeft[2])-1 do
      world.destroyLiquid({bottomLeft[1] + i, bottomLeft[2] + j})
    end
  end
end

--- Fills a selection with a liquid.
-- @param bottomLeft Bottom left corner of the selection.
-- @param topRight Top right corner of the selection.
-- @param liquidId ID of the liquid.
-- @see wedit.liquids
function wedit.hydrate(bottomLeft, topRight, liquidId)
  for i=0,math.ceil(topRight[1]-bottomLeft[1])-1 do
    for j=0,math.ceil(topRight[2]-bottomLeft[2])-1 do
      world.spawnLiquid({bottomLeft[1] + i, bottomLeft[2] + j}, liquidId, 1)
    end
  end
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
