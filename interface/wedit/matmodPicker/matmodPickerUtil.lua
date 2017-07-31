local serializationKey = "wedit.matmodPicker.mod"
local defaultMod = "grass"

matmodPickerUtil = {}

--- Retrieves the name of the serialized matmod.
-- If no mod is serialized (nil), defaultMod will be used.
-- @return Lowercase matmod name.
function matmodPickerUtil.getSerializedMod()
  return status.statusProperty(serializationKey) or defaultMod
end

--- Serializes the matmod name.
-- @param mod Case insensitive name of the matmod, or nil.
function matmodPickerUtil.serializeMod(mod)
  local mType = type(mod)
  if mType == "string" then
    mod = mod:lower()
  else
    mod = nil
  end
  status.setStatusProperty(serializationKey, mod)
end