local serializationKey = "wedit.randomPicker.percentage"

randomPickerUtil = {}

--- Retrieves the serialized percentage.
-- @return Serialized percentage, or nil
function randomPickerUtil.getSerializedPercentage()
  return status.statusProperty(serializationKey)
end

--- Serializes the percentage.
-- @param perc Percentage from 0-100.
function randomPickerUtil.serializePercentage(perc)
  local t = type(perc)
  if t ~= "number" and t ~= "nil" then error("serializePercentage expected a number or nil.") end
  status.setStatusProperty(serializationKey, perc)
end
