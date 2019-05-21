local Block = include("/scripts/wedit/objects/block.lua")
local Object = include("/scripts/wedit/objects/object.lua")
local debugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua").new()

local stamp = {}
module = stamp

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
-- @see stamp.paste
function stamp.copy(bottomLeft, topRight, copyOptions, logMaterials)
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
      ["foreground"] = true, ["foregroundMods"] = true,
      ["background"] = true, ["backgroundMods"] = true,
      ["liquids"] = true, ["objects"] = true, ["containerLoot"] = true,
      ["materialColors"] = true -- Material color is always saved (see Block), but can be ignored when pasting.
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
      local block = Block.create(pos, {i, j})
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

    local object = Object.create(id, offset)

    -- Count objects.
    if logMaterials then
      increaseCount(objectCount, object.name)
    end

    -- Set undefined containerLoot option to true if containers with items have been found.
    if copy.options.containerLoot == nil and object.items then copy.options.containerLoot = true end

    table.insert(copy.objects, object)
  end

  -- Logs materials found in the copy.
  if logMaterials then
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
function stamp.paste(copy, position)
  if not copy then return end

  position = wedit.clonePoint(position)

  local paste = {
    copy = copy,
    placeholders = {}
  }

  local backup = stamp.copy(position, {position[1] + copy.size[1], position[2] + copy.size[2]})

  local stages = {}

  local topRight = { position[1] + copy.size[1], position[2] + copy.size[2] }

  -- #region Stage 1: If copy has a background, break original background
  if copy.options.background then
    table.insert(stages, function(task)
      task.stageProgress = task.stageProgress + 1

      local it = wedit.getUserConfigData("doubleIterations") and 6 or 3
      task.parameters.message = string.format("^shadow;Breaking background blocks (%s/%s).", task.stageProgress - 1, it)

      if task.stageProgress <= it then
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
      task.stageProgress = task.stageProgress + 1

      -- TODO: Fixed some issue here where pasting would cut off, but this hotfix resulted in messy code that has to be cleaned up.
      -- I should really figure out an alternative to calculateIterations.
      local lessIterations = wedit.calculateIterations(position, copy.size, "foreground")
      if lessIterations + task.stageProgress - 1 < iterations then
        iterations = lessIterations + task.stageProgress - 2
      end

      task.parameters.message = string.format("^shadow;Placing background and placeholder blocks (%s/%s).", task.stageProgress - 1, iterations)

      if task.stageProgress > iterations then
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
    end)
  end
  -- #endregion

  if copy.options.foreground then
    -- #region Stage 3: If copy has foreground, break it.
    table.insert(stages, function(task)
      task.stageProgress = task.stageProgress + 1

      local it = wedit.getUserConfigData("doubleIterations") and 6 or 3
      task.parameters.message = string.format("^shadow;Breaking foreground blocks (%s/%s).", task.stageProgress - 1, it)

      if task.stageProgress <= it then
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
            world.placeMaterial(pos, "foreground", block.foreground.material, block.foreground.materialHueshift, true)
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
  local task = Task.new(stages, wedit.getUserConfigData("delay"))

  task.parameters.message = ""
  task.callback = function()
    debugRenderer:drawRectangle(position, topRight, "orange")
    if task.parameters.message then
      debugRenderer:drawText(task.parameters.message, {position[1], topRight[2]-1}, "orange")
    end
  end

  wedit.taskManager:start(task)

  wedit.logger:setLogMap("Paste", string.format("Beginning new paste at (%s,%s)", position[1], position[2]))

  return backup
end
