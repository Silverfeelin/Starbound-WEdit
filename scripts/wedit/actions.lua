--- WEdit Actions (https://github.com/Silverfeelin/Starbound-WEdit)
--
-- Script used by controller.lua. Keeps all WEdit actions centralized in one place.
-- This script can not be used by itself, as it relies on data defined in or adjusted by wedit.lua and/or controller.lua.

require "/interface/wedit/dyePicker/dyePickerUtil.lua"
require "/interface/wedit/huePicker/huePickerUtil.lua"
require "/scripts/wedit/libs/include.lua"

local controller = include("/scripts/wedit/controller.lua")
local shapes = include("/scripts/wedit/shapes.lua")

local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")
local AssetHelper = include("/scripts/wedit/helpers/assetHelper.lua")

wedit.actions = wedit.actions or {}

--- Sets or updates the selection area.
wedit.actions.WE_AllInOne = include("/scripts/wedit/actions/allInOne.lua")
wedit.actions.WE_BlockPinner = include("/scripts/wedit/actions/blockPinner.lua")
wedit.actions.WE_ColorPicker = include("/scripts/wedit/actions/colorPicker.lua")
wedit.actions.WE_Dye = include("/scripts/wedit/actions/dye.lua")
wedit.actions.WE_Erase = include("/scripts/wedit/actions/erase.lua")
wedit.actions.WE_Fill = include("/scripts/wedit/actions/fill.lua")
wedit.actions.WE_Flip = include("/scripts/wedit/actions/flip.lua")
wedit.actions.WE_Pencil = include("/scripts/wedit/actions/pencil.lua")
wedit.actions.WE_Select = include("/scripts/wedit/actions/select.lua")
wedit.actions.WE_Stamp = include("/scripts/wedit/actions/stamp.lua")
wedit.actions.WE_Undo = include("/scripts/wedit/actions/undo.lua")

--- Function to draw the block of the item under the cursor like the Pencil tool.
-- Uses the configured brush type and block brush size.
-- Existing blocks will be replaced.
function wedit.actions.WE_Block()
  controller.info("^shadow;^orange;WEdit: Material Placer")
  controller.info("^shadow;^yellow;Primary Fire: Place in foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Place in background.", {0,-2})

  local itemData = controller.itemData
  if itemData and itemData.block then
    controller.info("^shadow;^yellow;Material: ^red;" .. itemData.block .. "^yellow;.", {0,-3})
  else
    controller.info("^shadow;^yellow;Material: ^red;None^yellow;.", {0,-3})
  end

  local debugCallback = function(pos)
    DebugRenderer.instance:drawBlock(pos)
  end

  local layer = InputHelper.primary and "foreground" or
    InputHelper.alt and "background" or nil

  local callback
  if layer then
    callback = function(pos)
      debugCallback(pos)
      wedit.pencil(pos, layer, itemData.block, itemData.hueshift)
    end
  else
    callback = debugCallback
  end

  if wedit.getUserConfigData("brushShape") == "square" then
    shapes.rectangle(tech.aimPosition(), wedit.getUserConfigData("blockSize"), nil, callback)
  elseif wedit.getUserConfigData("brushShape") == "circle" then
    shapes.circle(tech.aimPosition(), wedit.getUserConfigData("blockSize"), callback)
  end
end

--- Function to create a schematic item for the given selection, which allows you to paste the selection later.
function wedit.actions.WE_SchematicMaker()
  controller.info("^shadow;^orange;WEdit: Schematic Maker")
  controller.info("^shadow;^yellow;Primary Fire: Create Schematic.", {0,-1})

  if not InputHelper.isLocked() and InputHelper.primary and SelectionHelper.isValid() then
    InputHelper.lock()

    local copy = StampHelper.copy(SelectionHelper.getStart(), SelectionHelper.getEnd(), nil, true)

    local icon = "/assetMissing.png?replace;00000000=ffffff;ffffff00=ffffff?setcolor=ffffff?scalenearest=1?crop=0;0;16;15?blendmult=/objects/outpost/customsign/signplaceholder.png;0;0?replace;01000101=FFFFFF00;01000201=FFFFFF00;01000301=090A0BFF;01000401=090A0BFF;01000501=090A0BFF;01000601=090A0BFF;01000701=090A0BFF;01000801=090A0BFF;02000101=FFFFFF00;02000201=090A0BFF;02000301=1B63ABFF;02000401=5796D5FF;02000501=5796D5FF;02000601=5796D5FF;02000701=5796D5FF;02000801=5796D5FF;03000101=FFFFFF00;03000201=090A0BFF;03000301=5796D5FF;03000401=77B9EAFF;03000501=9ED1F7FF;03000601=77B9EAFF;03000701=77B9EAFF;03000801=9ED1F7FF;04000101=FFFFFF00;04000201=090A0BFF;04000301=5796D5FF;04000401=77B9EAFF;04000501=5796D5FF;04000601=77B9EAFF;04000701=090A0BFF;04000801=090A0BFF;05000101=FFFFFF00;05000201=090A0BFF;05000301=5796D5FF;05000401=77B9EAFF;05000501=9ED1F7FF;05000601=090A0BFF;05000701=B1B1B1FF;05000801=B1B1B1FF;06000101=FFFFFF00;06000201=090A0BFF;06000301=5796D5FF;06000401=77B9EAFF;06000501=090A0BFF;06000601=B1B1B1FF;06000701=566EB1FF;06000801=749FC7FF;07000101=FFFFFF00;07000201=090A0BFF;07000301=5796D5FF;07000401=090A0BFF;07000501=B1B1B1FF;07000601=566EB1FF;07000701=CBECF4FF;07000801=CBECF4FF;08000101=FFFFFF00;08000201=090A0BFF;08000301=5796D5FF;08000401=090A0BFF;08000501=B1B1B1FF;08000601=749FC7FF;08000701=CBECF4FF;08000801=CBECF4FF;09000101=FFFFFF00;09000201=090A0BFF;09000301=5796D5FF;09000401=090A0BFF;09000501=B1B1B1FF;09000601=749FC7FF;09000701=9DD7E6FF;09000801=9DD7E6FF;10000101=FFFFFF00;10000201=090A0BFF;10000301=5796D5FF;10000401=090A0BFF;10000501=B1B1B1FF;10000601=566EB1FF;10000701=9DD7E6FF;10000801=9DD7E6FF;11000101=FFFFFF00;11000201=090A0BFF;11000301=5796D5FF;11000401=090A0BFF;11000501=743D23FF;11000601=B1B1B1FF;11000701=566EB1FF;11000801=749FC7FF;12000101=FFFFFF00;12000201=090A0BFF;12000301=090A0BFF;12000401=743D23FF;12000501=8D5834FF;12000601=BD8549FF;12000701=B1B1B1FF;12000801=B1B1B1FF;13000101=FFFFFF00;13000201=090A0BFF;13000301=743D23FF;13000401=8D5834FF;13000501=BD8549FF;13000601=090A0BFF;13000701=090A0BFF;13000801=090A0BFF;14000101=090A0BFF;14000201=743D23FF;14000301=8D5834FF;14000401=BD8549FF;14000501=090A0BFF;14000601=5796D5FF;14000701=5796D5FF;14000801=5796D5FF;15000101=090A0BFF;15000201=743D23FF;15000301=BD8549FF;15000401=090A0BFF;15000501=090A0BFF;15000601=090A0BFF;15000701=090A0BFF;15000801=090A0BFF;16000101=FFFFFF00;16000201=090A0BFF;16000301=090A0BFF;16000401=FFFFFF00;16000501=FFFFFF00;16000601=FFFFFF00;16000701=FFFFFF00;16000801=FFFFFF00?blendmult=/objects/outpost/customsign/signplaceholder.png;0;-8?replace;01000101=090A0BFF;01000201=090A0BFF;01000301=090A0BFF;01000401=090A0BFF;01000501=090A0BFF;01000601=090A0BFF;01000701=FFFFFF00;02000101=5796D5FF;02000201=5796D5FF;02000301=5796D5FF;02000401=5796D5FF;02000501=5796D5FF;02000601=1B63ABFF;02000701=090A0BFF;03000101=77B9EAFF;03000201=9ED1F7FF;03000301=77B9EAFF;03000401=9ED1F7FF;03000501=77B9EAFF;03000601=5796D5FF;03000701=090A0BFF;04000101=090A0BFF;04000201=090A0BFF;04000301=77B9EAFF;04000401=9ED1F7FF;04000501=77B9EAFF;04000601=5796D5FF;04000701=090A0BFF;05000101=B1B1B1FF;05000201=B1B1B1FF;05000301=090A0BFF;05000401=9ED1F7FF;05000501=77B9EAFF;05000601=5796D5FF;05000701=090A0BFF;06000101=749FC7FF;06000201=566EB1FF;06000301=B1B1B1FF;06000401=090A0BFF;06000501=77B9EAFF;06000601=5796D5FF;06000701=090A0BFF;07000101=9DD7E6FF;07000201=9DD7E6FF;07000301=566EB1FF;07000401=B1B1B1FF;07000501=090A0BFF;07000601=5796D5FF;07000701=090A0BFF;08000101=9DD7E6FF;08000201=9DD7E6FF;08000301=749FC7FF;08000401=B1B1B1FF;08000501=090A0BFF;08000601=5796D5FF;08000701=090A0BFF;09000101=9DD7E6FF;09000201=9DD7E6FF;09000301=749FC7FF;09000401=B1B1B1FF;09000501=090A0BFF;09000601=5796D5FF;09000701=090A0BFF;10000101=9DD7E6FF;10000201=9DD7E6FF;10000301=566EB1FF;10000401=B1B1B1FF;10000501=090A0BFF;10000601=5796D5FF;10000701=090A0BFF;11000101=749FC7FF;11000201=566EB1FF;11000301=B1B1B1FF;11000401=090A0BFF;11000501=77B9EAFF;11000601=5796D5FF;11000701=090A0BFF;12000101=B1B1B1FF;12000201=B1B1B1FF;12000301=090A0BFF;12000401=9ED1F7FF;12000501=77B9EAFF;12000601=5796D5FF;12000701=090A0BFF;13000101=090A0BFF;13000201=090A0BFF;13000301=77B9EAFF;13000401=77B9EAFF;13000501=77B9EAFF;13000601=5796D5FF;13000701=090A0BFF;14000101=5796D5FF;14000201=5796D5FF;14000301=5796D5FF;14000401=5796D5FF;14000501=5796D5FF;14000601=1B63ABFF;14000701=090A0BFF;15000101=090A0BFF;15000201=090A0BFF;15000301=090A0BFF;15000401=090A0BFF;15000501=090A0BFF;15000601=090A0BFF;15000701=FFFFFF00;16000101=FFFFFF00;16000201=FFFFFF00;16000301=FFFFFF00;16000401=FFFFFF00;16000501=FFFFFF00;16000601=FFFFFF00;16000701=FFFFFF00"

    local schematicID = storage.weditNextID or 1
    storage.weditNextID = schematicID + 1

    if not storage.weditSchematics then storage.weditSchematics = {} end
    storage.weditSchematics[schematicID] = { id = schematicID, copy = copy }

    local params = AssetHelper.oreParameters("WE_Schematic", "^yellow;Primary Fire: Paste Schematic.", "^orange;WEdit: Schematic " .. schematicID, icon, "essential")
    params.wedit = { schematicID = schematicID }

    world.spawnItem("triangliumore", mcontroller.position(), 1, params)
  end
end

--- Function to paste the schematic tied to this schematic item.
-- The link is made through a schematicID, since storing the copy in the actual item causes massive lag.
function wedit.actions.WE_Schematic()
  controller.info("^shadow;^orange;WEdit: Schematic")
  controller.info("^shadow;^yellow;Primary Fire: Paste Schematic.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: DELETE Schematic.", {0,-2})
  controller.info("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-3})

  if not storage.weditSchematics then return end

  local schematicID = controller.itemData and controller.itemData.schematicID
  local schematic
  local storageSchematicKey

  for i,v in pairs(storage.weditSchematics) do
    if v.id == schematicID then
      schematic = v.copy
      storageSchematicKey = i
      break
    end
  end

  if SelectionHelper.isValid() and schematicID and schematic then
    local top = SelectionHelper.getStart()[2] + schematic.size[2]
    DebugRenderer.instance:drawRectangle(SelectionHelper.getStart(), {SelectionHelper.getStart()[1] + schematic.size[1], top}, "cyan")

    if top == SelectionHelper.getEnd()[2] then top = SelectionHelper.getEnd()[2] + 1 end
    DebugRenderer.instance:drawText("^shadow;WEdit Schematic Paste Area", {SelectionHelper.getStart()[1], top}, "cyan")
  else
    controller.info("^shadow;^yellow;No schematic found! Did you delete it?", {0,-4})
  end

  if InputHelper.primary and SelectionHelper.isValid() and not InputHelper.isLocked() and schematic then
    InputHelper.lock()

    local position = {SelectionHelper.getStart()[1], SelectionHelper.getStart()[2]}
    local backup = StampHelper.paste(schematic, position)
    if backup then table.insert(controller.backup, backup) end
  elseif InputHelper.alt and not InputHelper.isLocked() and schematic then
    storage.weditSchematics[storageSchematicKey] = nil
  end
end

--- Function to replace blocks within the selection with another one.
-- Two actions; one to replace all existing blocks and one to replace the block type aimed at.
function wedit.actions.WE_Replace()
  local fgTile, bgTile = world.material(tech.aimPosition(), "foreground"), world.material(tech.aimPosition(), "background")

  controller.info("^shadow;^orange;WEdit: Replace Tool")
  controller.info("^shadow;^yellow;Primary Fire: Replace in foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Replace in background.", {0,-2})
  controller.info("^shadow;^yellow;Shift + Fire: Replace ALL blocks in layer.", {0,-3})
  controller.info("^shadow;^yellow;Replace Block: ^red;" .. Palette.getMaterialName(fgTile) .. "^yellow; / ^red;" .. Palette.getMaterialName(bgTile), {0,-4})
  controller.info("^shadow;^yellow;Replace With: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-5})

  if not InputHelper.isShiftLocked() and SelectionHelper.isValid() then
    local layer = InputHelper.primary and "foreground" or InputHelper.alt and "background" or nil
    local tile = layer == "foreground" and fgTile or layer == "background" and bgTile or nil
    if not tile and not InputHelper.shift then return end -- To replace air, use fill tool.

    if layer then
      InputHelper.shiftLock()
      BlockHelper.replace(SelectionHelper.selection, layer, Palette.getMaterial(), not InputHelper.shift and tile)
      --local backup = wedit.replace(SelectionHelper.getStart(), SelectionHelper.getEnd(), layer, controller.selectedBlock, not InputHelper.shift and tile)
      --if backup then table.insert(controller.backup, backup) end
    end
  end
end

--- Function to add modifications to terrain (matmods).
function wedit.actions.WE_Modifier()
  local mod = Palette.getMod()

  controller.info("^shadow;^orange;WEdit: Modifier")
  controller.info("^shadow;^yellow;Primary Fire: Modify foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Modify background.", {0,-2})
  controller.info("^shadow;^yellow;Shift + Fire: Select mod.", {0,-3})
  controller.info("^shadow;^yellow;Current Mod: ^red;" .. mod .. "^yellow;.", {0,-4})

  DebugRenderer.instance:drawBlock(tech.aimPosition())

  if InputHelper.shift then
    if not InputHelper.isShiftLocked() and (InputHelper.primary or InputHelper.alt) then
      require "/interface/wedit/matmodPicker/matmodPickerLoader.lua"
      matmodPickerLoader.initializeConfig()
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", matmodPickerLoader.config)
      InputHelper.shiftLock()
    end
  elseif not InputHelper.isShiftLocked() then
    if InputHelper.primary then
      wedit.placeMod(tech.aimPosition(), "foreground", mod)
    elseif InputHelper.alt then
      wedit.placeMod(tech.aimPosition(), "background", mod)
    end
  end
end

--- Function to remove modifications from terrain (matmods).
function wedit.actions.WE_ModRemover()
  controller.info("^shadow;^orange;WEdit: MatMod Remover")
  controller.info("^shadow;^yellow;Primary Fire: Remove from foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Remove from background.", {0,-2})

  DebugRenderer.instance:drawBlock(tech.aimPosition())

  if not InputHelper.isLocked() then
    if InputHelper.primary then
      wedit.removeMod(tech.aimPosition(), "foreground")
    elseif InputHelper.alt then
      wedit.removeMod(tech.aimPosition(), "background")
    end
  end
end

--- Function to spawn a tool similar to the Modifier, dedicated to a single selected material mod.
function wedit.actions.WE_ModPinner()
  controller.info("^shadow;^orange;WEdit: MatMod Pinner")
  controller.info("^shadow;^yellow;Primary Fire: Pin foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Pin background.", {0,-2})

  DebugRenderer.instance:drawBlock(tech.aimPosition())

  local fg, bg = world.mod(tech.aimPosition(), "foreground"), world.mod(tech.aimPosition(), "background")
  if fg then
    controller.info("^shadow;^yellow;Foreground Mod: ^red;" .. fg .. "^yellow;.", {0,-3})
  else
    controller.info("^shadow;^yellow;Foreground Mod: ^red;None^yellow;.", {0,-3})
  end
  if bg then
    controller.info("^shadow;^yellow;Background Mod: ^red;" .. bg .. "^yellow;.", {0,-4})
  else
    controller.info("^shadow;^yellow;Background Mod: ^red;None^yellow;.", {0,-4})
  end

  if not InputHelper.isLocked() then
    if InputHelper.primary or InputHelper.alt then
      InputHelper.lock()
      local mod = InputHelper.primary and fg or InputHelper.alt and bg
      if not mod then return end

      local path = "/tiles/mods/"
      local icon = root.assetJson(path .. mod .. ".matmod").renderParameters.texture .. "?crop=0;0;16;16"
      icon = AssetHelper.fixPath(path, icon)

      local params = AssetHelper.oreParameters("WE_Mod", "^yellow;Primary Fire: Modify foreground.\nAlt Fire: Modify background.", "^orange;WEdit: " .. mod .. " MatMod", icon, "essential")
      params.wedit = { mod = mod }

      world.spawnItem("triangliumore", mcontroller.position(), 1, params)
    end
  end
end

--- Function to add the material modification of the item under the cursor like the Modifier tool.
-- Uses the configured brush type and matmod brush size.
function wedit.actions.WE_Mod()
  controller.info("^shadow;^orange;WEdit: Modifier")
  controller.info("^shadow;^yellow;Primary Fire: Modify foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Modify background.", {0,-2})

  local itemData = controller.itemData
  if itemData and itemData.mod then
    controller.info("^shadow;^yellow;Mat Mod: ^red;" .. itemData.mod .. "^yellow;.", {0,-3})
  else
    controller.info("^shadow;^yellow;Mat Mod: ^red;None^yellow;.", {0,-3})
  end

  local debugCallback = function(pos)
    DebugRenderer.instance:drawBlock(pos)
  end

  local layer = InputHelper.primary and "foreground" or
    InputHelper.alt and "background" or nil

  local callback
  if layer then
    callback = function(pos)
      debugCallback(pos)
      wedit.placeMod(pos, layer, itemData.mod)
    end
  else
    callback = debugCallback
  end

  if wedit.getUserConfigData("brushShape") == "square" then
    shapes.rectangle(tech.aimPosition(), wedit.getUserConfigData("matmodSize"), nil, callback)
  elseif wedit.getUserConfigData("brushShape") == "circle" then
    shapes.circle(tech.aimPosition(), wedit.getUserConfigData("matmodSize"), callback)
  end
end

wedit.ruler = {}
--- Function to draw a line of blocks between two selected points
function wedit.actions.WE_Ruler()
  controller.info("^shadow;^orange;WEdit: Ruler")
  controller.info("^shadow;^yellow;Primary Fire: Fill foreground.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Fill background.", {0,-2})
  controller.info("^shadow;^yellow;Shift + Primary Fire: Create line.", {0,-3})
  controller.info("^shadow;^yellow;Shift + Alt Fire: Clear line.", {0,-4})
  controller.info("^shadow;^yellow;Current Block: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-5})

  local line = controller.lineSelection

  -- Draw line
  if not wedit.ruler.selecting and InputHelper.shift and InputHelper.primary and not InputHelper.isShiftLocked() then
    InputHelper.shiftLock()

    -- Set first point
    line[1] = tech.aimPosition()
    line[2] = {}

    -- Start selecting second point
    wedit.ruler.selecting = true
    wedit.ruler.bindA = Bind.create("primaryFire", function()
      -- Dragging selection; update second point.
      line[2] = tech.aimPosition()

      -- Round each value down.
      line[1][1] = math.floor(line[1][1])
      line[2][1] = math.floor(line[2][1])
      line[1][2] = math.floor(line[1][2])
      line[2][2] = math.floor(line[2][2])
    end, true)
    wedit.ruler.bindB = Bind.create("primaryFire=false", function()
      wedit.ruler.bindA:unbind()
      wedit.ruler.bindA = nil
      wedit.ruler.bindB:unbind()
      wedit.ruler.bindB = nil
      wedit.ruler.selecting = false
    end)
  end

  -- Fill / Clear line
  if not InputHelper.isShiftLocked() and not wedit.ruler.selecting then
    if InputHelper.shift and InputHelper.alt then
      -- Clear line
      InputHelper.shiftLock()
      controller.lineSelection = {{},{}}
    elseif not InputHelper.shift then
      -- Fill line
      local layer = InputHelper.primary and "foreground" or InputHelper.alt and "background" or nil
      if layer and controller.validLine() then
        InputHelper.shiftLock()
        wedit.line(line[1], line[2], InputHelper.primary and "foreground" or "background", Palette.getMaterialName())
      end
    end
  end

  -- Draw information
  if controller.validLine() then
    -- Draw boxes around every block in the current selection.
    shapes.line(line[1], line[2],
    function(x, y)
      world.debugLine({x, y}, {x + 1, y}, "green")
      world.debugLine({x, y + 1}, {x + 1, y + 1}, "green")
      world.debugLine({x, y}, {x, y + 1}, "green")
      world.debugLine({x + 1, y}, {x + 1, y + 1}, "green")
    end)

    -- Calculate line length for display
    local w, h = math.abs(line[1][1] - line[2][1]) + 1, math.abs(line[1][2] - line[2][2]) + 1
    local length = w > h and w or h
    controller.info("^shadow;^yellow;Current Length: ^red;" .. length .. " ^yellow;blocks ^red;(" .. w .. "x" .. h .. ")^yellow;.", {0,-6})
  end
end

--- Function to remove all liquid(s) in the selection.
function wedit.actions.WE_Dehydrator()
  controller.info("^shadow;^orange;WEdit: Dehydrator")
  controller.info("^shadow;^yellow;Primary Fire: Dehydrate selection.", {0,-1})

  if not InputHelper.isLocked() and InputHelper.primary and SelectionHelper.isValid() then
    InputHelper.lock()
    wedit.drain(SelectionHelper.getStart(), SelectionHelper.getEnd())
  end
end

--- Function to fill the selection with a liquid.
function wedit.actions.WE_Hydrator()
  controller.info("^shadow;^orange;WEdit: Hydrator")
  controller.info("^shadow;^yellow;Primary Fire: Fill selection.", {0,-1})
  controller.info("^shadow;^yellow;Alt Fire: Select liquid.", {0,-2})
  controller.info("^shadow;^yellow;Current Liquid: ^red;" .. Palette.getLiquid().name .. "^yellow;.", {0,-3})

  if not InputHelper.isLocked() then
    if InputHelper.primary and SelectionHelper.isValid() then
      wedit.hydrate(SelectionHelper.getStart(), SelectionHelper.getEnd(), Palette.getLiquid().liquidId)
      InputHelper.lock()
    elseif InputHelper.alt then
      require "/interface/wedit/liquidPicker/liquidPickerLoader.lua"
      liquidPickerLoader.initializeConfig()
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", liquidPickerLoader.config)
      InputHelper.lock()
    end
  end
end
