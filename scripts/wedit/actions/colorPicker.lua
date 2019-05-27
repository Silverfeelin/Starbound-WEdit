local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")

local function ColorPicker()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Color Picker")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Select a block.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: background.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Fire: Open material picker.", {0,-4})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Block: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-5})

  DebugRenderer.instance:drawBlock(tech.aimPosition())
  if InputHelper.shift then
    if not InputHelper.isShiftLocked() and (InputHelper.primary or InputHelper.alt) then
      require "/interface/wedit/materialPicker/materialPickerLoader.lua"
      materialPickerLoader.initializeConfig()
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", materialPickerLoader.config)
      InputHelper.shiftLock()
    end
  elseif not InputHelper.isShiftLocked() then
    if InputHelper.primary or InputHelper.alt then
      Palette.fromWorld(InputHelper.primary and "foreground" or "background")
    end
  end
end

module = {
  action = ColorPicker
}
