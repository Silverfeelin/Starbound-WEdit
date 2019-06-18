local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")
local Logger = include("/scripts/wedit/helpers/logger.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local shapes = include("/scripts/wedit/shapes.lua")

local function Block()
  local itemData = ItemHelper.getItemData()

  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Material Placer")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Place in foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Place in background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Material: ^red;" .. (itemData and itemData.block or "None") .. "^yellow;.", {0,-3})

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
      BlockHelper.place(pos, layer, itemData.block, itemData.hueshift)
    end
  else
    callback = debugCallback
  end

  if wedit.getUserConfigData("brushShape") == "square" then
    shapes.box(tech.aimPosition(), wedit.getUserConfigData("blockSize"), nil, callback)
  elseif wedit.getUserConfigData("brushShape") == "circle" then
    shapes.circle(tech.aimPosition(), wedit.getUserConfigData("blockSize"), callback)
  end
end

module = {
  action = Block
}
