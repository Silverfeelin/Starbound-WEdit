local BrushHelper = include("/scripts/wedit/helpers/BrushHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")
local ModHelper = include("/scripts/wedit/helpers/modHelper.lua")
local shapes = include("/scripts/wedit/shapes.lua")

local function Mod()
  local itemData = ItemHelper.getItemData()

  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Modifier")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Modify foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Modify background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Mat Mod: ^red;" .. (itemData and itemData.mod or "None") .. "^yellow;.", {0,-3})

  local debugCallback = function(pos)
    DebugRenderer.instance:drawBlock(pos)
  end

  local layer = InputHelper.primary and "foreground"
    or InputHelper.alt and "background"
    or nil

  local callback
  if layer then
    callback = function(pos)
      debugCallback(pos)
      ModHelper.place(pos, layer, itemData.mod)
    end
  else
    callback = debugCallback
  end

  local shape = BrushHelper.getShape()
  local size = BrushHelper.getModSize()

  if shape == "square" then
    shapes.box(tech.aimPosition(), size, nil, callback)
  elseif shape == "circle" then
    shapes.circle(tech.aimPosition(), size, callback)
  end
end

module = {
  action = Mod
}