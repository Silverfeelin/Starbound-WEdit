require "/interface/wedit/huePicker/huePickerUtil.lua"

local BrushHelper = include("/scripts/wedit/helpers/BrushHelper.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local shapes = include("/scripts/wedit/shapes.lua")

local function Dye()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Dye Tool")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Dye foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Dye background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Fire: Open Hue Picker.", {0,-3})

  local layer = InputHelper.primary and "foreground" or
    InputHelper.alt and "background" or nil

  local hue = huePickerUtil.getSerializedHue() or 0

  if InputHelper.shift then
    if not InputHelper.isShiftLocked() and (InputHelper.primary or InputHelper.alt) then
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", "/interface/wedit/huePicker/huePicker.config")
      InputHelper.shiftLock()
    end
  elseif not InputHelper.isShiftLocked() then
    local callback = function(pos)
        DebugRenderer.instance:drawBlock(pos)
        if layer then
          BlockHelper.place(pos, layer, world.material(pos, layer), hue)
        end
    end

    local shape = BrushHelper.getShape()
    local size = BrushHelper.getBlockSize()

    if brush == "square" then
      shapes.box(tech.aimPosition(), size, nil, callback)
    elseif brush == "circle" then
      shapes.circle(tech.aimPosition(), size, callback)
    end
  end
end

module = {
  action = Dye
}
