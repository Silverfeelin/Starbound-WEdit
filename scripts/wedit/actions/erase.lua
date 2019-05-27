local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")

local function Erase()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Eraser")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Erase all blocks in the current selection.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: foreground.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: background.", {0,-3})

  if InputHelper.isLocked() or not SelectionHelper.isValid() then return end
  if InputHelper.primary or InputHelper.alt then
    InputHelper.lock()
    BackupHelper.backup(StampHelper.copy(SelectionHelper.get()))
    BlockHelper.clear(SelectionHelper.get(), InputHelper.primary and "foreground" or "background")
  end
end

module = {
  action = Erase
}
