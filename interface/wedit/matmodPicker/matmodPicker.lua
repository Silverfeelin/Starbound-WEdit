require "/interface/wedit/matmodPicker/matmodPickerUtil.lua"

local wMods = "modScroll.mods"
-- Matmod name -> radioGroup index.
local modIndices = {
  aegisalt = -1, aliengrass = 0, alpinegrass = 1, aridgrass = 2, ash = 3, blackash = 4,
  bone = 5, ceilingslimegrass = 6, ceilingsnow = 7, charredgrass = 8, coal = 9, colourfulgrass = 10,
  copper = 11, corefragment = 12, crystal = 13, crystalgrass = 14, diamond = 15, durasteel = 16,
  erchius = 17, ferozium = 18, fleshgrass = 19, flowerygrass = 20, gold = 21, grass = 22,
  heckgrass = 23, hiveceilinggrass = 24, hivegrass = 25, iron = 26, junglegrass = 27, lead = 28,
  metal = 29, meteordust = 30, moonstone = 31, moss = 32, platinum = 33, plutonium = 34,
  prisilite = 35, roots = 36, sand = 37, savannahgrass = 38, silver = 39, slimegrass = 40,
  snow = 41, snowygrass = 42, solarium = 43, sulphur = 44, tar = 45, tarceiling = 46,
  tentaclegrass = 47, thickgrass = 48, tilled = 49, tilleddry = 50, titanium = 51, toxicgrass = 52,
  trianglium = 53, tungsten = 54, undergrowth = 55, uranium = 56, veingrowth = 57,  violium = 58
}

function init()
  -- Prevent multiples matmod pickers.
  -- If the value is somehow true while the interface is closed, a reload should fix this.
  -- weditController.lua forces them back to false on init.
  if status.statusProperty("wedit.matmodPicker.open") then
    forceClosed = true
    pane.dismiss()
  end

  status.setStatusProperty("wedit.matmodPicker.open", true)
  loadSerializedMod()
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.matmodPicker.open", nil)
  end
end

function pickMod(w, data)
  matmodPickerUtil.serializeMod(data)
end

function loadSerializedMod()
  local mod = matmodPickerUtil.getSerializedMod()
  local index = modIndices[mod] or -1
  widget.setSelectedOption(wMods, index)
end