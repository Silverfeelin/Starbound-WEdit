local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local LiquidHelper = include("/scripts/wedit/helpers/liquidHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

local function Hydrator()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Hydrator")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Fill selection.", {0, -1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Select liquid.", {0, -2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Liquid: ^red;" .. Palette.getLiquid().name .. "^yellow;.", {0, -3})

  if not InputHelper.isLocked() then
    if InputHelper.primary and SelectionHelper.isValid() then
      LiquidHelper.fill(SelectionHelper.get(), Palette.getLiquid().liquidId)
      InputHelper.lock()
    elseif InputHelper.alt then
      require "/interface/wedit/liquidPicker/liquidPickerLoader.lua"
      liquidPickerLoader.initializeConfig()
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", liquidPickerLoader.config)
      InputHelper.lock()
    end
  end
end

module = {
  action = Hydrator
}