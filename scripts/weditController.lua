--[[
  WEdit library (http://silvermods.com/WEdit/)

  To load this script, it has to be required -inside- the init function of a base tech script (EG. distortionsphere.lua).
  To use this script, the chosen base tech has to be active on your character. Further usage instructions can be found on the official page linked above.

  Hit ALT + 0 in NP++ to fold all, and get an overview of the contents of this script.
]]

require "/scripts/wedit.lua"
require "/scripts/keybinds.lua"

--[[
  Controller table, variables accessed with 'weditController.' are stored here..
]]
weditController = { }

if not root.getConfigurationPath("wedit") then root.setConfigurationPath("wedit", {}) end
-- Retrieve parameters stored in the starbound.config.
-- The parameters are set by the WEdit Interface for MUI.
function weditController.setConfigData(key, value)
  root.setConfigurationPath("wedit." .. key, value)
end
function weditController.getConfigData(key)
  return root.getConfigurationPath("wedit." .. key)
end

--- Noclip parameters.
weditController.useNoclip = true
-- Default noclip status (on tech selection or character load)
weditController.noclipping = false

-- Indices for selected materials, used by the Modifier and Hydrator.
weditController.modIndex = 1
weditController.liquidIndex = 1

-- Variables used to determine if LMB and/or RMB are held down this tick.
weditController.primaryFire, weditController.altFire = false, false
weditController.fireLock = false

-- Number used by WE_Select to determine the selection stage (0: Nothing, 1: Selecting).
weditController.selectStage = 0
-- Table used to store the current raw selection coordinates.
-- [1] Start selection or nil, [2] End selection or nil.
weditController.rawSelection = {}
-- Table used to store the current selection coordinates, converted to block coordinates.
-- [1] Bottom left corner of selection, [2] Top right corner of selection.
weditController.selection = {{},{}}

weditController.lineStage = 0
weditController.line = {{},{}}

-- String used to determine what layer the Eraser, Color Picker, Paint Bucket and Pencil affect.
weditController.layer = "foreground"

-- String used to hold the block used by the Pencil and Paint Bucket
weditController.selectedBlock = "dirt"

-- Table used to store copies of areas prior to commands such as fill.
weditController.backup = {}

-- Table used to display information in certain colors. { title & operations, description, variables }
weditController.colors = { "^orange;", "^yellow;", "^red;"}
wedit.colors = weditController.colors

-- Table used to store the coordinates at which to display the config interface.
weditController.configLocation = {}
storage.weditCopy = storage.weditCopy or nil

weditController.lastUpdate = os.clock()

----------------------------------------
--          Useful functions          --
-- Primary for use within this script --
----------------------------------------

--[[
  Returns the currently selected matmod.
  @return - Selected matmod.
]]
function weditController.getSelectedMod()
  return wedit.mods[weditController.modIndex]
end

--[[
  Returns the currently selected block for displaying purposes (false = air, nil = none)
  @return - Block name, where non-strings are converted for displaying.
]]
function weditController.selectedBlockToString()
  if weditController.selectedBlock == nil then
    return "none"
  elseif weditController.selectedBlock == false then
    return "air"
  else
    return weditController.selectedBlock
  end
end

--[[
  Sets the selected block to the one under the cursor, on the given layer.
  @param [layer] - Layer to select block from. Defaults to
  weditController.layer.
  @return - Tile or false.
]]
function weditController.updateColor(layer)

  if type(layer) ~= "string" then layer = weditController.layer end

  local tile = world.material(tech.aimPosition(), layer)
  if tile then
    weditController.selectedBlock = tile
  else
    weditController.selectedBlock = false
  end

  return tile or false
end

--[[
  Returns a value indicating whether there's currently a valid selection.
  Does this by confirming both the bottom left and top right point are set.
]]
function weditController.validSelection()
  return next(weditController.selection[1]) and next(weditController.selection[2]) and true or false
end

function weditController.updateUserConfig(initializing)
  if initializing or weditController.getConfigData("updateConfig") then
    weditController.setConfigData("updateConfig", false)

    if weditController.getConfigData("clearSchematics") then
      storage.weditSchematics = {}
      weditController.setConfigData("clearSchematics", false)
    end

    wedit.user.lineSpacing = weditController.getConfigData("lineSpacing") or wedit.config.lineSpacing
    wedit.user.delay = weditController.getConfigData("iterationDelay") or wedit.config.iterationDelay
    wedit.user.doubleIterations = weditController.getConfigData("doubleIterations") or wedit.config.doubleIterations
    wedit.user.brushShape = weditController.getConfigData("brushShape") or wedit.config.brushShape
    wedit.user.pencilSize = weditController.getConfigData("pencilSize") or wedit.config.pencilSize
    wedit.user.blockSize = weditController.getConfigData("blockSize") or wedit.config.blockSize
    wedit.user.matmodSize = weditController.getConfigData("matmodSize") or wedit.config.matmodSize

    -- Bind can be any Keybinds compatible bind string.
    weditController.noclipBind = weditController.getConfigData("noclipBind") or wedit.config.noclipBind
    -- Movement speed per tick, in blocks.
    weditController.noclipSpeed = weditController.getConfigData("noclipSpeed") or wedit.config.noclipSpeed
  end
end

-- Run it once before the first update.
weditController.updateUserConfig(true)

---------------------
-- Update Callback --
---------------------

--[[
  Update function, called in the main update callback.
]]
function weditController.update(args)
  -- Update parameters every 2.5 seconds
  local clock = os.clock()
  if clock > weditController.lastUpdate + 1 then
    weditController.lastUpdate = clock
    weditController.updateUserConfig()
  end

  -- Check if LMB / RMB are held down this game tick.
  weditController.primaryFire = args.moves["primaryFire"]
  weditController.altFire = args.moves["altFire"]

  if weditController.noclipping then
    mcontroller.controlParameters({
      gravityEnabled = false,
      collisionEnabled = false,
      standingPoly = {},
      crouchingPoly = {},
      mass = 0,
      runSpeed = 0,
      walkSpeed = 0
    })
    wedit.setLogMap("Noclip", string.format("Press '%s' to stop flying.", weditController.noclipBind))
  else
    wedit.setLogMap("Noclip", string.format("Press '%s' to fly.", weditController.noclipBind))
  end
  -- Removes the lock on your fire keys (LMB/RMB) if both have been released.
  if weditController.fireLock and not weditController.primaryFire and not weditController.altFire then
    weditController.fireLock = false
  end

  -- As all WEdit items are two handed, we only have to check the primary item.
  local primaryItem = world.entityHandItemDescriptor(entity.id(), "primary")
  local primaryType = nil
  if primaryItem and primaryItem.parameters and primaryItem.parameters.shortdescription then primaryType = primaryItem.parameters.shortdescription end

  -- Run the function bound to the short description of the held item.
  if primaryType and type(weditController[primaryType]) == "function" then
    weditController.itemData = primaryItem.parameters.wedit
    weditController[primaryType]()
  end

  -- Draw selections if they have been made.
  if weditController.validSelection() then
    wedit.debugRectangle(weditController.selection[1], weditController.selection[2])
    wedit.debugText(string.format("^shadow;WEdit Selection (%s,%s)", weditController.selection[2][1] - weditController.selection[1][1], weditController.selection[2][2] - weditController.selection[1][2]), {weditController.selection[1][1], weditController.selection[2][2]}, "green")

    if storage.weditCopy and storage.weditCopy.size and (primaryType == "WE_Select" or primaryType == "WE_Stamp") then
      local copy = storage.weditCopy
      local top = weditController.selection[1][2] + copy.size[2]
      wedit.debugRectangle(weditController.selection[1], {weditController.selection[1][1] + copy.size[1], top}, "cyan")

      if top == weditController.selection[2][2] then top = weditController.selection[2][2] + 1 end
      wedit.debugText("^shadow;WEdit Paste Selection", {weditController.selection[1][1], top}, "cyan")
    end
  end
end

-- Set up noclip using Keybinds.
Bind.create(weditController.noclipBind, function()
  weditController.noclipping = not weditController.noclipping
  if weditController.noclipping then
    tech.setParentState("fly")
    for i,v in ipairs(weditController.noclipBinds) do
      v:rebind()
    end
  else
    tech.setParentState()
    for i,v in ipairs(weditController.noclipBinds) do
      v:unbind()
    end
  end
end)

local adjustPosition = function(offset)
  local pos = mcontroller.position()
  mcontroller.setPosition({pos[1] + offset[1], pos[2] + offset[2]})
end
weditController.noclipBinds = {}
table.insert(weditController.noclipBinds, Bind.create("up", function() adjustPosition({0,weditController.noclipSpeed}) end, true))
table.insert(weditController.noclipBinds, Bind.create("down", function() adjustPosition({0,-weditController.noclipSpeed}) end, true))
table.insert(weditController.noclipBinds, Bind.create("left", function() adjustPosition({-weditController.noclipSpeed,0}) end, true))
table.insert(weditController.noclipBinds, Bind.create("right", function() adjustPosition({weditController.noclipSpeed,0}) end, true))
for i,v in ipairs(weditController.noclipBinds) do
  v:unbind()
end

-- Alter update callback.
local oldUpdate = update
update = function(args)
  oldUpdate(args)
  weditController.update(args)
end

-----------------
-- WEdit Tools --
-----------------

--[[
  Sets or updates the selection area.
]]
function weditController.WE_Select()
  wedit.info("^shadow;^orange;WEdit: Selection Tool")

  if weditController.validSelection() then
    wedit.info("^shadow;^yellow;Alt Fire: Remove selection.", {0,-2})
    wedit.info("^shadow;^yellow;Current Selection: ^red;(" .. (weditController.selection[2][1] - weditController.selection[1][1]) .. "," .. (weditController.selection[2][2] - weditController.selection[1][2]) .. ")^yellow;.", {0,-3})
  end

  -- RMB resets selection entirely
  if not weditController.fireLock and weditController.altFire then
    weditController.fireLock = true
    weditController.selectStage = 0
    weditController.selection = {{},{}}
    return
  end

  if weditController.selectStage == 0 then
    -- Select stage 0: Not selecting.
    wedit.info("^shadow;^yellow;Primary Fire: Select area.", {0,-1})

    if weditController.primaryFire then
      -- Start selection; set first point.
      weditController.selectStage = 1
      weditController.rawSelection[1] = tech.aimPosition()
    end

  elseif weditController.selectStage == 1 then
  wedit.info("^shadow;^yellow;Drag mouse and let go to select an area.", {0,-1})
    -- Select stage 1: Selection started.
    if weditController.primaryFire then
      -- Dragging selection; update second point.
      weditController.rawSelection[2] = tech.aimPosition()

      -- Update converted coördinates.
      -- Compare X (1 is smallest):
      weditController.selection[1][1] = math.floor((weditController.rawSelection[1][1] <  weditController.rawSelection[2][1]) and weditController.rawSelection[1][1] or weditController.rawSelection[2][1])
      weditController.selection[2][1] = math.ceil((weditController.rawSelection[1][1] <  weditController.rawSelection[2][1]) and weditController.rawSelection[2][1] or weditController.rawSelection[1][1])

      -- Compare Y (1 is smallest):
      weditController.selection[1][2] = math.floor((weditController.rawSelection[1][2] <  weditController.rawSelection[2][2]) and weditController.rawSelection[1][2] or weditController.rawSelection[2][2])
      weditController.selection[2][2] = math.ceil((weditController.rawSelection[1][2] <  weditController.rawSelection[2][2]) and weditController.rawSelection[2][2] or weditController.rawSelection[1][2])
    else
      -- Selection ended; reset stage.
      weditController.selectStage = 0

      -- We can forget about the raw coördinates now.
      weditController.rawSelection = {}
    end
  else
    -- Select stage is not valid; reset it.
    weditController.selectStage = 0
  end
end

--[[
  Function to set weditController.layer.
]]
function weditController.WE_Layer()
  wedit.info("^shadow;^orange;WEdit: Layer Tool")
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: background", {0,-2})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. weditController.layer .. "^yellow;.", {0,-3})

  if not weditController.fireLock and (weditController.primaryFire or weditController.altFire) then
    -- Prioritizes LMB over RMB.
    weditController.layer = (weditController.primaryFire and "foreground") or (weditController.altFire and "background") or weditController.layer

    -- Prevents repeats until mouse buttons no longer held.
    weditController.fireLock = true
  end
end

--[[
  Function to erase all blocks in the current selection.
  Only targets weditController.layer
]]
function weditController.WE_Erase()
  wedit.info("^shadow;^orange;WEdit: Eraser")
  wedit.info("^shadow;^yellow;Erase all blocks in the current selection.", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: background.", {0,-3})

  if not weditController.fireLock and weditController.validSelection() then
    if weditController.primaryFire then
      -- Remove Foreground
      weditController.fireLock = true
      local backup = wedit.breakBlocks(weditController.selection[1], weditController.selection[2], "foreground")

      if backup then table.insert(weditController.backup, backup) end

    elseif weditController.altFire then
      -- Remove Background
      weditController.fireLock = true
      local backup = wedit.breakBlocks(weditController.selection[1], weditController.selection[2], "background")

      if backup then table.insert(weditController.backup, backup) end
    end
  end
end

--[[
  Function to undo the previous Fill or Erase action.
  LMB Undoes the last remembered action. RMB removes the last remembered action, allowing for multiple undo steps.
]]
function weditController.WE_Undo()
  local backupSize = #weditController.backup
  wedit.info("^shadow;^orange;WEdit: Undo Tool (EXPERIMENTAL)")
  wedit.info("^shadow;^yellow;Undoes previous action (Fill, Break, Paste, Replace).", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: Undo last action.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: Forget last undo (go back a step).", {0,-3})
  wedit.info("^shadow;^yellow;Undo Count: " .. backupSize .. ".", {0,-4})

  -- Show undo area.
  if backupSize > 0 then
    local backup = weditController.backup[backupSize]
    local top = backup.origin[2] + backup.size[2]
    if weditController.validSelection() and math.ceil(weditController.selection[2][2]) == math.ceil(top) then top = top + 1 end
    wedit.debugText("^shadow;WEdit Undo Position", {backup.origin[1], top}, "#FFBF87")
    wedit.debugRectangle(backup.origin, {backup.origin[1] + backup.size[1], backup.origin[2] + backup.size[2]}, "#FFBF87")
  end

  -- Actions
  if not weditController.fireLock then
    if weditController.primaryFire then
      -- Undo
      weditController.fireLock = true
      if backupSize > 0 then
        wedit.paste(weditController.backup[backupSize], weditController.backup[backupSize].origin)
      end
    elseif weditController.altFire then
      -- Remove Undo
      weditController.fireLock = true
      if backupSize > 0 then
        table.remove(weditController.backup, backupSize)
      end
    end
  end
end

--[[
  Function to select a block to be used by tools such as the Pencil or the Paint Bucket.
]]
function weditController.WE_ColorPicker()
  wedit.info("^shadow;^orange;WEdit: Color Picker")
  wedit.info("^shadow;^yellow;Select a block for certain tools.", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: background.", {0,-3})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. weditController.selectedBlockToString() .. "^yellow;.", {0,-4})

  if weditController.primaryFire then
    weditController.fireLock = true
    weditController.updateColor("foreground")
  elseif weditController.altFire then
    weditController.fireLock = true
    weditController.updateColor("background")
  end
end

--[[
  Function to fill the crurent selection with the selected block.
  Only targets weditController.layer
]]
function weditController.WE_Fill()
  wedit.info("^shadow;^orange;WEdit: Paint Bucket")
  wedit.info("^shadow;^yellow;Fills air in the current selection with the selected block.", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: background.", {0,-3})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. weditController.selectedBlockToString() .. "^yellow;.", {0,-4})

  if not weditController.fireLock and weditController.validSelection() then
    if weditController.primaryFire then
      weditController.fireLock = true

      local backup = wedit.fillBlocks(weditController.selection[1], weditController.selection[2], "foreground", weditController.selectedBlock)

      if backup then table.insert(weditController.backup, backup) end
    elseif weditController.altFire then
      weditController.fireLock = true

      local backup = wedit.fillBlocks(weditController.selection[1], weditController.selection[2], "background", weditController.selectedBlock)

      if backup then table.insert(weditController.backup, backup) end
    end
  end
end

--[[
  Function to draw the selected block under the cursor. Existing blocks will be replaced.
  Uses the configured brush type and pencil brush size.
  Only targets weditController.layer
]]
function weditController.WE_Pencil()
  wedit.info("^shadow;^orange;WEdit: Pencil")
  wedit.info("^shadow;^yellow;Primary Fire: Draw on foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Draw on background.", {0,-2})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. weditController.selectedBlockToString() .. "^yellow;.", {0,-3})

  local debugCallback = function(pos)
    wedit.debugBlock(pos)
  end

  local layer = weditController.primaryFire and "foreground" or
    weditController.altFire and "background" or nil

  local callback
  if weditController.selectedBlock ~= nil and layer then
    callback = function(pos)
      debugCallback(pos)
      wedit.pencil(pos, layer, weditController.selectedBlock)
    end
  else
    callback = debugCallback
  end

  if wedit.config.brushShape == "square" then
    wedit.rectangle(tech.aimPosition(), wedit.config.pencilSize, nil, callback)
  elseif wedit.config.brushShape == "circle" then
    wedit.circle(tech.aimPosition(), wedit.config.pencilSize, callback)
  end
end

--[[
  Function to spawn a tool similar to the Pencil, dedicated to a single selected block.
]]
function weditController.WE_BlockPinner()
  wedit.info("^shadow;^orange;WEdit: Block Pinner")
  wedit.info("^shadow;^yellow;Primary Fire: Pin foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Pin background.", {0,-2})
  local fg, bg = world.material(tech.aimPosition(), "foreground"), world.material(tech.aimPosition(), "background")
  if fg then
    wedit.info("^shadow;^yellow;Foreground Block: ^red;" .. fg .. "^yellow;.", {0,-3})
  else
    wedit.info("^shadow;^yellow;Foreground Block: ^red;None^yellow;.", {0,-3})
  end
  if bg then
    wedit.info("^shadow;^yellow;Background Block: ^red;" .. bg .. "^yellow;.", {0,-4})
  else
    wedit.info("^shadow;^yellow;Background Block: ^red;None^yellow;.", {0,-4})
  end

  if not weditController.fireLock then
    if weditController.primaryFire or weditController.altFire then
      weditController.fireLock = true
      local block = weditController.primaryFire and fg or weditController.altFire and bg
      if type(block) == "nil" then return end

      if type(block) ~= "boolean" then
        local path = "/items/materials/"
        local icon = root.assetJson(path .. block .. ".matitem").inventoryIcon
        icon = fixImagePath(path, icon)

        local params = silverOreParameters("WE_Block", "^yellow;Primary Fire: Place foreground.\nAlt Fire: Place background.", "^orange;WEdit: " .. block .. " Material", icon, "essential")
        params.wedit = { block = block }

        world.spawnItem("silverore", mcontroller.position(), 1, params)
      else
        local params = silverOreParameters("WE_Block", "^yellow;Primary Fire: Remove foreground.\nAlt Fire: Remove background.", "^orange;WEdit: Air", "/assetMissing.png?replace;00000000=ffffff;ffffff00=ffffff?setcolor=ffffff?scalenearest=1?crop=0;0;16;16?blendmult=/objects/outpost/customsign/signplaceholder.png;0;0?replace;01000101=00000000;01000201=0000000A;01000301=5E00009D;01000401=950000CC;01000501=9E0000CC;01000601=A60000CC;01000701=AE0000CC;01000801=B40000CC;02000101=00000000;02000201=00000017;02000301=7A0000CC;02000401=DC1E2FFF;02000501=DE1C2DFF;02000601=E42536FF;02000701=EC2D3EFF;02000801=F23546FF;03000101=00000000;03000201=0000001A;03000301=7A0000CC;03000401=D81325FF;03000501=D50015FF;03000601=DB0019FF;03000701=E3001CFF;03000801=E90020FF;04000101=00000000;04000201=0000001A;04000301=7A0000CC;04000401=D81325FF;04000501=D50015FF;04000601=DB0019FF;04000701=E3001CFF;04000801=E90020FF;05000101=00000000;05000201=0000001A;05000301=7A0000CC;05000401=D81325FF;05000501=D50015FF;05000601=DB0019FF;05000701=E3001CFF;05000801=E90020FF;06000101=00000000;06000201=0000001A;06000301=7A0000CC;06000401=D81325FF;06000501=D50015FF;06000601=DB0019FF;06000701=E3001CFF;06000801=E90020FF;07000101=00000000;07000201=00000027;07000301=7A0000CC;07000401=D81325FF;07000501=D50015FF;07000601=DB0019FF;07000701=E3001CFF;07000801=E90020FF;08000101=0000001A;08000201=0E4200A6;08000301=533B00CC;08000401=654100CC;08000501=6D4600CC;08000601=754A00CC;08000701=7C4E00CC;08000801=825200CC;09000101=0000001A;09000201=105500CC;09000301=79BD35FF;09000401=7BBF37FF;09000501=7FC33BFF;09000601=82C63EFF;09000701=86CA42FF;09000801=88CC44FF;10000101=0000001A;10000201=105500CC;10000301=87CB43FF;10000401=86CA42FF;10000501=8CCF48FF;10000601=91D54DFF;10000701=95D951FF;10000801=A9ED65FF;11000101=0000001A;11000201=105500CC;11000301=82C63EFF;11000401=7BBF37FF;11000501=7FC33BFF;11000601=82C63EFF;11000701=86CA42FF;11000801=A9ED65FF;12000101=0000001A;12000201=105500CC;12000301=82C63EFF;12000401=7BBF37FF;12000501=7FC33BFF;12000601=82C63EFF;12000701=86CA42FF;12000801=A9ED65FF;13000101=0000001A;13000201=105500CC;13000301=82C63EFF;13000401=7BBF37FF;13000501=7FC33BFF;13000601=82C63EFF;13000701=86CA42FF;13000801=A9ED65FF;14000101=00000017;14000201=105500CC;14000301=87CB43FF;14000401=86CA42FF;14000501=8CCF48FF;14000601=91D54DFF;14000701=95D951FF;14000801=89D341ED;15000101=0000000A;15000201=0E42009D;15000301=2B7500CC;15000401=348100CC;15000501=3C8B00CC;15000601=449400CC;15000701=4A9C00CC;15000801=50A400AE;16000101=00000000;16000201=0C2F0000;16000301=2B750000;16000401=34810000;16000501=3C8B0000;16000601=44940000;16000701=4A9C0000;16000801=50A40000?blendmult=/objects/outpost/customsign/signplaceholder.png;0;-8?replace;01000101=BA0000AE;01000201=BE000048;01000301=BF000000;01000401=BF000000;01000501=BF000000;01000601=60405D00;01000701=0184BF00;01000801=0188C200;02000101=E64B4CED;02000201=BE0000CC;02000301=BF000000;02000401=BF000000;02000501=901E2D00;02000601=017EB900;02000701=0184BF00;02000801=0188C200;03000101=FE7576FF;03000201=BE0000CC;03000301=BF000000;03000401=901C2B00;03000501=0176B100;03000601=017EB900;03000701=0184BF00;03000801=0188C200;04000101=FE7576FF;04000201=BE0000CC;04000301=901A2900;04000401=016EA900;04000501=0176B100;04000601=017EB900;04000701=0184BF00;04000801=0188C200;05000101=A36279FF;05000201=5A3050E6;05000301=0165A1D7;05000401=016EA9D9;05000501=0176B1DB;05000601=017EB9DC;05000701=0184BFBC;05000801=0189C34E;06000101=55507BFF;06000201=32A9DCFF;06000301=32A9DCFF;06000401=38AEE1FF;06000501=3DB4E7FF;06000601=41B8EBFF;06000701=36B2E7F3;06000801=0189C3DE;07000101=55507BFF;07000201=2DA4D7FF;07000301=279ED1FF;07000401=2CA3D6FF;07000501=30A7DAFF;07000601=33AADDFF;07000701=54CBFEFF;07000801=0189C3DE;08000101=284559EF;08000201=2DA4D7FF;08000301=279ED1FF;08000401=2CA3D6FF;08000501=30A7DAFF;08000601=33AADDFF;08000701=54CBFEFF;08000801=0189C3DE;09000101=195D59EF;09000201=2DA4D7FF;09000301=279ED1FF;09000401=2CA3D6FF;09000501=30A7DAFF;09000601=33AADDFF;09000701=54CBFEFF;09000801=0189C3DE;10000101=195D59EF;10000201=32A9DCFF;10000301=32A9DCFF;10000401=624358FF;10000501=86242FFF;10000601=7B475CFF;10000701=36B2E7F3;10000801=0189C3DE;11000101=2B743FE5;11000201=015A97D5;11000301=0165A1D7;11000401=6A131EF7;11000501=F75E5EFF;11000601=8A1621F8;11000701=0184BFBC;11000801=0189C34E;12000101=54A900CC;12000201=40972700;12000301=5A192800;12000401=800000CC;12000501=F75E5EFF;12000601=A70000CC;12000701=80223000;12000801=2C679200;13000101=54A900CC;13000201=55AA0000;13000301=77000000;13000401=800000CC;13000501=F75E5EFF;13000601=A70000CC;13000701=AA000000;13000801=AA000000;14000101=54A900CC;14000201=55AA0000;14000301=77000000;14000401=800000CC;14000501=F75E5EFF;14000601=A70000CC;14000701=AA000000;14000801=AA000000;15000101=54A90048;15000201=55AA0000;15000301=77000000;15000401=800000CC;15000501=F75E5EFF;15000601=A70000CC;15000701=AA000000;15000801=AA000000;16000101=53A80000;16000201=6B550000;16000301=80000000;16000401=84000099;16000501=980000CC;16000601=A6000099;16000701=A7000000;16000801=A7000000", "essential")
        params.wedit = { block = false }

        world.spawnItem("silverore", mcontroller.position(), 1, params)
      end
    end
  end
end

--[[
  Function to draw the block of the item under the cursor like the Pencil tool.
  Uses the configured brush type and block brush size.
  Existing blocks will be replaced.
]]
function weditController.WE_Block()
  wedit.info("^shadow;^orange;WEdit: Material Placer")
  wedit.info("^shadow;^yellow;Primary Fire: Place in foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Place in background.", {0,-2})

  local itemData = weditController.itemData
  if itemData and itemData.block then
    wedit.info("^shadow;^yellow;Material: ^red;" .. itemData.block .. "^yellow;.", {0,-3})
  else
    wedit.info("^shadow;^yellow;Material: ^red;None^yellow;.", {0,-3})
  end

  local debugCallback = function(pos)
    wedit.debugBlock(pos)
  end

  local layer = weditController.primaryFire and "foreground" or
    weditController.altFire and "background" or nil

  local callback
  if weditController.selectedBlock ~= nil and layer then
    callback = function(pos)
      debugCallback(pos)
      wedit.pencil(pos, layer, itemData.block)
    end
  else
    callback = debugCallback
  end

  if wedit.config.brushShape == "square" then
    wedit.rectangle(tech.aimPosition(), wedit.config.blockSize, nil, callback)
  elseif wedit.config.brushShape == "circle" then
    wedit.circle(tech.aimPosition(), wedit.config.blockSize, callback)
  end
end

--[[
  Function to copy and paste a selection elsewhere.
  The pasting is done through weditController.paste, this function just sets the pasting stage to 1 after checking values for validity.
]]
function weditController.WE_Stamp()
  wedit.info("^shadow;^orange;WEdit: Stamp Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Copy selection.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Paste selection.", {0,-2})
  wedit.info("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-3})

  if not weditController.fireLock and weditController.primaryFire and weditController.validSelection() then
    -- Store copy
    storage.weditCopy = wedit.copy(weditController.selection[1], weditController.selection[2], nil, true)
    weditController.fireLock = true
  elseif not weditController.fireLock and weditController.altFire and weditController.validSelection() then
    -- Start paste
    local position = {weditController.selection[1][1], weditController.selection[1][2]}
    local backup = wedit.paste(storage.weditCopy, position)
    if backup then table.insert(weditController.backup, backup) end

    weditController.fireLock = true
  end
end

--[[
  Function to flip the current copy horizontally or vertically.
  Vertical flips may cause issues with objects, matmods and liquids.
  Does not work with Schematics.
]]
function weditController.WE_Flip()
  wedit.info("^shadow;^orange;WEdit: Flip Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Flip copy horizontally.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Flip copy vertically.", {0,-2})
  wedit.info("^shadow;^yellow;Flipping vertically will cause issues with objects, matmods and liquids.", {0,-3})

  local c = storage.weditCopy
  if c then
    local msg = "^shadow;^yellow;Flipped: ^red;"
    local dir = c.flipX and c.flipY and "Horizontally and Vertically"
    or c.flipX and "Horizontally"
    or c.flipY and "Vertically"
    or "None"

    wedit.info(msg .. dir, {0,-4})
  end

  if not weditController.fireLock and weditController.primaryFire then
    weditController.fireLock = true
    if c then
      storage.weditCopy = wedit.flip(storage.weditCopy, "horizontal")
    end
  elseif not weditController.fireLock and weditController.altFire then
    weditController.fireLock = true
    if c then
      storage.weditCopy = wedit.flip(storage.weditCopy, "vertical")
    end
  end
end

--[[
  Function to create a schematic item for the given selection, which
  allows you to paste the selection later.
]]
function weditController.WE_SchematicMaker()
  wedit.info("^shadow;^orange;WEdit: Schematic Maker")
  wedit.info("^shadow;^yellow;Primary Fire: Create Schematic.", {0,-1})

  if not weditController.fireLock and weditController.primaryFire and weditController.validSelection() then
    weditController.fireLock = true

    local copy = wedit.copy(weditController.selection[1], weditController.selection[2], nil, true)

    local icon = "/assetMissing.png?replace;00000000=ffffff;ffffff00=ffffff?setcolor=ffffff?scalenearest=1?crop=0;0;16;15?blendmult=/objects/outpost/customsign/signplaceholder.png;0;0?replace;01000101=FFFFFF00;01000201=FFFFFF00;01000301=090A0BFF;01000401=090A0BFF;01000501=090A0BFF;01000601=090A0BFF;01000701=090A0BFF;01000801=090A0BFF;02000101=FFFFFF00;02000201=090A0BFF;02000301=1B63ABFF;02000401=5796D5FF;02000501=5796D5FF;02000601=5796D5FF;02000701=5796D5FF;02000801=5796D5FF;03000101=FFFFFF00;03000201=090A0BFF;03000301=5796D5FF;03000401=77B9EAFF;03000501=9ED1F7FF;03000601=77B9EAFF;03000701=77B9EAFF;03000801=9ED1F7FF;04000101=FFFFFF00;04000201=090A0BFF;04000301=5796D5FF;04000401=77B9EAFF;04000501=5796D5FF;04000601=77B9EAFF;04000701=090A0BFF;04000801=090A0BFF;05000101=FFFFFF00;05000201=090A0BFF;05000301=5796D5FF;05000401=77B9EAFF;05000501=9ED1F7FF;05000601=090A0BFF;05000701=B1B1B1FF;05000801=B1B1B1FF;06000101=FFFFFF00;06000201=090A0BFF;06000301=5796D5FF;06000401=77B9EAFF;06000501=090A0BFF;06000601=B1B1B1FF;06000701=566EB1FF;06000801=749FC7FF;07000101=FFFFFF00;07000201=090A0BFF;07000301=5796D5FF;07000401=090A0BFF;07000501=B1B1B1FF;07000601=566EB1FF;07000701=CBECF4FF;07000801=CBECF4FF;08000101=FFFFFF00;08000201=090A0BFF;08000301=5796D5FF;08000401=090A0BFF;08000501=B1B1B1FF;08000601=749FC7FF;08000701=CBECF4FF;08000801=CBECF4FF;09000101=FFFFFF00;09000201=090A0BFF;09000301=5796D5FF;09000401=090A0BFF;09000501=B1B1B1FF;09000601=749FC7FF;09000701=9DD7E6FF;09000801=9DD7E6FF;10000101=FFFFFF00;10000201=090A0BFF;10000301=5796D5FF;10000401=090A0BFF;10000501=B1B1B1FF;10000601=566EB1FF;10000701=9DD7E6FF;10000801=9DD7E6FF;11000101=FFFFFF00;11000201=090A0BFF;11000301=5796D5FF;11000401=090A0BFF;11000501=743D23FF;11000601=B1B1B1FF;11000701=566EB1FF;11000801=749FC7FF;12000101=FFFFFF00;12000201=090A0BFF;12000301=090A0BFF;12000401=743D23FF;12000501=8D5834FF;12000601=BD8549FF;12000701=B1B1B1FF;12000801=B1B1B1FF;13000101=FFFFFF00;13000201=090A0BFF;13000301=743D23FF;13000401=8D5834FF;13000501=BD8549FF;13000601=090A0BFF;13000701=090A0BFF;13000801=090A0BFF;14000101=090A0BFF;14000201=743D23FF;14000301=8D5834FF;14000401=BD8549FF;14000501=090A0BFF;14000601=5796D5FF;14000701=5796D5FF;14000801=5796D5FF;15000101=090A0BFF;15000201=743D23FF;15000301=BD8549FF;15000401=090A0BFF;15000501=090A0BFF;15000601=090A0BFF;15000701=090A0BFF;15000801=090A0BFF;16000101=FFFFFF00;16000201=090A0BFF;16000301=090A0BFF;16000401=FFFFFF00;16000501=FFFFFF00;16000601=FFFFFF00;16000701=FFFFFF00;16000801=FFFFFF00?blendmult=/objects/outpost/customsign/signplaceholder.png;0;-8?replace;01000101=090A0BFF;01000201=090A0BFF;01000301=090A0BFF;01000401=090A0BFF;01000501=090A0BFF;01000601=090A0BFF;01000701=FFFFFF00;02000101=5796D5FF;02000201=5796D5FF;02000301=5796D5FF;02000401=5796D5FF;02000501=5796D5FF;02000601=1B63ABFF;02000701=090A0BFF;03000101=77B9EAFF;03000201=9ED1F7FF;03000301=77B9EAFF;03000401=9ED1F7FF;03000501=77B9EAFF;03000601=5796D5FF;03000701=090A0BFF;04000101=090A0BFF;04000201=090A0BFF;04000301=77B9EAFF;04000401=9ED1F7FF;04000501=77B9EAFF;04000601=5796D5FF;04000701=090A0BFF;05000101=B1B1B1FF;05000201=B1B1B1FF;05000301=090A0BFF;05000401=9ED1F7FF;05000501=77B9EAFF;05000601=5796D5FF;05000701=090A0BFF;06000101=749FC7FF;06000201=566EB1FF;06000301=B1B1B1FF;06000401=090A0BFF;06000501=77B9EAFF;06000601=5796D5FF;06000701=090A0BFF;07000101=9DD7E6FF;07000201=9DD7E6FF;07000301=566EB1FF;07000401=B1B1B1FF;07000501=090A0BFF;07000601=5796D5FF;07000701=090A0BFF;08000101=9DD7E6FF;08000201=9DD7E6FF;08000301=749FC7FF;08000401=B1B1B1FF;08000501=090A0BFF;08000601=5796D5FF;08000701=090A0BFF;09000101=9DD7E6FF;09000201=9DD7E6FF;09000301=749FC7FF;09000401=B1B1B1FF;09000501=090A0BFF;09000601=5796D5FF;09000701=090A0BFF;10000101=9DD7E6FF;10000201=9DD7E6FF;10000301=566EB1FF;10000401=B1B1B1FF;10000501=090A0BFF;10000601=5796D5FF;10000701=090A0BFF;11000101=749FC7FF;11000201=566EB1FF;11000301=B1B1B1FF;11000401=090A0BFF;11000501=77B9EAFF;11000601=5796D5FF;11000701=090A0BFF;12000101=B1B1B1FF;12000201=B1B1B1FF;12000301=090A0BFF;12000401=9ED1F7FF;12000501=77B9EAFF;12000601=5796D5FF;12000701=090A0BFF;13000101=090A0BFF;13000201=090A0BFF;13000301=77B9EAFF;13000401=77B9EAFF;13000501=77B9EAFF;13000601=5796D5FF;13000701=090A0BFF;14000101=5796D5FF;14000201=5796D5FF;14000301=5796D5FF;14000401=5796D5FF;14000501=5796D5FF;14000601=1B63ABFF;14000701=090A0BFF;15000101=090A0BFF;15000201=090A0BFF;15000301=090A0BFF;15000401=090A0BFF;15000501=090A0BFF;15000601=090A0BFF;15000701=FFFFFF00;16000101=FFFFFF00;16000201=FFFFFF00;16000301=FFFFFF00;16000401=FFFFFF00;16000501=FFFFFF00;16000601=FFFFFF00;16000701=FFFFFF00"

    local schematicID = storage.weditNextID or 1
    storage.weditNextID = schematicID + 1

    if not storage.weditSchematics then storage.weditSchematics = {} end
    storage.weditSchematics[schematicID] = { id = schematicID, copy = copy }

    local params = silverOreParameters("WE_Schematic", "^yellow;Primary Fire: Paste Schematic.", "^orange;WEdit: Schematic " .. schematicID, icon, "essential")
    params.wedit = { schematicID = schematicID }

    world.spawnItem("silverore", mcontroller.position(), 1, params)
  end
end

--[[
  Function to paste the schematic tied to this schematic item.
  The link is made through a schematicID, since storing the copy
  in the actual item causes massive lag.
  Deleting schematics is possible (to save memory).
]]
function weditController.WE_Schematic()
  wedit.info("^shadow;^orange;WEdit: Schematic")
  wedit.info("^shadow;^yellow;Primary Fire: Paste Schematic.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: DELETE Schematic.", {0,-2})
  wedit.info("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-3})

  if not storage.weditSchematics then return end

  local schematicID = weditController.itemData and weditController.itemData.schematicID
  local schematic
  local storageSchematicKey

  for i,v in pairs(storage.weditSchematics) do
    if v.id == schematicID then
      schematic = v.copy
      storageSchematicKey = i
      goto brk
    end
  end
  ::brk::

  if weditController.validSelection() and schematicID and schematic then
    local top = weditController.selection[1][2] + schematic.size[2]
    wedit.debugRectangle(weditController.selection[1], {weditController.selection[1][1] + schematic.size[1], top}, "cyan")

    if top == weditController.selection[2][2] then top = weditController.selection[2][2] + 1 end
    wedit.debugText("^shadow;WEdit Schematic Paste Area", {weditController.selection[1][1], top}, "cyan")
  else
    wedit.info("^shadow;^yellow;No schematic found! Did you delete it?", {0,-4})
  end

  if weditController.primaryFire and weditController.validSelection() and not weditController.fireLock and schematic then
    weditController.fireLock = true

    local position = {weditController.selection[1][1], weditController.selection[1][2]}
    local backup = wedit.paste(schematic, position)
    if backup then table.insert(weditController.backup, backup) end
  elseif weditController.altFire and not weditController.fireLock and schematic then
    storage.weditSchematics[storageSchematicKey] = nil
  end
end

--[[
  Function to select certain parameters for the tech.
]]
function weditController.WE_Config()
  wedit.info("^shadow;^orange;WEdit: Config Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Select item.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Show or move menu.", {0,-2})

  -- Draw
  if weditController.configLocation and weditController.configLocation[1] then
    wedit.debugText("^shadow;^orange;WEdit Config:", {weditController.configLocation[1], weditController.configLocation[2] - 1})
  end

  -- Actions
  if weditController.altFire then
    weditController.configLocation = tech.aimPosition()
  elseif not weditController.fireLock and weditController.primaryFire and weditController.configLocation and weditController.configLocation[1] then

  end
end

--[[
  Function to replace blocks within the selection with another one.
  Two actions; one to replace all existing blocks and one to replace the block type aimed at.
]]
function weditController.WE_Replace()
  wedit.info("^shadow;^orange;WEdit: Replace Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Replace hovered block.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Replace all blocks.", {0,-2})
  wedit.info("^shadow;^yellow;Replace With: ^red;" .. weditController.selectedBlockToString() .. "^yellow;.", {0,-3})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. weditController.layer .. "^yellow;.", {0,-4})
  local tile = world.material(tech.aimPosition(), weditController.layer)
  if tile then
    wedit.info("^shadow;^yellow;Replace Block: ^red;" .. tile, {0,-5})
  end

  if not weditController.fireLock and weditController.validSelection() then
    if weditController.primaryFire and tile then
      weditController.fireLock = true

      local backup = wedit.replace(weditController.selection[1], weditController.selection[2], weditController.layer, weditController.selectedBlock, tile)
      if backup then table.insert(weditController.backup, backup) end
    elseif weditController.altFire then
      weditController.fireLock = true

      local backup = wedit.replace(weditController.selection[1], weditController.selection[2], weditController.layer, weditController.selectedBlock)
      if backup then table.insert(weditController.backup, backup) end
    end
  end
end

--[[
  Function to add modifications to terrain (matmods).
]]
function weditController.WE_Modifier()
  wedit.info("^shadow;^orange;WEdit: Modifier")
  wedit.info("^shadow;^yellow;Primary Fire: Modify hovered block.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Select next Mod.", {0,-2})
  wedit.info("^shadow;^yellow;Current Mod: ^red;" .. weditController.getSelectedMod() .. "^yellow;.", {0,-3})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. weditController.layer .. "^yellow;.", {0,-4})

  if not weditController.fireLock then
    if weditController.primaryFire then
      wedit.placeMod(tech.aimPosition(), weditController.layer, weditController.getSelectedMod())
    elseif weditController.altFire then
      weditController.fireLock = true
      weditController.modIndex = weditController.modIndex + 1
      if weditController.modIndex > #wedit.mods then weditController.modIndex = 1 end
    end
  end
end

--[[
  Function to remove modifications from terrain (matmods).
]]
function weditController.WE_ModRemover()
  wedit.info("^shadow;^orange;WEdit: MatMod Remover")
  wedit.info("^shadow;^yellow;Primary Fire: Remove from foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Remove from background.", {0,-2})

  if not weditController.fireLock then
    if weditController.primaryFire then
      wedit.removeMod(tech.aimPosition(), "foreground")
    elseif weditController.altFire then
      wedit.removeMod(tech.aimPosition(), "background")
    end
  end
end

--[[
  Function to spawn a tool similar to the Modifier, dedicated to a single selected material mod.
]]
function weditController.WE_ModPinner()
  wedit.info("^shadow;^orange;WEdit: MatMod Pinner")
  wedit.info("^shadow;^yellow;Primary Fire: Pin foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Pin background.", {0,-2})
  local fg, bg = world.mod(tech.aimPosition(), "foreground"), world.mod(tech.aimPosition(), "background")
  if fg then
    wedit.info("^shadow;^yellow;Foreground Mod: ^red;" .. fg .. "^yellow;.", {0,-3})
  else
    wedit.info("^shadow;^yellow;Foreground Mod: ^red;None^yellow;.", {0,-3})
  end
  if bg then
    wedit.info("^shadow;^yellow;Background Mod: ^red;" .. bg .. "^yellow;.", {0,-4})
  else
    wedit.info("^shadow;^yellow;Background Mod: ^red;None^yellow;.", {0,-4})
  end

  if not weditController.fireLock then
    if weditController.primaryFire or weditController.altFire then
      weditController.fireLock = true
      local mod = weditController.primaryFire and fg or weditController.altFire and bg
      if not mod then return end

      local path = "/tiles/mods/"
      local icon = root.assetJson(path .. mod .. ".matmod").renderParameters.texture .. "?crop=0;0;16;16"
      icon = fixImagePath(path, icon)

      local params = silverOreParameters("WE_Mod", "^yellow;Primary Fire: Modify foreground.\nAlt Fire: Modify background.", "^orange;WEdit: " .. mod .. " MatMod", icon, "essential")
      params.wedit = { mod = mod }

      world.spawnItem("silverore", mcontroller.position(), 1, params)
    end
  end
end

--[[
  Function to add the material modification of the item under the cursor like the Modifier tool.
  Uses the configured brush type and matmod brush size.
]]
function weditController.WE_Mod()
  wedit.info("^shadow;^orange;WEdit: Modifier")
  wedit.info("^shadow;^yellow;Primary Fire: Modify foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Modify background.", {0,-2})

  local itemData = weditController.itemData
  if itemData and itemData.mod then
    wedit.info("^shadow;^yellow;Mat Mod: ^red;" .. itemData.mod .. "^yellow;.", {0,-3})
  else
    wedit.info("^shadow;^yellow;Mat Mod: ^red;None^yellow;.", {0,-3})
  end

  local debugCallback = function(pos)
    wedit.debugBlock(pos)
  end

  local layer = weditController.primaryFire and "foreground" or
    weditController.altFire and "background" or nil

  local callback
  if weditController.selectedBlock ~= nil and layer then
    callback = function(pos)
      debugCallback(pos)
      wedit.placeMod(pos, layer, itemData.mod)
    end
  else
    callback = debugCallback
  end

  if wedit.config.brushShape == "square" then
    wedit.rectangle(tech.aimPosition(), wedit.config.matmodSize, nil, callback)
  elseif wedit.config.brushShape == "circle" then
    wedit.circle(tech.aimPosition(), wedit.config.matmodSize, callback)
  end
end

--[[
  Function to draw a line of blocks between two selected points
]]
function weditController.WE_Ruler()
  wedit.info("^shadow;^orange;WEdit: Ruler")
  -- Line x - 1 reserved.
  wedit.info("^shadow;^yellow;Alt Fire: Fill selection.", {0,-2})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. weditController.selectedBlockToString() .. "^yellow;.", {0,-3})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. weditController.layer .. "^yellow;.", {0,-4})

  -- Make selection (similar to WE_Select, but doesn't convert the two points to the bottom left and top right corner).
  if weditController.lineStage == 0 then
    -- Select stage 0: Not selecting.
    wedit.info("^shadow;^yellow;Primary Fire: Create selection.", {0,-1})

    if weditController.primaryFire then
      -- Start selection; set first point.
      weditController.lineStage = 1
      weditController.line[2] = {}
      weditController.line[1] = tech.aimPosition()
    end

  elseif weditController.lineStage == 1 then
  wedit.info("^shadow;^yellow;Drag mouse and let go to finish the selection.", {0,-1})
    -- Select stage 1: Selection started.
    if weditController.primaryFire then
      -- Dragging selection; update second point.
      weditController.line[2] = tech.aimPosition()

      -- Round each value down.
      weditController.line[1][1] = math.floor(weditController.line[1][1])
      weditController.line[2][1] = math.floor(weditController.line[2][1])

      weditController.line[1][2] = math.floor(weditController.line[1][2])
      weditController.line[2][2] = math.floor(weditController.line[2][2])
    else
      -- Selection ended; reset stage to allow next selection.
      weditController.lineStage = 0
    end
  else
    -- Select stage is not valid; reset it.
    weditController.lineStage = 0
  end

  -- Drawing and allowing RMB only works with a valid selection
  if weditController.line[1] and weditController.line[1][1] and weditController.line[2] and weditController.line[2][1] then
    -- Draw boxes around every block in the current selection.
    wedit.bresenham(weditController.line[1], weditController.line[2],
    function(x, y)
      world.debugLine({x, y}, {x + 1, y}, "green")
      world.debugLine({x, y + 1}, {x + 1, y + 1}, "green")
      world.debugLine({x, y}, {x, y + 1}, "green")
      world.debugLine({x + 1, y}, {x + 1, y + 1}, "green")
    end)

    wedit.info("^shadow;^yellow;Current line is indicated with green blocks.", {0,-5})

    -- RMB : Fill selection.
    if not weditController.fireLock and weditController.altFire then
      weditController.fireLock = true
      wedit.line(weditController.line[1], weditController.line[2], weditController.layer, weditController.selectedBlockToString())
    end
  end
end

--[[
  Function to remove all liquid(s) in the selection.
]]
function weditController.WE_Dehydrator()
  wedit.info("^shadow;^orange;WEdit: Dehydrator")
  wedit.info("^shadow;^yellow;Primary Fire: Dehydrate selection.", {0,-1})

  if not weditController.fireLock and weditController.primaryFire and weditController.validSelection() then
    weditController.fireLock = true
    wedit.drain(weditController.selection[1], weditController.selection[2])
  end
end

--[[
  Function to fill the selection with a liquid.
]]
function weditController.WE_Hydrator()
  wedit.info("^shadow;^orange;WEdit: Hydrator")
  wedit.info("^shadow;^yellow;Primary Fire: Fill selection.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Select next Liquid.", {0,-2})
  wedit.info("^shadow;^yellow;Current Liquid: ^red;" .. wedit.liquids[weditController.liquidIndex].name .. "^yellow;.", {0,-3})

 -- Execute
  if not weditController.fireLock and weditController.primaryFire and weditController.validSelection() then
    weditController.fireLock = true
    wedit.hydrate(weditController.selection[1], weditController.selection[2], wedit.liquids[weditController.liquidIndex].id)
  end

  if not weditController.fireLock and weditController.altFire then
    weditController.fireLock = true

    weditController.liquidIndex = weditController.liquidIndex + 1
    if weditController.liquidIndex > #wedit.liquids then weditController.liquidIndex = 1 end
  end
  -- Scroll available liquids
end

--[[
  Function to obtain all WEdit Tools.
  Uses weditController.colors to color the names and descriptions of the tools.
]]
function weditController.WE_ItemBox()
  wedit.info("^shadow;^orange;WEdit: Item Box")
  wedit.info("^shadow;^yellow;Primary Fire: Spawn Tools.", {0,-1})

  if not weditController.fireLock and weditController.primaryFire then
    weditController.fireLock = true

    local items = root.assetJson("/weditItems/items.json")

    for i=1,#items do
      items[i].category = items[i].category:gsub("%^orange;", weditController.colors[1])
      items[i].description = items[i].description:gsub("%^yellow;", weditController.colors[2])
      world.spawnItem("silverore", mcontroller.position(), 1, items[i])
    end
  end
end

--[[
  Returns parameters for a silver ore used for WEdit tools.
  Vanilla parameters such as blueprints and radio messages are removed.
  @param shortDescription - Visual item name, used to identify WEdit functions.
  @param description - Item description displayed in the item tooltip.
  @param category - Item header, displayed below the item shortDescription.
  @param inventoryIcon - Path to an icon. Supports directives.
  @param rarity - Item rarity. Defaults to common.
  @return - Altered item parameters (for a silverore).
]]
function silverOreParameters(shortDescription, description, category, inventoryIcon, rarity)
 rarity = rarity or "common"
  return {
    itemTags = jarray(),
    radioMessagesOnPickup = jarray(),
    learnBlueprintsOnPickup = jarray(),
    twoHanded = true,
    shortdescription = shortDescription,
    category = category,
    description = description,
    inventoryIcon = inventoryIcon,
    rarity = rarity
  }
end

--[[
  Returns a corrected asset path to the given image.
  @param path - Nil or path leading up to the image. Path should end with a /.
  @param image - Absolute asset path or just the file name (including the extension).
  @return - Absolute asset path to the image.
]]
function fixImagePath(path, image)
  return not path and image or image:find("^/") and image or (path .. image):gsub("//", "/")
end

sb.logInfo("WEdit: Loaded!")
