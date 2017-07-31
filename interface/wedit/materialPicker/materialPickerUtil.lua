materialPickerUtil  = {}

local x, y, i
local used = {}
materialPickerUtil.initialized = false

function materialPickerUtil.initializeConfig()
  if materialPickerUtil.initialized then return end
  materialPickerUtil.initialized = true

  materialPickerUtil.config = root.assetJson("/interface/wedit/materialPicker/materialPicker.config")

  local materials = root.assetJson("/interface/wedit/materialPicker/materials.json")
  local platforms = root.assetJson("/interface/wedit/materialPicker/platforms.json")

  x, y, i = 0, -19, 0

  materialPickerUtil.addAir()

  for _,v in ipairs(materials) do
    materialPickerUtil.addMaterial(v)
  end

  for _,v in ipairs(platforms) do
    materialPickerUtil.addMaterial(v)
  end

end

function materialPickerUtil.addMaterial(material)
  if used[material.name] then return end
  used[material.name] = true

  local button = {
		type = "button",
		base = "/interface/wedit/materialPicker/materials/" .. material.buttonImage,
		hover = "/interface/wedit/materialPicker/materials/" .. material.buttonImage .. "?brightness=15",
		pressedOffset = {0, -1},
    position = {x, y},
    data = material.name,
		callback = "pickMaterial"
	}

  materialPickerUtil.config.gui.materialScroll.children[material.name] = button
  materialPickerUtil.config.gui.materialScroll.children.a2.position[2] = y

  materialPickerUtil.nextPosition()
end

function materialPickerUtil.addAir()
  local button = {
		type = "button",
		base = "/interface/wedit/materialPicker/materials/air.png",
		hover = "/interface/wedit/materialPicker/materials/air.png?brightness=15",
		pressedOffset = {0, -1},
    position = {x, y},
    data = false,
		callback = "pickMaterial"
	}

  materialPickerUtil.config.gui.materialScroll.children["air"] = button
  materialPickerUtil.config.gui.materialScroll.children.a2.position[2] = y

  materialPickerUtil.nextPosition()
end

function materialPickerUtil.nextPosition()
  i = i + 1
  if i > 9 then
    y = y - 22
    i = 0
  end

  x = i * 22
end