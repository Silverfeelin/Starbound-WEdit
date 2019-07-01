matmodPickerLoader = {}

local x, y, i
local used = {}
matmodPickerLoader.initialized = false

function matmodPickerLoader.initializeConfig()
  if matmodPickerLoader.initialized then return end
  matmodPickerLoader.initialized = true

  matmodPickerLoader.config = root.assetJson("/interface/wedit/matmodPicker/matmodPicker.config")

  local mods = root.assetJson("/interface/wedit/matmodPicker/matmods.json")

  x, y, i = 0, 0, 0
  
  matmodPickerLoader.addNone()

  for _,v in ipairs(mods) do
    matmodPickerLoader.addMod(v)
  end
end

function matmodPickerLoader.addMod(mod)
  if used[mod.name] then return end
  used[mod.name] = true

  local button = {
    type = "button",
		base = "/interface/wedit/matmodPicker/mods/" .. mod.buttonImage,
		hover = "/interface/wedit/matmodPicker/mods/" .. mod.buttonImage .. "?brightness=15",
		pressedOffset = {0, -1},
    position = {x, y},
    data = mod.name,
		callback = "pickMod"
  }

  matmodPickerLoader.config.gui.modScroll.children[mod.name] = button
  matmodPickerLoader.config.gui.modScroll.children.a2.position[2] = y

  matmodPickerLoader.nextPosition()
end


function matmodPickerLoader.addNone()
  local button = {
		type = "button",
		base = "/interface/wedit/matmodPicker/mods/none.png",
		hover = "/interface/wedit/matmodPicker/mods/none.png?brightness=15",
		pressedOffset = {0, -1},
    position = {x, y},
    data = false,
		callback = "pickMod"
	}

  matmodPickerLoader.config.gui.modScroll.children["none"] = button
  matmodPickerLoader.config.gui.modScroll.children.a2.position[2] = y

  matmodPickerLoader.nextPosition()
end

function matmodPickerLoader.nextPosition()
  i = i + 1
  if i > 5 then
    y = y - 22
    i = 0
  end

  x = i * 22
end