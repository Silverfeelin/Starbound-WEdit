--[[
  WEdit library (http://silvermods.com/WEdit/)

  The bresemham function falls under a different license, refer to it's documentation for licensing information.
  Hit ALT + 0 in NP++ to fold all, and get an overview of the contents of this script.
]]

--[[
  WEdit table, variables and functions accessed with 'wedit.' are stored here.
  Variables in wedit.user are prioritized over wedit.default; please do not touch wedit.default.
]]
wedit = {
  default = {
    delay = 15,
    -- Tasks with a blank description aren't logged.
    description = "",
    -- Note: synchronization is not optimized; setting this value to true may cause critical issues.
    synchronized = false
    },
  user = {

  }
}

--[[
  Available matmods. Has to be updated when game updates add or remove options.
]]
wedit.mods = {
  [1] = "aegisalt",
  [2] = "aliengrass",
  [3] = "alpinegrass",
  [4] = "aridgrass",
  [5] = "ash",
  [6] = "blackash",
  [7] = "bone",
  [8] = "ceilingslimegrass",
  [9] = "ceilingsnow",
  [10] = "charredgrass",
  [11] = "coal",
  [12] = "colourfulgrass",
  [13] = "copper",
  [14] = "corefragment",
  [15] = "crystal",
  [16] = "crystalgrass",
  [17] = "diamond",
  [18] = "durasteel",
  [19] = "ferozium",
  [20] = "fleshgrass",
  [21] = "flowerygrass",
  [22] = "gold",
  [23] = "grass",
  [24] = "heckgrass",
  [25] = "hiveceilinggrass",
  [26] = "hivegrass",
  [27] = "iron",
  [28] = "junglegrass",
  [29] = "lead",
  [30] = "metal",
  [31] = "moonstone",
  [32] = "moss",
  [33] = "platinum",
  [34] = "plutonium",
  [35] = "prisilite",
  [36] = "roots",
  [37] = "sand",
  [38] = "savannahgrass",
  [39] = "silver",
  [40] = "slimegrass",
  [41] = "snow",
  [42] = "snowygrass",
  [43] = "solarium",
  [44] = "sulphur",
  [45] = "tar",
  [46] = "tarceiling",
  [47] = "tentaclegrass",
  [48] = "thickgrass",
  [49] = "tilled",
  [50] = "tilleddry",
  [51] = "titanium",
  [52] = "toxicgrass",
  [53] = "trianglium",
  [54] = "tungsten",
  [55] = "undergrowth",
  [56] = "uranium",
  [57] = "veingrowth",
  [58] = "violium"
}

--[[
  Available liquids. Has to be updated when game updates add or remove options.
]]
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

--[[
  Draws lines on the edges of the given rectangle.
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
  @param [color="green"] - "color" or {r, g, b}, where r/g/b are values between 0 and 255.
]]
function wedit.debugRectangle(bottomLeft, topRight, color)
  color = type(color) == "table" and color or type(color) == "string" and color or "green"

  world.debugLine({bottomLeft[1], topRight[2]}, {topRight[1], topRight[2]}, color) -- top edge
  world.debugLine(bottomLeft, {bottomLeft[1], topRight[2]}, color) -- left edge
  world.debugLine({topRight[1], bottomLeft[2]}, {topRight[1], topRight[2]}, color) -- right edge
  world.debugLine({bottomLeft[1], bottomLeft[2]}, {topRight[1], bottomLeft[2]}, color) -- bottom edge
end

--[[
  Draws debug text below the user's character, or with an offset relative to it.
  @param str - Text to draw.
  @param [offset={0,0}] - {x,y} Offset relative to the feet of the player's character.
]]
function wedit.info(str, offset)
  if type(offset) == "nil" then offset = {0,0} end
  wedit.debugText(str, {mcontroller.position()[1] + offset[1], mcontroller.position()[2] - 3 + offset[2]})
end

--[[
  Draws debug text at the given world position.
  @param str - Text to draw.
  @param pos - Position in blocks.
  @param [color="green"] - "color" or {r, g, b}, where r/g/b are values between 0 and 255.
]]
function wedit.debugText(str, pos, color)
  color = type(color) == "table" and color or type(color) == "string" and color or "green"
  world.debugText(str, pos, color)
end

--[[
  Logs the given string with a WEdit prefix.
  @param str - Text to log.
]]
function wedit.logInfo(str)
  sb.logInfo("WEdit: %s", str)
end

--[[
  Adds an entry to the debug log map, with a WEdit prefix.
  @param key - Log map key. 'WEdit' is added in front of this key.
  @param val - Log map value.
]]
function wedit.setLogMap(key, val)
  sb.setLogMap(string.format("^cyan;WEdit %s", key), val)
end

--[[
  Returns a copy of the given point.
  Generally used to prevent having a bunch of references to the same points,
  meaning asynchronous tasks will have undesired effects when changing your selection mid-task.
  @param point - Point to clone.
  @return - Cloned point.
]]
function wedit.clonePoint(point)
  return {point[1], point[2]}
end

--[[
  Quick attempt to lessen the amount of iterations needed to complete tasks such as filling an area.
  For each block, see if there's a foreground material. If there is, see how far it's away from the furthest edge.
  If this number is smaller than than the current amount of iterations, less iterations are needed.
  Problem: Since every block is compared to the furthest edge and not other blocks, this generally misses a lot of skippable iterations.
  @param bottomLeft - [X, Y], representing the bottom left corner of the rectangle.
  @param size - [X, Y], representing the dimensions of the rectangle.
  @param layer - "foreground" or "background", representing the layer to calculate iterations needed to fill for.
    Note: The algorithm will check the OPPOSITE layer, as it assumes the given layer will be emptied before filling.
]]
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

  return airFound and iterations or 1
end

--[[
  List of all active or queued tasks.
  Tasks queueing is done with wedit.Task:start(), do not manually add entries.
]]
wedit.tasks = {}

--[[
  Inject task handling into the update function.
]]
local oldUpdate = update
update = function(args)
  oldUpdate(args)

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

--[[
  Task Class.
  Used to run actions in multiple steps over time.
]]
wedit.Task = {}
wedit.Task.__index = wedit.Task
wedit.Task.__tostring = function() return "weditTask" end

--[[
  Creates and returns a wedit Task object.
  @param stages - Table of functions, each function defining code for one stage of the task.
    Stages are repeated until changed or the task is completed.
    Each stage function is passed the task object as it's first argument, used to easily access the task properties.
    task.stage: Stage index, can be set to switch between stages.
    task:nextStage():  Increases task.stage by 1. Does not abort remaining code when called in a stage function.
    task.progress: Can be used to manually keep track of progress. Starts at 0.
    task.progressLimit: Can be used to manually keep track of progress. Starts at 1.
    task.parameters: Empty table that can be used to save and read parameters, without having to worry about reserved names.
    task.complete(): Sets task.completed to true. Does not abort remaining code when called in a stage function.
    task.callback: Function called every tick, regardless of delay and stage.
  @param [delay=wedit.user.delay] - Delay, in game ticks, between each step.
  @param [synchronized=wedit.user.synchronized] - Value indicating whether this task should run synchronized (true) or asynchronized (false).
  @param [description=wedit.user.description] - Description used to log task details.
  @return - Task object.
]]
function wedit.Task.create(stages, delay, synchronized, description)
  local task = {}

  task.stages = type(stages) == "table" and stages or {stages}

  task.delay = delay or wedit.user.delay or wedit.default.delay
  if type(synchronized) == "boolean" then
    task.synchronized = synchronized
  elseif type(wedit.user.synchronized) == "boolean" then
    task.synchronized = wedit.user.synchronized
  else
    task.synchronized = wedit.default.synchronized
  end
  task.description = description or wedit.user.description or wedit.default.description
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

--[[
  Queues the initialized task for execution.
]]
function wedit.Task:start()
  if self.description ~= "" then
    local msg = self.synchronized and "Synchronized task (%s) queued. It will automatically start." or "Asynchronous task (%s) started."
    wedit.logInfo(string.format(msg, self.description))
  end
  table.insert(wedit.tasks, self)
end

--[[
  Increases the stage index of the task by one.
  @param [keepProgress=0] - Value indicating whether task.progress should be kept, or reset.
]]
function wedit.Task:nextStage(keepProgress)
  self.stage = self.stage + 1
  if (self.stage > #self.stages) then self:complete() return end

  if not keepProgress then self.progress = 0 end
  if self.description ~= "" then
    wedit.logInfo(string.format("Task (%s) stage increased to %s.", self.description, self.stage))
  end
end

--[[
  Sets the status of the task to complete.
]]
function wedit.Task:complete()
  if self.description ~= "" then
    wedit.logInfo(string.format("Task (%s) completed.", self.description))
  end
  self.completed = true
end

--[[
  Starbound Block Class.
  Identifiable with tostring(obj).
]]
wedit.Block = {}
wedit.Block.__index = wedit.Block
wedit.Block.__tostring = function() return "starboundBlock" end

--[[
  Creates and returns a block object.
  Each optional parameter is automatically fetched when left blank.
  @param position - Original position of the block.
  @param offset - Offset from the bottom left corner of the copied area.
  @param [foreground] - Material found in the foreground layer.
  @param [foregroundMod] - Matmod found in the foreground layer.
  @param [background] - Material found in the background layer.
  @param [backgroundMod] - Matmod found in the background layer.
  @param [liquid] - Liquid data found.
]]
function wedit.Block.create(position, offset, foreground, foregroundMod, background, backgroundMod, liquid)
  if not position then error("WEdit: Attempted to create a Block object for a block without a valid original position.") end
  if not offset then error(string.format("WEdit: Attempted to create a Block object for a block at (%s, %s) without a valid offset.", position[1], position[2])) end

  local block = {
    position = position,
    offset = offset
  }

  setmetatable(block, wedit.Block)

  block.foreground = {
    material = foreground or block:getMaterial("foreground"),
    mod = foregroundMod or block:getMod("foreground")
  }

  block.background = {
    material = background or block:getMaterial("background"),
    mod = backgroundMod or block:getMod("background")
  }

  block.liquid = liquid or block:getLiquid()

  return block
end

--[[
  Returns the material name of this block, if any.
  @param layer - "foreground" or "background".
  @return - Material name in the given layer.
]]
function wedit.Block:getMaterial(layer)
  return world.material(self.position, layer)
end

--[[
  Returns the matmod name of this block, if any.
  @param layer - "foreground" or "background".
  @return - Matmod name in the given layer.
]]
function wedit.Block:getMod(layer)
  return world.mod(self.position, layer)
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

--[[
  Creates and returns a Starbound object.. object.
  @param id - Entity id of the source object.
  @param offset - Offset from the bottom left corner of the copied area.
  @return - Starbound Object data. Contains id, offset, name, parameters, [items].
]]
function wedit.Object.create(id, offset, name, parameters)
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

--[[
  Returns the identifier of the object.
  @return - Object name.
]]
function wedit.Object:getName()
  return world.entityName(self.id)
end

--[[
  Returns the full parameters of the object.
  @return - Object parameters.
]]
function wedit.Object:getParameters()
  return world.getObjectParameter(self.id, "", nil)
end

--[[
  Returns the items of the container object, or nil if the object isn't a container.
  @param clearTreasure - If true, sets the treasurePools parameter to nil, to avoid random loot after breaking the object.
  @return - Contained items, or nil.
]]
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

--[[
  Fills all air blocks in the given layer between the two points.
  Calls wedit.breakBlocks using the given arguments if the block is nil, false or "air".
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
  @param layer - "foreground" or "background".
  @param block - String representation of material to use.
  @return - Copy of the selection prior to the fill command.
]]
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

--[[
  Break all blocks in the given layer between the two points.
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
  @param layer - "foreground" or "background".
  @return - Copy of the selection prior to the break command.
]]
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

--[[
  Draws a block, or break an existing block, at the location.
  @param pos - World position in blocks.
  @param layer - "foreground" or "background".
  @param block - String representation of material to use.
]]
function wedit.pencil(pos, layer, block)
  local mat = world.material(pos, layer)
  if (mat and mat ~= block) or not block then
    world.damageTiles({pos}, layer, pos, "blockish", 9999, 0)
    if block then
      -- TODO: Time out task for same block within wedit.user.delay, to prevent multiple tasks trying to place the same block.
      wedit.Task.create({function(task)
        world.placeMaterial(pos, layer, block, 0, true)
        task:complete()
      end}, nil, false):start()
    end
  else
    world.placeMaterial(pos, layer, block, 0, true)
  end

  wedit.setLogMap("Pencil", string.format("Drawn %s.", block))
end

--[[
  Copies and returns the given selection. Used in combination with wedit.paste.
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
  @param [copyOptions] - Table with options representing what should be copied. Default is all-true.
    Supported options:
    foreground, foregroundMods, background, backgroundMods, liquids, objects, containerLoot
    Options not defined will be set to true if any match has been found in the selection.
]]
function wedit.copy(bottomLeft, topRight, copyOptions)
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
      ["containerLoot"] = true
    }
  end

  -- TODO: Implement ignorable options. EG: Objects = true, but no objects were found.
  ignorableOptions = {}

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

      if copy.options.foreground == nil and block.foreground.material then copy.options.foreground = true end
      if copy.options.foregroundMods == nil and block.foreground.mod then copy.options.foregroundMods = true end
      if copy.options.background == nil and block.background.material then copy.options.background = true end
      if copy.options.backgroundMods == nil and block.background.mod then copy.options.backgroundMods = true end
      if copy.options.liquids == nil and block.liquid then copy.options.liquids = true end
    end
  end

  if copy.options.objects == nil and #objectIds > 0 then copy.options.objects = true end

  -- Iterate over every found object
  for id,_ in pairs(objectIds) do
    local offset = world.entityPosition(id)
    offset = {
      offset[1] - bottomLeft[1],
      offset[2] - bottomLeft[2]
    }

    local object = wedit.Object.create(id, offset)

    -- Set undefined containerLoot option to true if containers with items have been found.
    if copy.options.containerLoot == nil and object.items then copy.options.containerLoot = true end

    table.insert(copy.objects, object)
  end

  return copy
end

--[[
  Initializes and begins a paste with the given values. The position represents the bottom left corner of the paste.
  @param copy - Copy table; see wedit.copy.
  @param position - [X, Y], representing the bottom left corner of the paste area.
  @return - Copy of the selection prior to the paste command.
]]
function wedit.paste(copy, position)
  position = wedit.clonePoint(position)

  local paste = {
    copy = copy,
    placeholders = {}
  }

  local backup = wedit.copy(position, {position[1] + copy.size[1], position[2] + copy.size[2]})

  local stages = {}

  local topRight = { position[1] + copy.size[1], position[2] + copy.size[2] }

  ---
  -- Stage one: If copy has a background, break original background
  if copy.options.background then
    table.insert(stages, function(task)
      task.progress = task.progress + 1
      task.parameters.message = string.format("^shadow;Breaking background blocks (%s/%s).", task.progress - 1, 3)
      if task.progress <= 3 then
        wedit.breakBlocks(position, topRight, "background")
      else
        task:nextStage()
      end
    end)
  end
  -- /Stage one
  ---

  local iterations = wedit.calculateIterations(position, copy.size)

  ---
  -- Stage two: If copy has background OR foreground, place background and/or placeholders.
  if copy.options.background or copy.options.foreground then
    table.insert(stages, function(task)
      task.progress = task.progress + 1
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
  -- /Stage two
  ---

  if copy.options.foreground then
    ---
    -- Stage three: If copy has foreground, break it.
    table.insert(stages, function(task)
      task.progress = task.progress + 1
      task.parameters.message = string.format("^shadow;Breaking foreground blocks (%s/%s).", task.progress - 1, 3)

      if task.progress <= 3 then
        wedit.breakBlocks(position, topRight, "foreground")
      else
        task:nextStage()
      end
    end)
    -- /Stage three
    ---

    ---
    -- Stage four: If copy has foreground, place it.
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
    -- /Stage four
    ---
  end

  ---
  -- Stage five: If copy has liquids, place them.
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
  -- /Stage five
  ---

  ---
  -- Stage six: If paste has foreground, and thus may need placeholders, remove the placeholders.
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
  -- /Stage six
  ---

  if copy.options.objects and #copy.objects > 0 then
    local hasItems = false

    ---
    -- Stage seven: If copy has objects, place them.
    table.insert(stages, function(task)
      task.parameters.message = "^shadow;Placing objects."
      local centerOffset = copy.size[1] / 2
      for _,v in pairs(copy.objects) do
        -- TODO: Object Direction
        local dir = v.offset[1] < centerOffset and 1 or -1
        world.placeObject(v.name, {position[1] + v.offset[1], position[2] + v.offset[2]}, dir, v.parameters)

        if v.items ~= nil then hasItems = true end
      end
      task:nextStage()
    end)
    -- /Stage seven
    ---

    ---
    -- Stage eight: If copy has containers, place items in them.
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
    -- /Stage eight
    ---
  end

  ---
  -- Stage nine: If copy has matmods, place them
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
  -- /Stage nine
  ---

  ---
  -- Stage ten: Done
  table.insert(stages, function(task)
    task.parameters.message = "^shadow;Done pasting!"
    task:complete()
  end)
  -- /Stage ten
  ---

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

--[[
  Initializes and begins a replace operation.
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
  @param layer - "foreground" or "background".
  @param toBlock - String representation of material to replace blocks with. Replaces with air when value is nil or false.
  @param [fromBlock] - String representation of material to replace. Replaces all blocks when value is nil or false.
  @returns - Copy of the selection prior to the replace command.
]]
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

--[[
  Modifies the block at the given position, using a (hopefully validated) material mod type.
  @param pos - [X, Y], representing the block position.
  @param layer - "foreground" or "background".
  @param block - String representation of material to replace blocks with. Replaces with air when value is nil or false.
]]
function wedit.placeMod(pos, layer, block)
  world.placeMod(pos, layer, block, nil, false)
end

--[[
  Drains any liquid in the given selection.
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
]]
function wedit.drain(bottomLeft, topRight)
  for i=0,math.ceil(topRight[1]-bottomLeft[1])-1 do
    for j=0,math.ceil(topRight[2]-bottomLeft[2])-1 do
      world.destroyLiquid({bottomLeft[1] + i, bottomLeft[2] + j})
    end
  end
end

--[[
  Fills the given selection with liquid.
  @param bottomLeft - [X1, Y1], representing the bottom left corner of the rectangle.
  @param topRight - [X2, Y2], representing the top right corner of the rectangle.
  @param liquidId - ID of the liquid to use.
]]
function wedit.hydrate(bottomLeft, topRight, liquidId)
  for i=0,math.ceil(topRight[1]-bottomLeft[1])-1 do
    for j=0,math.ceil(topRight[2]-bottomLeft[2])-1 do
      world.spawnLiquid({bottomLeft[1] + i, bottomLeft[2] + j}, liquidId, 1)
    end
  end
end

--[[
  Runs callback function with parameters (currentX, currentY) for each block in a line between the given points using Bresenham's Line Algorithm.
  Base code found at https://github.com/kikito/bresenham.lua is licensed under https://github.com/kikito/bresenham.lua/blob/master/MIT-LICENSE.txt
  @param startPos - [X1, Y1], representing the start of the line.
  @param endPos - [X2, Y2], representing the end of the line.
  @param callback - Callback function, called for every block on the line with the X and Y value as separate arguments.
]]
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

--[[
  Call bresenham function with a callback function to place the given block.
  @param startPos - [X1, Y1], representing the start of the line.
  @param endPos - [X2, Y2], representing the end of the line.
  @param layer - "foreground" or background".
  @param block - String representation of material to use.
]]
function wedit.line(startPos, endPos, layer, block)
  if block ~= "air" and block ~= "none" then
    wedit.bresenham(startPos, endPos, function(x, y) world.placeMaterial({x, y}, layer, block, 0, true) end)
  else
    wedit.bresenham(startPos, endPos, function(x, y) world.damageTiles({{x,y}}, layer, {x,y}, "blockish", 9999, 0) end)
  end
end

--[[
  Function that logs environmental values and functions.
  You can't have enough of these at your disposal.
]]
function wedit.logENV()
  for k,v in pairs(_ENV) do
    if type(v) == "table" then
      for k2,v2 in pairs(v) do
        sb.logInfo("%s.%s", k, k2)
      end
    else
      sb.logInfo("%s", k)
    end
  end
end
