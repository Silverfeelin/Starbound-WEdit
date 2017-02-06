--[[
  WEdit Actions (https://github.com/Silverfeelin/Starbound-WEdit)

  Script used by weditController.lua. Keeps all WEdit actions centralized in one place.
  This script can not be used by itself, as it relies on data defined in or adjusted by wedit.lua and/or weditController.lua.

  Hit ALT + 0 in NP++ to fold all, and get an overview of the contents of this script.
]]

wedit = wedit or {}
wedit.actions = wedit.actions or {}

--[[
  Function that appears to lack functionality, yet mysteriously accomplishes just about everything.
]]
function wedit.actions.WE_AllInOne()
  -- This tool has no code
end

--[[
  Sets or updates the selection area.
]]
function wedit.actions.WE_Select()
  wedit.info("^shadow;^orange;WEdit: Selection Tool")

  if wedit.controller.validSelection() then
    wedit.info("^shadow;^yellow;Alt Fire: Remove selection.", {0,-2})
    local w, h = wedit.controller.selection[2][1] - wedit.controller.selection[1][1], wedit.controller.selection[2][2] - wedit.controller.selection[1][2]
    wedit.info(string.format("^shadow;^yellow;Current Selection: ^red;(%sx%s)^yellow;.", w, h), {0,-3})
  end

  -- RMB resets selection entirely
  if not wedit.controller.fireLocked and wedit.controller.altFire then
    wedit.controller.fireLock()
    wedit.controller.selectStage = 0
    wedit.controller.selection = {{},{}}
    return
  end

  if wedit.controller.selectStage == 0 then
    -- Select stage 0: Not selecting.
    wedit.info("^shadow;^yellow;Primary Fire: Select area.", {0,-1})

    if wedit.controller.primaryFire then
      -- Start selection; set first point.
      wedit.controller.selectStage = 1
      wedit.controller.rawSelection[1] = tech.aimPosition()
    end
  elseif wedit.controller.selectStage == 1 then
  wedit.info("^shadow;^yellow;Drag mouse and let go to select an area.", {0,-1})
    -- Select stage 1: Selection started.
    if wedit.controller.primaryFire then
      -- Dragging selection; update second point.
      wedit.controller.rawSelection[2] = tech.aimPosition()

      -- Update converted coördinates.
      -- Compare X (1 is smallest):
      wedit.controller.selection[1][1] = math.floor((wedit.controller.rawSelection[1][1] <  wedit.controller.rawSelection[2][1]) and wedit.controller.rawSelection[1][1] or wedit.controller.rawSelection[2][1])
      wedit.controller.selection[2][1] = math.ceil((wedit.controller.rawSelection[1][1] <  wedit.controller.rawSelection[2][1]) and wedit.controller.rawSelection[2][1] or wedit.controller.rawSelection[1][1])

      -- Compare Y (1 is smallest):
      wedit.controller.selection[1][2] = math.floor((wedit.controller.rawSelection[1][2] <  wedit.controller.rawSelection[2][2]) and wedit.controller.rawSelection[1][2] or wedit.controller.rawSelection[2][2])
      wedit.controller.selection[2][2] = math.ceil((wedit.controller.rawSelection[1][2] <  wedit.controller.rawSelection[2][2]) and wedit.controller.rawSelection[2][2] or wedit.controller.rawSelection[1][2])
    else
      -- Selection ended; reset stage.
      wedit.controller.selectStage = 0

      -- We can forget about the raw coördinates now.
      wedit.controller.rawSelection = {}
    end
  else
    -- Select stage is not valid; reset it.
    wedit.controller.selectStage = 0
  end
end

--[[
  Function to set wedit.controller.layer.
]]
function wedit.actions.WE_Layer()
  wedit.info("^shadow;^orange;WEdit: Layer Tool")
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: background", {0,-2})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. wedit.controller.layer .. "^yellow;.", {0,-3})

  if not wedit.controller.fireLocked and (wedit.controller.primaryFire or wedit.controller.altFire) then
    -- Prioritizes LMB over RMB.
    wedit.controller.layer = (wedit.controller.primaryFire and "foreground") or (wedit.controller.altFire and "background") or wedit.controller.layer

    -- Prevents repeats until mouse buttons no longer held.
    wedit.controller.fireLock()
  end
end

--[[
  Function to erase all blocks in the current selection.
  Only targets wedit.controller.layer
]]
function wedit.actions.WE_Erase()
  wedit.info("^shadow;^orange;WEdit: Eraser")
  wedit.info("^shadow;^yellow;Erase all blocks in the current selection.", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: background.", {0,-3})

  if not wedit.controller.fireLocked and wedit.controller.validSelection() then
    if wedit.controller.primaryFire then
      -- Remove Foreground
      wedit.controller.fireLock()
      local backup = wedit.breakBlocks(wedit.controller.selection[1], wedit.controller.selection[2], "foreground")

      if backup then table.insert(wedit.controller.backup, backup) end

    elseif wedit.controller.altFire then
      -- Remove Background
      wedit.controller.fireLock()
      local backup = wedit.breakBlocks(wedit.controller.selection[1], wedit.controller.selection[2], "background")

      if backup then table.insert(wedit.controller.backup, backup) end
    end
  end
end

--[[
  Function to undo the previous Fill or Erase action.
  LMB Undoes the last remembered action. RMB removes the last remembered action, allowing for multiple undo steps.
]]
function wedit.actions.WE_Undo()
  local backupSize = #wedit.controller.backup
  wedit.info("^shadow;^orange;WEdit: Undo Tool (EXPERIMENTAL)")
  wedit.info("^shadow;^yellow;Undoes previous action (Fill, Break, Paste, Replace).", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: Undo last action.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: Forget last undo (go back a step).", {0,-3})
  wedit.info("^shadow;^yellow;Undo Count: " .. backupSize .. ".", {0,-4})

  -- Show undo area.
  if backupSize > 0 then
    local backup = wedit.controller.backup[backupSize]
    local top = backup.origin[2] + backup.size[2]
    if wedit.controller.validSelection() and math.ceil(wedit.controller.selection[2][2]) == math.ceil(top) then top = top + 1 end
    wedit.debugText("^shadow;WEdit Undo Position", {backup.origin[1], top}, "#FFBF87")
    wedit.debugRectangle(backup.origin, {backup.origin[1] + backup.size[1], backup.origin[2] + backup.size[2]}, "#FFBF87")
  end

  -- Actions
  if not wedit.controller.fireLocked then
    if wedit.controller.primaryFire then
      -- Undo
      wedit.controller.fireLock()
      if backupSize > 0 then
        wedit.paste(wedit.controller.backup[backupSize], wedit.controller.backup[backupSize].origin)
      end
    elseif wedit.controller.altFire then
      -- Remove Undo
      wedit.controller.fireLock()
      if backupSize > 0 then
        table.remove(wedit.controller.backup, backupSize)
      end
    end
  end
end

--[[
  Function to select a block to be used by tools such as the Pencil or the Paint Bucket.
]]
function wedit.actions.WE_ColorPicker()
  wedit.info("^shadow;^orange;WEdit: Color Picker")
  wedit.info("^shadow;^yellow;Select a block for certain tools.", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: background.", {0,-3})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. wedit.controller.selectedBlockToString() .. "^yellow;.", {0,-4})

  if wedit.controller.primaryFire then
    wedit.controller.fireLock()
    wedit.controller.updateColor("foreground")
  elseif wedit.controller.altFire then
    wedit.controller.fireLock()
    wedit.controller.updateColor("background")
  end
end

--[[
  Function to fill the crurent selection with the selected block.
  Only targets wedit.controller.layer
]]
function wedit.actions.WE_Fill()
  wedit.info("^shadow;^orange;WEdit: Paint Bucket")
  wedit.info("^shadow;^yellow;Fills air in the current selection with the selected block.", {0,-1})
  wedit.info("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  wedit.info("^shadow;^yellow;Alt Fire: background.", {0,-3})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. wedit.controller.selectedBlockToString() .. "^yellow;.", {0,-4})

  if not wedit.controller.fireLocked and wedit.controller.validSelection() then
    if wedit.controller.primaryFire then
      wedit.controller.fireLock()

      local backup = wedit.fillBlocks(wedit.controller.selection[1], wedit.controller.selection[2], "foreground", wedit.controller.selectedBlock)

      if backup then table.insert(wedit.controller.backup, backup) end
    elseif wedit.controller.altFire then
      wedit.controller.fireLock()

      local backup = wedit.fillBlocks(wedit.controller.selection[1], wedit.controller.selection[2], "background", wedit.controller.selectedBlock)

      if backup then table.insert(wedit.controller.backup, backup) end
    end
  end
end

--[[
  Function to draw the selected block under the cursor. Existing blocks will be replaced.
  Uses the configured brush type and pencil brush size.
  Only targets wedit.controller.layer
]]
function wedit.actions.WE_Pencil()
  wedit.info("^shadow;^orange;WEdit: Pencil")
  wedit.info("^shadow;^yellow;Primary Fire: Draw on foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Draw on background.", {0,-2})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. wedit.controller.selectedBlockToString() .. "^yellow;.", {0,-3})

  local debugCallback = function(pos)
    wedit.debugBlock(pos)
  end

  local layer = wedit.controller.primaryFire and "foreground" or
    wedit.controller.altFire and "background" or nil

  local callback
  if wedit.controller.selectedBlock ~= nil and layer then
    callback = function(pos)
      debugCallback(pos)
      wedit.pencil(pos, layer, wedit.controller.selectedBlock)
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
function wedit.actions.WE_BlockPinner()
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

  if not wedit.controller.fireLocked then
    if wedit.controller.primaryFire or wedit.controller.altFire then
      wedit.controller.fireLock()
      local block = wedit.controller.primaryFire and fg or wedit.controller.altFire and bg
      if type(block) == "nil" then return end

      if type(block) ~= "boolean" then
        local path = "/items/materials/"
        local icon = root.assetJson(path .. block .. ".matitem").inventoryIcon
        icon = wedit.controller.fixImagePath(path, icon)

        local params = wedit.controller.spawnOreParameters("WE_Block", "^yellow;Primary Fire: Place foreground.\nAlt Fire: Place background.", "^orange;WEdit: " .. block .. " Material", icon, "essential")
        params.wedit = { block = block }

        world.spawnItem("triangliumore", mcontroller.position(), 1, params)
      else
        local params = wedit.controller.spawnOreParameters("WE_Block", "^yellow;Primary Fire: Remove foreground.\nAlt Fire: Remove background.", "^orange;WEdit: Air", "/assetMissing.png?replace;00000000=ffffff;ffffff00=ffffff?setcolor=ffffff?scalenearest=1?crop=0;0;16;16?blendmult=/objects/outpost/customsign/signplaceholder.png;0;0?replace;01000101=00000000;01000201=0000000A;01000301=5E00009D;01000401=950000CC;01000501=9E0000CC;01000601=A60000CC;01000701=AE0000CC;01000801=B40000CC;02000101=00000000;02000201=00000017;02000301=7A0000CC;02000401=DC1E2FFF;02000501=DE1C2DFF;02000601=E42536FF;02000701=EC2D3EFF;02000801=F23546FF;03000101=00000000;03000201=0000001A;03000301=7A0000CC;03000401=D81325FF;03000501=D50015FF;03000601=DB0019FF;03000701=E3001CFF;03000801=E90020FF;04000101=00000000;04000201=0000001A;04000301=7A0000CC;04000401=D81325FF;04000501=D50015FF;04000601=DB0019FF;04000701=E3001CFF;04000801=E90020FF;05000101=00000000;05000201=0000001A;05000301=7A0000CC;05000401=D81325FF;05000501=D50015FF;05000601=DB0019FF;05000701=E3001CFF;05000801=E90020FF;06000101=00000000;06000201=0000001A;06000301=7A0000CC;06000401=D81325FF;06000501=D50015FF;06000601=DB0019FF;06000701=E3001CFF;06000801=E90020FF;07000101=00000000;07000201=00000027;07000301=7A0000CC;07000401=D81325FF;07000501=D50015FF;07000601=DB0019FF;07000701=E3001CFF;07000801=E90020FF;08000101=0000001A;08000201=0E4200A6;08000301=533B00CC;08000401=654100CC;08000501=6D4600CC;08000601=754A00CC;08000701=7C4E00CC;08000801=825200CC;09000101=0000001A;09000201=105500CC;09000301=79BD35FF;09000401=7BBF37FF;09000501=7FC33BFF;09000601=82C63EFF;09000701=86CA42FF;09000801=88CC44FF;10000101=0000001A;10000201=105500CC;10000301=87CB43FF;10000401=86CA42FF;10000501=8CCF48FF;10000601=91D54DFF;10000701=95D951FF;10000801=A9ED65FF;11000101=0000001A;11000201=105500CC;11000301=82C63EFF;11000401=7BBF37FF;11000501=7FC33BFF;11000601=82C63EFF;11000701=86CA42FF;11000801=A9ED65FF;12000101=0000001A;12000201=105500CC;12000301=82C63EFF;12000401=7BBF37FF;12000501=7FC33BFF;12000601=82C63EFF;12000701=86CA42FF;12000801=A9ED65FF;13000101=0000001A;13000201=105500CC;13000301=82C63EFF;13000401=7BBF37FF;13000501=7FC33BFF;13000601=82C63EFF;13000701=86CA42FF;13000801=A9ED65FF;14000101=00000017;14000201=105500CC;14000301=87CB43FF;14000401=86CA42FF;14000501=8CCF48FF;14000601=91D54DFF;14000701=95D951FF;14000801=89D341ED;15000101=0000000A;15000201=0E42009D;15000301=2B7500CC;15000401=348100CC;15000501=3C8B00CC;15000601=449400CC;15000701=4A9C00CC;15000801=50A400AE;16000101=00000000;16000201=0C2F0000;16000301=2B750000;16000401=34810000;16000501=3C8B0000;16000601=44940000;16000701=4A9C0000;16000801=50A40000?blendmult=/objects/outpost/customsign/signplaceholder.png;0;-8?replace;01000101=BA0000AE;01000201=BE000048;01000301=BF000000;01000401=BF000000;01000501=BF000000;01000601=60405D00;01000701=0184BF00;01000801=0188C200;02000101=E64B4CED;02000201=BE0000CC;02000301=BF000000;02000401=BF000000;02000501=901E2D00;02000601=017EB900;02000701=0184BF00;02000801=0188C200;03000101=FE7576FF;03000201=BE0000CC;03000301=BF000000;03000401=901C2B00;03000501=0176B100;03000601=017EB900;03000701=0184BF00;03000801=0188C200;04000101=FE7576FF;04000201=BE0000CC;04000301=901A2900;04000401=016EA900;04000501=0176B100;04000601=017EB900;04000701=0184BF00;04000801=0188C200;05000101=A36279FF;05000201=5A3050E6;05000301=0165A1D7;05000401=016EA9D9;05000501=0176B1DB;05000601=017EB9DC;05000701=0184BFBC;05000801=0189C34E;06000101=55507BFF;06000201=32A9DCFF;06000301=32A9DCFF;06000401=38AEE1FF;06000501=3DB4E7FF;06000601=41B8EBFF;06000701=36B2E7F3;06000801=0189C3DE;07000101=55507BFF;07000201=2DA4D7FF;07000301=279ED1FF;07000401=2CA3D6FF;07000501=30A7DAFF;07000601=33AADDFF;07000701=54CBFEFF;07000801=0189C3DE;08000101=284559EF;08000201=2DA4D7FF;08000301=279ED1FF;08000401=2CA3D6FF;08000501=30A7DAFF;08000601=33AADDFF;08000701=54CBFEFF;08000801=0189C3DE;09000101=195D59EF;09000201=2DA4D7FF;09000301=279ED1FF;09000401=2CA3D6FF;09000501=30A7DAFF;09000601=33AADDFF;09000701=54CBFEFF;09000801=0189C3DE;10000101=195D59EF;10000201=32A9DCFF;10000301=32A9DCFF;10000401=624358FF;10000501=86242FFF;10000601=7B475CFF;10000701=36B2E7F3;10000801=0189C3DE;11000101=2B743FE5;11000201=015A97D5;11000301=0165A1D7;11000401=6A131EF7;11000501=F75E5EFF;11000601=8A1621F8;11000701=0184BFBC;11000801=0189C34E;12000101=54A900CC;12000201=40972700;12000301=5A192800;12000401=800000CC;12000501=F75E5EFF;12000601=A70000CC;12000701=80223000;12000801=2C679200;13000101=54A900CC;13000201=55AA0000;13000301=77000000;13000401=800000CC;13000501=F75E5EFF;13000601=A70000CC;13000701=AA000000;13000801=AA000000;14000101=54A900CC;14000201=55AA0000;14000301=77000000;14000401=800000CC;14000501=F75E5EFF;14000601=A70000CC;14000701=AA000000;14000801=AA000000;15000101=54A90048;15000201=55AA0000;15000301=77000000;15000401=800000CC;15000501=F75E5EFF;15000601=A70000CC;15000701=AA000000;15000801=AA000000;16000101=53A80000;16000201=6B550000;16000301=80000000;16000401=84000099;16000501=980000CC;16000601=A6000099;16000701=A7000000;16000801=A7000000", "essential")
        params.wedit = { block = false }

        world.spawnItem("triangliumore", mcontroller.position(), 1, params)
      end
    end
  end
end

--[[
  Function to draw the block of the item under the cursor like the Pencil tool.
  Uses the configured brush type and block brush size.
  Existing blocks will be replaced.
]]
function wedit.actions.WE_Block()
  wedit.info("^shadow;^orange;WEdit: Material Placer")
  wedit.info("^shadow;^yellow;Primary Fire: Place in foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Place in background.", {0,-2})

  local itemData = wedit.controller.itemData
  if itemData and itemData.block then
    wedit.info("^shadow;^yellow;Material: ^red;" .. itemData.block .. "^yellow;.", {0,-3})
  else
    wedit.info("^shadow;^yellow;Material: ^red;None^yellow;.", {0,-3})
  end

  local debugCallback = function(pos)
    wedit.debugBlock(pos)
  end

  local layer = wedit.controller.primaryFire and "foreground" or
    wedit.controller.altFire and "background" or nil

  local callback
  if wedit.controller.selectedBlock ~= nil and layer then
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
  The pasting is done through wedit.controller.paste, this function just sets the pasting stage to 1 after checking values for validity.
]]
function wedit.actions.WE_Stamp()
  wedit.info("^shadow;^orange;WEdit: Stamp Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Copy selection.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Paste selection.", {0,-2})
  wedit.info("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-3})

  if wedit.controller.validSelection() then
    wedit.controller.showSelection()
  end

  if not wedit.controller.fireLocked and wedit.controller.primaryFire and wedit.controller.validSelection() then
    -- Store copy
    storage.weditCopy = wedit.copy(wedit.controller.selection[1], wedit.controller.selection[2], nil, true)
    wedit.controller.fireLock()
  elseif not wedit.controller.fireLocked and wedit.controller.altFire and wedit.controller.validSelection() then
    -- Start paste
    local position = {wedit.controller.selection[1][1], wedit.controller.selection[1][2]}
    local backup = wedit.paste(storage.weditCopy, position)
    if backup then table.insert(wedit.controller.backup, backup) end

    wedit.controller.fireLock()
  end
end

--[[
  Function to flip the current copy horizontally or vertically.
  Vertical flips may cause issues with objects, matmods and liquids.
  Does not work with Schematics.
]]
function wedit.actions.WE_Flip()
  wedit.info("^shadow;^orange;WEdit: Flip Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Flip copy horizontally.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Flip copy vertically.", {0,-2})
  wedit.info("^shadow;^yellow;Flipping copies may cause issues with objects, matmods and liquids.", {0,-3})

  local c = storage.weditCopy
  if c then
    local msg = "^shadow;^yellow;Flipped: ^red;"
    local dir = c.flipX and c.flipY and "Horizontally and Vertically"
    or c.flipX and "Horizontally"
    or c.flipY and "Vertically"
    or "None"

    wedit.info(msg .. dir, {0,-4})
  end

  if not wedit.controller.fireLocked and wedit.controller.primaryFire then
    wedit.controller.fireLock()
    if c then
      storage.weditCopy = wedit.flip(storage.weditCopy, "horizontal")
    end
  elseif not wedit.controller.fireLocked and wedit.controller.altFire then
    wedit.controller.fireLock()
    if c then
      storage.weditCopy = wedit.flip(storage.weditCopy, "vertical")
    end
  end
end

--[[
  Function to create a schematic item for the given selection, which
  allows you to paste the selection later.
]]
function wedit.actions.WE_SchematicMaker()
  wedit.info("^shadow;^orange;WEdit: Schematic Maker")
  wedit.info("^shadow;^yellow;Primary Fire: Create Schematic.", {0,-1})

  if not wedit.controller.fireLocked and wedit.controller.primaryFire and wedit.controller.validSelection() then
    wedit.controller.fireLock()

    local copy = wedit.copy(wedit.controller.selection[1], wedit.controller.selection[2], nil, true)

    local icon = "/assetMissing.png?replace;00000000=ffffff;ffffff00=ffffff?setcolor=ffffff?scalenearest=1?crop=0;0;16;15?blendmult=/objects/outpost/customsign/signplaceholder.png;0;0?replace;01000101=FFFFFF00;01000201=FFFFFF00;01000301=090A0BFF;01000401=090A0BFF;01000501=090A0BFF;01000601=090A0BFF;01000701=090A0BFF;01000801=090A0BFF;02000101=FFFFFF00;02000201=090A0BFF;02000301=1B63ABFF;02000401=5796D5FF;02000501=5796D5FF;02000601=5796D5FF;02000701=5796D5FF;02000801=5796D5FF;03000101=FFFFFF00;03000201=090A0BFF;03000301=5796D5FF;03000401=77B9EAFF;03000501=9ED1F7FF;03000601=77B9EAFF;03000701=77B9EAFF;03000801=9ED1F7FF;04000101=FFFFFF00;04000201=090A0BFF;04000301=5796D5FF;04000401=77B9EAFF;04000501=5796D5FF;04000601=77B9EAFF;04000701=090A0BFF;04000801=090A0BFF;05000101=FFFFFF00;05000201=090A0BFF;05000301=5796D5FF;05000401=77B9EAFF;05000501=9ED1F7FF;05000601=090A0BFF;05000701=B1B1B1FF;05000801=B1B1B1FF;06000101=FFFFFF00;06000201=090A0BFF;06000301=5796D5FF;06000401=77B9EAFF;06000501=090A0BFF;06000601=B1B1B1FF;06000701=566EB1FF;06000801=749FC7FF;07000101=FFFFFF00;07000201=090A0BFF;07000301=5796D5FF;07000401=090A0BFF;07000501=B1B1B1FF;07000601=566EB1FF;07000701=CBECF4FF;07000801=CBECF4FF;08000101=FFFFFF00;08000201=090A0BFF;08000301=5796D5FF;08000401=090A0BFF;08000501=B1B1B1FF;08000601=749FC7FF;08000701=CBECF4FF;08000801=CBECF4FF;09000101=FFFFFF00;09000201=090A0BFF;09000301=5796D5FF;09000401=090A0BFF;09000501=B1B1B1FF;09000601=749FC7FF;09000701=9DD7E6FF;09000801=9DD7E6FF;10000101=FFFFFF00;10000201=090A0BFF;10000301=5796D5FF;10000401=090A0BFF;10000501=B1B1B1FF;10000601=566EB1FF;10000701=9DD7E6FF;10000801=9DD7E6FF;11000101=FFFFFF00;11000201=090A0BFF;11000301=5796D5FF;11000401=090A0BFF;11000501=743D23FF;11000601=B1B1B1FF;11000701=566EB1FF;11000801=749FC7FF;12000101=FFFFFF00;12000201=090A0BFF;12000301=090A0BFF;12000401=743D23FF;12000501=8D5834FF;12000601=BD8549FF;12000701=B1B1B1FF;12000801=B1B1B1FF;13000101=FFFFFF00;13000201=090A0BFF;13000301=743D23FF;13000401=8D5834FF;13000501=BD8549FF;13000601=090A0BFF;13000701=090A0BFF;13000801=090A0BFF;14000101=090A0BFF;14000201=743D23FF;14000301=8D5834FF;14000401=BD8549FF;14000501=090A0BFF;14000601=5796D5FF;14000701=5796D5FF;14000801=5796D5FF;15000101=090A0BFF;15000201=743D23FF;15000301=BD8549FF;15000401=090A0BFF;15000501=090A0BFF;15000601=090A0BFF;15000701=090A0BFF;15000801=090A0BFF;16000101=FFFFFF00;16000201=090A0BFF;16000301=090A0BFF;16000401=FFFFFF00;16000501=FFFFFF00;16000601=FFFFFF00;16000701=FFFFFF00;16000801=FFFFFF00?blendmult=/objects/outpost/customsign/signplaceholder.png;0;-8?replace;01000101=090A0BFF;01000201=090A0BFF;01000301=090A0BFF;01000401=090A0BFF;01000501=090A0BFF;01000601=090A0BFF;01000701=FFFFFF00;02000101=5796D5FF;02000201=5796D5FF;02000301=5796D5FF;02000401=5796D5FF;02000501=5796D5FF;02000601=1B63ABFF;02000701=090A0BFF;03000101=77B9EAFF;03000201=9ED1F7FF;03000301=77B9EAFF;03000401=9ED1F7FF;03000501=77B9EAFF;03000601=5796D5FF;03000701=090A0BFF;04000101=090A0BFF;04000201=090A0BFF;04000301=77B9EAFF;04000401=9ED1F7FF;04000501=77B9EAFF;04000601=5796D5FF;04000701=090A0BFF;05000101=B1B1B1FF;05000201=B1B1B1FF;05000301=090A0BFF;05000401=9ED1F7FF;05000501=77B9EAFF;05000601=5796D5FF;05000701=090A0BFF;06000101=749FC7FF;06000201=566EB1FF;06000301=B1B1B1FF;06000401=090A0BFF;06000501=77B9EAFF;06000601=5796D5FF;06000701=090A0BFF;07000101=9DD7E6FF;07000201=9DD7E6FF;07000301=566EB1FF;07000401=B1B1B1FF;07000501=090A0BFF;07000601=5796D5FF;07000701=090A0BFF;08000101=9DD7E6FF;08000201=9DD7E6FF;08000301=749FC7FF;08000401=B1B1B1FF;08000501=090A0BFF;08000601=5796D5FF;08000701=090A0BFF;09000101=9DD7E6FF;09000201=9DD7E6FF;09000301=749FC7FF;09000401=B1B1B1FF;09000501=090A0BFF;09000601=5796D5FF;09000701=090A0BFF;10000101=9DD7E6FF;10000201=9DD7E6FF;10000301=566EB1FF;10000401=B1B1B1FF;10000501=090A0BFF;10000601=5796D5FF;10000701=090A0BFF;11000101=749FC7FF;11000201=566EB1FF;11000301=B1B1B1FF;11000401=090A0BFF;11000501=77B9EAFF;11000601=5796D5FF;11000701=090A0BFF;12000101=B1B1B1FF;12000201=B1B1B1FF;12000301=090A0BFF;12000401=9ED1F7FF;12000501=77B9EAFF;12000601=5796D5FF;12000701=090A0BFF;13000101=090A0BFF;13000201=090A0BFF;13000301=77B9EAFF;13000401=77B9EAFF;13000501=77B9EAFF;13000601=5796D5FF;13000701=090A0BFF;14000101=5796D5FF;14000201=5796D5FF;14000301=5796D5FF;14000401=5796D5FF;14000501=5796D5FF;14000601=1B63ABFF;14000701=090A0BFF;15000101=090A0BFF;15000201=090A0BFF;15000301=090A0BFF;15000401=090A0BFF;15000501=090A0BFF;15000601=090A0BFF;15000701=FFFFFF00;16000101=FFFFFF00;16000201=FFFFFF00;16000301=FFFFFF00;16000401=FFFFFF00;16000501=FFFFFF00;16000601=FFFFFF00;16000701=FFFFFF00"

    local schematicID = storage.weditNextID or 1
    storage.weditNextID = schematicID + 1

    if not storage.weditSchematics then storage.weditSchematics = {} end
    storage.weditSchematics[schematicID] = { id = schematicID, copy = copy }

    local params = wedit.controller.spawnOreParameters("WE_Schematic", "^yellow;Primary Fire: Paste Schematic.", "^orange;WEdit: Schematic " .. schematicID, icon, "essential")
    params.wedit = { schematicID = schematicID }

    world.spawnItem("triangliumore", mcontroller.position(), 1, params)
  end
end

--[[
  Function to paste the schematic tied to this schematic item.
  The link is made through a schematicID, since storing the copy
  in the actual item causes massive lag.
  Deleting schematics is possible (to save memory).
]]
function wedit.actions.WE_Schematic()
  wedit.info("^shadow;^orange;WEdit: Schematic")
  wedit.info("^shadow;^yellow;Primary Fire: Paste Schematic.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: DELETE Schematic.", {0,-2})
  wedit.info("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-3})

  if not storage.weditSchematics then return end

  local schematicID = wedit.controller.itemData and wedit.controller.itemData.schematicID
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

  if wedit.controller.validSelection() and schematicID and schematic then
    local top = wedit.controller.selection[1][2] + schematic.size[2]
    wedit.debugRectangle(wedit.controller.selection[1], {wedit.controller.selection[1][1] + schematic.size[1], top}, "cyan")

    if top == wedit.controller.selection[2][2] then top = wedit.controller.selection[2][2] + 1 end
    wedit.debugText("^shadow;WEdit Schematic Paste Area", {wedit.controller.selection[1][1], top}, "cyan")
  else
    wedit.info("^shadow;^yellow;No schematic found! Did you delete it?", {0,-4})
  end

  if wedit.controller.primaryFire and wedit.controller.validSelection() and not wedit.controller.fireLocked and schematic then
    wedit.controller.fireLock()

    local position = {wedit.controller.selection[1][1], wedit.controller.selection[1][2]}
    local backup = wedit.paste(schematic, position)
    if backup then table.insert(wedit.controller.backup, backup) end
  elseif wedit.controller.altFire and not wedit.controller.fireLocked and schematic then
    storage.weditSchematics[storageSchematicKey] = nil
  end
end

--[[
  Function to select certain parameters for the tech.
]]
function wedit.actions.WE_Config()
  wedit.info("^shadow;^orange;WEdit: Config Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Select item.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Show or move menu.", {0,-2})

  -- Draw
  if wedit.controller.configLocation and wedit.controller.configLocation[1] then
    wedit.debugText("^shadow;^orange;WEdit Config:", {wedit.controller.configLocation[1], wedit.controller.configLocation[2] - 1})
  end

  -- Actions
  if wedit.controller.altFire then
    wedit.controller.configLocation = tech.aimPosition()
  elseif not wedit.controller.fireLocked and wedit.controller.primaryFire and wedit.controller.configLocation and wedit.controller.configLocation[1] then

  end
end

--[[
  Function to replace blocks within the selection with another one.
  Two actions; one to replace all existing blocks and one to replace the block type aimed at.
]]
function wedit.actions.WE_Replace()
  wedit.info("^shadow;^orange;WEdit: Replace Tool")
  wedit.info("^shadow;^yellow;Primary Fire: Replace hovered block.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Replace all blocks.", {0,-2})
  wedit.info("^shadow;^yellow;Replace With: ^red;" .. wedit.controller.selectedBlockToString() .. "^yellow;.", {0,-3})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. wedit.controller.layer .. "^yellow;.", {0,-4})
  local tile = world.material(tech.aimPosition(), wedit.controller.layer)
  if tile then
    wedit.info("^shadow;^yellow;Replace Block: ^red;" .. tile, {0,-5})
  end

  if not wedit.controller.fireLocked and wedit.controller.validSelection() then
    if wedit.controller.primaryFire and tile then
      wedit.controller.fireLock()

      local backup = wedit.replace(wedit.controller.selection[1], wedit.controller.selection[2], wedit.controller.layer, wedit.controller.selectedBlock, tile)
      if backup then table.insert(wedit.controller.backup, backup) end
    elseif wedit.controller.altFire then
      wedit.controller.fireLock()

      local backup = wedit.replace(wedit.controller.selection[1], wedit.controller.selection[2], wedit.controller.layer, wedit.controller.selectedBlock)
      if backup then table.insert(wedit.controller.backup, backup) end
    end
  end
end

--[[
  Function to add modifications to terrain (matmods).
]]
function wedit.actions.WE_Modifier()
  wedit.info("^shadow;^orange;WEdit: Modifier")
  wedit.info("^shadow;^yellow;Primary Fire: Modify hovered block.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Select next Mod.", {0,-2})
  wedit.info("^shadow;^yellow;Current Mod: ^red;" .. wedit.controller.getSelectedMod() .. "^yellow;.", {0,-3})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. wedit.controller.layer .. "^yellow;.", {0,-4})

  if not wedit.controller.fireLocked then
    if wedit.controller.primaryFire then
      wedit.placeMod(tech.aimPosition(), wedit.controller.layer, wedit.controller.getSelectedMod())
    elseif wedit.controller.altFire then
      wedit.controller.fireLock()
      wedit.controller.modIndex = wedit.controller.modIndex + 1
      if wedit.controller.modIndex > #wedit.mods then wedit.controller.modIndex = 1 end
    end
  end
end

--[[
  Function to remove modifications from terrain (matmods).
]]
function wedit.actions.WE_ModRemover()
  wedit.info("^shadow;^orange;WEdit: MatMod Remover")
  wedit.info("^shadow;^yellow;Primary Fire: Remove from foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Remove from background.", {0,-2})

  if not wedit.controller.fireLocked then
    if wedit.controller.primaryFire then
      wedit.removeMod(tech.aimPosition(), "foreground")
    elseif wedit.controller.altFire then
      wedit.removeMod(tech.aimPosition(), "background")
    end
  end
end

--[[
  Function to spawn a tool similar to the Modifier, dedicated to a single selected material mod.
]]
function wedit.actions.WE_ModPinner()
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

  if not wedit.controller.fireLocked then
    if wedit.controller.primaryFire or wedit.controller.altFire then
      wedit.controller.fireLock()
      local mod = wedit.controller.primaryFire and fg or wedit.controller.altFire and bg
      if not mod then return end

      local path = "/tiles/mods/"
      local icon = root.assetJson(path .. mod .. ".matmod").renderParameters.texture .. "?crop=0;0;16;16"
      icon = wedit.controller.fixImagePath(path, icon)

      local params = wedit.controller.spawnOreParameters("WE_Mod", "^yellow;Primary Fire: Modify foreground.\nAlt Fire: Modify background.", "^orange;WEdit: " .. mod .. " MatMod", icon, "essential")
      params.wedit = { mod = mod }

      world.spawnItem("triangliumore", mcontroller.position(), 1, params)
    end
  end
end

--[[
  Function to add the material modification of the item under the cursor like the Modifier tool.
  Uses the configured brush type and matmod brush size.
]]
function wedit.actions.WE_Mod()
  wedit.info("^shadow;^orange;WEdit: Modifier")
  wedit.info("^shadow;^yellow;Primary Fire: Modify foreground.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Modify background.", {0,-2})

  local itemData = wedit.controller.itemData
  if itemData and itemData.mod then
    wedit.info("^shadow;^yellow;Mat Mod: ^red;" .. itemData.mod .. "^yellow;.", {0,-3})
  else
    wedit.info("^shadow;^yellow;Mat Mod: ^red;None^yellow;.", {0,-3})
  end

  local debugCallback = function(pos)
    wedit.debugBlock(pos)
  end

  local layer = wedit.controller.primaryFire and "foreground" or
    wedit.controller.altFire and "background" or nil

  local callback
  if wedit.controller.selectedBlock ~= nil and layer then
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
function wedit.actions.WE_Ruler()
  wedit.info("^shadow;^orange;WEdit: Ruler")
  -- Line x - 1 reserved.
  wedit.info("^shadow;^yellow;Alt Fire: Fill selection.", {0,-2})
  wedit.info("^shadow;^yellow;Current Block: ^red;" .. wedit.controller.selectedBlockToString() .. "^yellow;.", {0,-3})
  wedit.info("^shadow;^yellow;Current Layer: ^red;" .. wedit.controller.layer .. "^yellow;.", {0,-4})

  local line = wedit.controller.line

  -- Make selection (similar to WE_Select, but doesn't convert the two points to the bottom left and top right corner).
  if wedit.controller.lineStage == 0 then
    -- Select stage 0: Not selecting.
    wedit.info("^shadow;^yellow;Primary Fire: Create selection.", {0,-1})

    if wedit.controller.primaryFire then
      -- Start selection; set first point.
      wedit.controller.lineStage = 1
      line[2] = {}
      line[1] = tech.aimPosition()
    end

  elseif wedit.controller.lineStage == 1 then
  wedit.info("^shadow;^yellow;Drag mouse and let go to finish the selection.", {0,-1})
    -- Select stage 1: Selection started.
    if wedit.controller.primaryFire then
      -- Dragging selection; update second point.
      line[2] = tech.aimPosition()

      -- Round each value down.
      line[1][1] = math.floor(line[1][1])
      line[2][1] = math.floor(line[2][1])

      line[1][2] = math.floor(line[1][2])
      line[2][2] = math.floor(line[2][2])
    else
      -- Selection ended; reset stage to allow next selection.
      wedit.controller.lineStage = 0
    end
  else
    -- Select stage is not valid; reset it.
    wedit.controller.lineStage = 0
  end

  -- Drawing and allowing RMB only works with a valid selection
  if line[1] and line[1][1] and line[2] and line[2][1] then
    -- Draw boxes around every block in the current selection.
    wedit.bresenham(line[1], line[2],
    function(x, y)
      world.debugLine({x, y}, {x + 1, y}, "green")
      world.debugLine({x, y + 1}, {x + 1, y + 1}, "green")
      world.debugLine({x, y}, {x, y + 1}, "green")
      world.debugLine({x + 1, y}, {x + 1, y + 1}, "green")
    end)

    -- Calculate line length for display
    local w, h = math.abs(line[1][1] - line[2][1]) + 1, math.abs(line[1][2] - line[2][2]) + 1
    local length = w > h and w or h
    wedit.info("^shadow;^yellow;Current Length: ^red;" .. length .. " ^yellow;blocks ^red;(" .. w .. "x" .. h .. ")^yellow;.", {0,-5})

    -- RMB : Fill selection.
    if not wedit.controller.fireLocked and wedit.controller.altFire then
      wedit.controller.fireLock()
      wedit.line(line[1], line[2], wedit.controller.layer, wedit.controller.selectedBlockToString())
    end
  end
end

--[[
  Function to remove all liquid(s) in the selection.
]]
function wedit.actions.WE_Dehydrator()
  wedit.info("^shadow;^orange;WEdit: Dehydrator")
  wedit.info("^shadow;^yellow;Primary Fire: Dehydrate selection.", {0,-1})

  if not wedit.controller.fireLocked and wedit.controller.primaryFire and wedit.controller.validSelection() then
    wedit.controller.fireLock()
    wedit.drain(wedit.controller.selection[1], wedit.controller.selection[2])
  end
end

--[[
  Function to fill the selection with a liquid.
]]
function wedit.actions.WE_Hydrator()
  wedit.info("^shadow;^orange;WEdit: Hydrator")
  wedit.info("^shadow;^yellow;Primary Fire: Fill selection.", {0,-1})
  wedit.info("^shadow;^yellow;Alt Fire: Select next Liquid.", {0,-2})
  wedit.info("^shadow;^yellow;Current Liquid: ^red;" .. wedit.liquids[wedit.controller.liquidIndex].name .. "^yellow;.", {0,-3})

 -- Execute
  if not wedit.controller.fireLocked and wedit.controller.primaryFire and wedit.controller.validSelection() then
    wedit.controller.fireLock()
    wedit.hydrate(wedit.controller.selection[1], wedit.controller.selection[2], wedit.liquids[wedit.controller.liquidIndex].id)
  end

  if not wedit.controller.fireLocked and wedit.controller.altFire then
    wedit.controller.fireLock()

    wedit.controller.liquidIndex = wedit.controller.liquidIndex + 1
    if wedit.controller.liquidIndex > #wedit.liquids then wedit.controller.liquidIndex = 1 end
  end
  -- Scroll available liquids
end

--[[
  Function to obtain all WEdit Tools.
  Uses wedit.controller.colors to color the names and descriptions of the tools.
]]
function wedit.actions.WE_ItemBox()
  wedit.info("^shadow;^orange;WEdit: Item Box")
  wedit.info("^shadow;^yellow;Primary Fire: Spawn Tools.", {0,-1})

  if not wedit.controller.fireLocked and wedit.controller.primaryFire then
    wedit.controller.fireLock()

    local items = root.assetJson("/wedit/items.json")

    for i=1,#items do
      local item = items[i]
      if item.parameters.category then
        item.parameters.category = item.parameters.category:gsub("%^orange;", wedit.controller.colors[1])
      end
      if item.parameters.description then
        item.parameters.description = item.parameters.description:gsub("%^yellow;", wedit.controller.colors[2])
      end
      world.spawnItem(item, mcontroller.position())
    end
  end
end
