local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")

local function Fill()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Paint Bucket")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Fills air in the current selection with the selected block.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: background.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Current Block: ^red;" .. Palette.getMaterialName() .. "^yellow;.", {0,-4})

  if InputHelper.isLocked() or not SelectionHelper.isValid() then return end
  if InputHelper.primary or InputHelper.alt then
    InputHelper.lock()
    local sel = SelectionHelper.get()
    local layer = InputHelper.primary and "foreground" or "background"
    BackupHelper.backup(StampHelper.copy(sel))
    BlockHelper.fill(SelectionHelper.get(), layer, Palette.getMaterial())
  end
end

module = {
  action = Fill
}
