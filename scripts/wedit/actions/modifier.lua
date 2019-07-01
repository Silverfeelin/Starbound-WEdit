local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local ModHelper = include("/scripts/wedit/helpers/modHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")

local function Modifier()
  local mod = Palette.getMod()
  local modName = Palette.getModName(mod)

  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Modifier")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Modify foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Modify background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Fire: Select mod.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Mod: ^red;" .. modName .. "^yellow;.", {0,-4})

  DebugRenderer.instance:drawBlock(tech.aimPosition())

  if InputHelper.shift then
    if not InputHelper.isShiftLocked() and (InputHelper.primary or InputHelper.alt) then
      require "/interface/wedit/matmodPicker/matmodPickerLoader.lua"
      matmodPickerLoader.initializeConfig()
      world.sendEntityMessage(entity.id(), "interact", "ScriptPane", matmodPickerLoader.config)
      InputHelper.shiftLock()
    end
  elseif not InputHelper.isShiftLocked() then
    local p = mod and ModHelper.place or ModHelper.remove
    local l = InputHelper.primary and "foreground" or InputHelper.alt and "background" or nil
    if l then
      p(tech.aimPosition(), l, mod)
    end
  end
end

module = {
  action = Modifier
}