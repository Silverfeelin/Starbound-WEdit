require "/scripts/wedit/libs/vec2Ext.lua"

local Block = include("/scripts/wedit/objects/block.lua")
local Object = include("/scripts/wedit/objects/object.lua")
local Task = include("/scripts/wedit/objects/task.lua")
local Rectangle = include("/scripts/wedit/objects/shapes/rectangle.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local LiquidHelper = include("/scripts/wedit/helpers/liquidHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

local taskManager = include("/scripts/wedit/helpers/taskManager.lua").instance
local debugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua").instance
local logger = include("/scripts/wedit/helpers/logger.lua").instance

local Stamp = {}
module = Stamp

--- Copies a selection.
-- @param rect Rectangle shape
-- @param [copyOptions] Table containing options to copy. If nil, copies everything.
--   <layer> - Copies materials in the layer.
--   <layer>Mods - Copies matmods in the layer.
--   liquids - Copies liquids (block based, not density based).
--   objects - Copies objects with all parameters.
--   containerLoot - Copies items in copied containers.
-- @param [logMaterials=false] If true, logs the materials found in the copy.
-- @see Stamp.paste
function Stamp.copy(rect, copyOptions, logMaterials)
  bottomLeft = vec2.clone(rect:getStart())
  topRight = vec2.clone(rect:getEnd())

  local width = topRight[1] - bottomLeft[1] + 1
  local height = topRight[2] - bottomLeft[2] + 1

  if width <= 0 or height <= 0 then
    sb.logInfo("WEdit: Failed to copy area at (%s, %s) sized %sx%s.", bottomLeft[1], bottomLeft[2], width, height)
    return
  end

  -- Default copy options
  if not copyOptions then
    copyOptions = {
      ["foreground"] = true, ["foregroundMods"] = true, ["background"] = true, ["backgroundMods"] = true,
      ["liquids"] = true, ["objects"] = true, ["containerLoot"] = true, ["materialColors"] = true
    }
  end

  local copy = {
    origin = bottomLeft, size = {width, height},
    blocks = {}, objects = {},
    options = copyOptions
  }

  -- Set containing objects in the selection.
  local objectIds = {}

  local materialCount = {}
  local matmodCount = {}
  local liquidCount = {}
  local objectCount = {}

  local increaseCount = function(tbl, key)
    if not key then return end
    if not tbl[key] then tbl[key] = 1 else tbl[key] = tbl[key] + 1 end
  end

  -- Iterate over every block
  for i=0,width-1 do
    copy.blocks[i+1] = {}
    for j=0,height-1 do
      -- Block coordinate
      local pos = {bottomLeft[1] + 0.5 + i, bottomLeft[2] + 0.5 + j}

      -- Object check
      if copy.options.objects then
        local objects = world.objectQuery(pos, 1, {order="nearest"})
        if objects and objects[1] then
          objectIds[objects[1]] = true
        end
      end

      -- Block check
      local block = Block.create(pos, {i, j})
      copy.blocks[i+1][j+1] = block

      -- Count materials.
      increaseCount(materialCount, block.foreground.material)
      increaseCount(materialCount, block.background.material)
      increaseCount(matmodCount, block.foreground.mod)
      increaseCount(matmodCount, block.background.mod)
      if block.liquid then
        local liqName = LiquidHelper.getName(block.liquid[1]) or "unknown"
        increaseCount(liquidCount, liqName)
      end
    end
  end

  -- Iterate over every found object
  for id,_ in pairs(objectIds) do
    local offset = world.entityPosition(id)
    offset = {
      offset[1] - bottomLeft[1],
      offset[2] - bottomLeft[2]
    }

    local object = Object.create(id, offset)

    -- Count objects.
    increaseCount(objectCount, object.name)

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
function Stamp.paste(copy, position)
  if not copy then return end
  position = vec2.clone(position)
  local paste = { copy = copy, placeholders = {} }
  local topRight = { position[1] + copy.size[1] - 1, position[2] + copy.size[2] - 1 }
  local rect = Rectangle:create(position, topRight)

  local message = ""
  local draw = function()
    debugRenderer:drawRectangle(position, topRight, "orange")
    if message then
      local top = topRight[2]
      if SelectionHelper.isValid() and SelectionHelper.getEnd()[2] == top then top = top + 1 end
      debugRenderer:drawText(message, {position[1], top + 1 }, "orange")
    end
  end
  local waitShort = function() util.waitTicks(10, draw) end

  local task = taskManager:startNew(function()
    -- #region Stage 1: Blocks
    if copy.options.foreground or copy.options.background then
      message = "^shadow;Breaking blocks."
      for i=1,3 do
        if copy.options.foreground then
          BlockHelper.clear(rect, "foreground")
        end
        if copy.options.background then
          BlockHelper.clear(rect, "background")
        end

        if util.waitTicks(10, function()
          draw()
          -- TODO: Better detection for when everything is broken. I.e. trees & matmods.
          --return not world.material(position, "background")
          --   and not world.material(topRight, "background")
        end) then --[[break]] end
      end

      message = "^shadow;Placing blocks."
      waitShort()
      for i=0, copy.size[1]-1 do for j=0, copy.size[2]-1 do
        local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}
        local block = copy.blocks[i+1][j+1]
        if block then
          if block.foreground.material then
            world.placeMaterial(pos, "foreground", block.foreground.material, block.foreground.materialHueshift, true)
          end
          if block.background.material then
            world.placeMaterial(pos, "background", block.background.material, block.background.materialHueshift, true)
          end
        end
      end end
    end
    -- #endregion

    -- #region Stage 2: Liquids
    if copy.options.liquids then
        message = "^shadow;Placing liquids."
        waitShort()
        for i=0,copy.size[1]-1 do
          for j=0,copy.size[2]-1 do
            local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}

            local block = copy.blocks[i+1][j+1]
            if block and block.liquid then
              world.spawnLiquid(pos, block.liquid[1], block.liquid[2])
            end
          end
        end
    end
    -- #endregion

    -- #region Stage 3: Objects
    if copy.options.objects and #copy.objects > 0 then
      local hasItems = false
      message = "^shadow;Placing objects."
      waitShort()
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

      if copy.options.containerLoot and hasItems then
        message = "^shadow;Placing items in containers."
        waitShort()
        for i,v in pairs(util.filter(copy.objects, function() return v.items end)) do
          local ids = world.objectQuery({position[1] + v.offset[1], position[2] + v.offset[2]}, 1, {order="nearest"})
          if ids and ids[1] then
            for j,k in ipairs(v.items) do
              world.containerAddItems(ids[1], k)
            end
          end
        end
      end
    end
    -- #endregion

    -- #region Stage 4: Matmods
    if copy.options.foregroundMods or copy.options.backgroundMods then
        message = "^shadow;Placing material mods."
        waitShort()
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
    end
    -- #endregion

    -- #region Stage 5: Paint
    if copy.options.materialColors then
        message = "^shadow;Dyeing tiles."
        waitShort()
        for i=0,copy.size[1]-1 do
          for j=0,copy.size[2]-1 do
            local pos = {position[1] + 0.5 + i, position[2] + 0.5 + j}
            local block = copy.blocks[i+1][j+1]

            if block.foreground.materialColor then
              world.setMaterialColor(pos, "foreground", block.foreground.materialColor or 0)
            end
            if block.background.materialColor then
              world.setMaterialColor(pos, "background", block.background.materialColor or 0)
            end
          end
        end
    end
    -- #endregion

    -- #region Stage 6: Done
    message = "^shadow;Done pasting!"
    waitShort()
    -- #endregion
  end)

  logger:setLogMap("Paste", string.format("Beginning new paste at (%s,%s)", position[1], position[2]))
  return task
end
