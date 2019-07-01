materialPickerLoader  = {}

local x, y, i
local used = {}
materialPickerLoader.initialized = false

function materialPickerLoader.initializeConfig()
  if materialPickerLoader.initialized then return end
  materialPickerLoader.initialized = true

  materialPickerLoader.config = root.assetJson("/interface/wedit/materialPicker/materialPicker.config")

  local materials = root.assetJson("/interface/wedit/materialPicker/materials.json")
  local platforms = root.assetJson("/interface/wedit/materialPicker/platforms.json")

  x, y, i = 0, 0, 0

  materialPickerLoader.addAir()

  for _,v in ipairs(materials) do
    materialPickerLoader.addMaterial(v)
  end

  for _,v in ipairs(platforms) do
    materialPickerLoader.addMaterial(v)
  end

end

function materialPickerLoader.addMaterial(material)
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

  materialPickerLoader.config.gui.materialScroll.children[material.name] = button
  materialPickerLoader.config.gui.materialScroll.children.a2.position[2] = y

  materialPickerLoader.nextPosition()
end

function materialPickerLoader.addAir()
  local button = {
		type = "button",
		base = "/interface/wedit/materialPicker/materials/air.png",
		hover = "/interface/wedit/materialPicker/materials/air.png?brightness=15",
		pressedOffset = {0, -1},
    position = {x, y},
    data = false,
		callback = "pickMaterial"
	}

  materialPickerLoader.config.gui.materialScroll.children["air"] = button
  materialPickerLoader.config.gui.materialScroll.children.a2.position[2] = y

  materialPickerLoader.nextPosition()
end

function materialPickerLoader.nextPosition()
  i = i + 1
  if i > 9 then
    y = y - 22
    i = 0
  end

  x = i * 22
end