local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local LiquidHelper = include("/scripts/wedit/helpers/liquidHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

local function Hydrator()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Hydrator")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Fill selection.", {0, -1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Clear selection.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Fire: Select liquid.", {0, -3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Liquid: ^red;" .. Palette.getLiquid().name .. "^yellow;.", {0, -4})

  if InputHelper.isLocked() then return end
  

  if InputHelper.shift then
    if not InputHelper.isShiftLocked() and (InputHelper.primary or InputHelper.alt) then
      require "/interface/wedit/liquidPicker/liquidPickerLoader.lua"
      liquidPickerLoader.initializeConfig()
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", liquidPickerLoader.config)
      InputHelper.shiftLock()
    end
  elseif SelectionHelper.isValid() then
    if InputHelper.primary then
      LiquidHelper.fill(SelectionHelper.get(), Palette.getLiquid().liquidId)
      InputHelper.lock()
    elseif InputHelper.alt then
      LiquidHelper.clear(SelectionHelper.get())
      InputHelper.lock()
    end
  end
end

module = {
  action = Hydrator
}
