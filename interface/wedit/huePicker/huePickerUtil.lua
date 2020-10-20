local serializationKey = "wedit.huePicker.hue"

huePickerUtil = {}

--- Retrieves the serialized hue number.
-- If no hue is serialized, returns nil.
-- @return Serialized hue number, or nil.
function huePickerUtil.getSerializedHue()
  return status.statusProperty(serializationKey)
end

--- Serializes the color naame.
-- @param hue Hue number.
function huePickerUtil.serializeHue(hue)
  local t = type(hue)
  if t ~= "number" and t ~= "nil" then error("serializeHue expected a number or nil.") end
  status.setStatusProperty(serializationKey, hue)
end
