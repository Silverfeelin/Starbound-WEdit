--- WEdit Actions (https://github.com/Silverfeelin/Starbound-WEdit)
--
-- Script used by controller.lua. Keeps all WEdit actions centralized in one place.
-- This script can not be used by itself, as it relies on data defined in or adjusted by wedit.lua and/or controller.lua.

require "/interface/wedit/dyePicker/dyePickerUtil.lua"
require "/scripts/wedit/libs/include.lua"
require "/scripts/wedit/libs/keybinds.lua"

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
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")

local Actions = {}
module = Actions

hook("init", function() 
  --- Sets or updates the selection area.
  Actions.WE_AllInOne = include("/scripts/wedit/actions/allInOne.lua")
  Actions.WE_Block = include("/scripts/wedit/actions/block.lua")
  Actions.WE_BlockPinner = include("/scripts/wedit/actions/blockPinner.lua")
  Actions.WE_ColorPicker = include("/scripts/wedit/actions/colorPicker.lua")
  Actions.WE_Dehydrator = include("/scripts/wedit/actions/dehydrator.lua")
  Actions.WE_Dye = include("/scripts/wedit/actions/dye.lua")
  Actions.WE_Erase = include("/scripts/wedit/actions/erase.lua")
  Actions.WE_Fill = include("/scripts/wedit/actions/fill.lua")
  Actions.WE_Flip = include("/scripts/wedit/actions/flip.lua")
  Actions.WE_Hydrator = include("/scripts/wedit/actions/hydrator.lua")
  Actions.WE_Mod = include("/scripts/wedit/actions/mod.lua")
  Actions.WE_Modifier = include("/scripts/wedit/actions/modifier.lua")
  Actions.WE_ModPinner = include("/scripts/wedit/actions/modPinner.lua")
  Actions.WE_ModRemover = include("/scripts/wedit/actions/modRemover.lua")
  Actions.WE_Pencil = include("/scripts/wedit/actions/pencil.lua")
  Actions.WE_Replace = include("/scripts/wedit/actions/replace.lua")
  Actions.WE_SchematicMaker = include("/scripts/wedit/actions/schematicMaker.lua")
  Actions.WE_Schematic = include("/scripts/wedit/actions/schematic.lua")
  Actions.WE_Select = include("/scripts/wedit/actions/select.lua")
  Actions.WE_Stamp = include("/scripts/wedit/actions/stamp.lua")
  Actions.WE_Undo = include("/scripts/wedit/actions/undo.lua")
end)

wedit.ruler = {}
--- Function to draw a line of blocks between two selected points
function Actions.WE_Ruler()
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
