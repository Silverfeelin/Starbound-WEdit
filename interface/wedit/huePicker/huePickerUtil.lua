local serializationKey = "wedit.huePicker.hue"

huePickerUtil = {}

--- Retrieves the serialized color name.
-- If no color is serialized, returns nil.
-- @return Serialized color name, or nil.
function huePickerUtil.getSerializedHue()
  return status.statusProperty(serializationKey)
end

--- Serializes the color naame.
-- @param color Case insensitive name of the color.
function huePickerUtil.serializeHue(hue)
  local t = type(hue)
  if t ~= "number" and t ~= "nil" then error("serializeHue expected a number or nil.") end
  status.setStatusProperty(serializationKey, hue)
end
