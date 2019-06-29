local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local BrushHelper = include("/scripts/wedit/helpers/BrushHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local shapes = include("/scripts/wedit/shapes.lua")

local function Pencil()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Pencil")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Draw on foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Draw on background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Block: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-3})
  local hue = huePickerUtil.getSerializedHue() or 0
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Hue: ^red;" .. hue .. "^yellow;.", {0,-4})

  local debugCallback = function(pos)
    DebugRenderer.instance:drawBlock(pos)
  end

  local layer = InputHelper.primary and "foreground" or
    InputHelper.alt and "background" or nil

  local callback
  if Palette.getMaterial() ~= nil and layer then
    callback = function(pos)
      debugCallback(pos)
      BlockHelper.place(pos, layer, Palette.getMaterial(), hue)
    end
  else
    callback = debugCallback
  end

  local shape = BrushHelper.getShape()
  local size = BrushHelper.getPencilSize()
  
  if shape == "square" then
    shapes.box(tech.aimPosition(), size, nil, callback)
  elseif shape == "circle" then
    shapes.circle(tech.aimPosition(), size, callback)
  end
end

module = {
  action = Pencil
}
