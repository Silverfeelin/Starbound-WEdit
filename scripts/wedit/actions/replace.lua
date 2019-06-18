local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")

local function Replace()
  local fgTile, bgTile = world.material(tech.aimPosition(), "foreground"), world.material(tech.aimPosition(), "background")

  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Replace Tool")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Replace in foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Replace in background.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Fire: Replace ALL blocks in layer.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Replace Block: ^red;" .. Palette.getMaterialName(fgTile) .. "^yellow; / ^red;" .. Palette.getMaterialName(bgTile), {0,-4})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Replace With: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-5})

  if InputHelper.isShiftLocked() or not SelectionHelper.isValid() then return end
  local layer = InputHelper.primary and "foreground" or InputHelper.alt and "background" or nil
  if not layer then return end
  local tile = layer == "foreground" and fgTile or layer == "background" and bgTile or nil
  if not tile and not InputHelper.shift then return end -- To replace air, use fill tool.

  InputHelper.shiftLock()
  BackupHelper.backup(StampHelper.copy(SelectionHelper.get()))
  BlockHelper.replace(SelectionHelper.selection, layer, Palette.getMaterial(), not InputHelper.shift and tile)
end

module = {
  action = Replace
}
