liquidPickerLoader = {}

local x, y, i
local used = {}
liquidPickerLoader.initialized = false

function liquidPickerLoader.initializeConfig()
  if liquidPickerLoader.initialized then return end
  liquidPickerLoader.initialized = true

  liquidPickerLoader.config = root.assetJson("/interface/wedit/liquidPicker/liquidPicker.config")

  local liquids = root.assetJson("/interface/wedit/liquidPicker/liquids.json")

  x, y, i = 0, -19, 0

  for _,v in ipairs(liquids) do
    liquidPickerLoader.addLiquid(v)
  end
end

function liquidPickerLoader.addLiquid(liquid)
  if used[liquid.liquidId] then return end
  used[liquid.liquidId] = true

  local button = {
    type = "button",
		base = "/interface/wedit/liquidPicker/liquids/" .. liquid.buttonImage,
		hover = "/interface/wedit/liquidPicker/liquids/" .. liquid.buttonImage .. "?brightness=15",
		pressedOffset = {0, -1},
    position = {x, y},
    data = { name = liquid.name, liquidId = liquid.liquidId },
		callback = "pickLiquid"
  }

  liquidPickerLoader.config.gui.liquidScroll.children[tostring(liquid.liquidId)] = button
  liquidPickerLoader.config.gui.liquidScroll.children.a2.position[2] = y

  liquidPickerLoader.nextPosition()
end

function liquidPickerLoader.nextPosition()
  i = i + 1
  if i > 3 then
    y = y - 26
    i = 0
  end

  x = i * 26
end