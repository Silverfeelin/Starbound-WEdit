-- Lookup tables
local colorIndices = { none = 0, red = 1, blue = 2, green = 3, yellow = 4, orange = 5, pink = 6, black = 7, white = 8 }
local colorNames = { [0] = "none", [1] = "red", [2] = "blue", [3] = "green", [4] = "yellow", [5] = "orange", [6] = "pink", [7] = "black", [8] = "white" }

local serializationKey = "wedit.dyePicker.color"

dyePickerUtil = {}
--- Retrieves the color index of a color.
-- This color index can be used by functions such as world.setMaterialColor.
-- The index 0 represents no selected color or an invalid selection.
-- @param color Case insensitive name of the color.
-- @return Color index number.
function dyePickerUtil.getColorIndex(color)
  if type(color) ~= "string" then return 0 end
  return colorIndices[color:lower()] or 0
end

--- Retrieves the color name of a color index.
-- The name "none" represents no color selection.
-- @param index Index of the color.
-- @return Lowercase color name.
function dyePickerUtil.getColorName(index)
  if type(index) ~= "number" then return "none" end
  return colorNames[index] or "none"
end

--- Retrieves the serialized color name.
-- If no color is serialized, returns nil.
-- @return Serialized color name, or nil.
function dyePickerUtil.getSerializedColor()
  return status.statusProperty(serializationKey)
end

--- Serializes the color naame.
-- @param color Case insensitive name of the color.
function dyePickerUtil.serializeColor(color)
  local cType = type(color)
  if cType ~= "string" and cType ~= "nil" then error("setSerializeColor expected a string or nil.") end
  status.setStatusProperty(serializationKey, color and color:lower())
end