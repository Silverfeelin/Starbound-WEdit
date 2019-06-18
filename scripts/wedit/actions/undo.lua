local BlockHelper = include("/scripts/wedit/helpers/blockHelper.lua")
local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")

local function Undo()
  local backupSize = #BackupHelper.backups
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Undo Tool (EXPERIMENTAL)")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Undoes previous action (Fill, Break, Paste, Replace).", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Undo last action.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Forget last undo (go back a step).", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Undo Count: " .. backupSize .. ".", {0,-4})

  if backupSize == 0 then return end

  -- Show undo area.
  local backup = BackupHelper.peek()
  local top = backup.origin[2] + backup.size[2] - 2
  if SelectionHelper.isValid() and math.floor(SelectionHelper.getEnd()[2]) == math.floor(top) then top = top - 1 end
  DebugRenderer.instance:drawText("^shadow;WEdit Undo Position", {backup.origin[1], top + 1}, "#FFBF87")
  DebugRenderer.instance:drawRectangle(backup.origin, {backup.origin[1] + backup.size[1] - 1, backup.origin[2] + backup.size[2] - 1}, "#FFBF87")

  -- Actions
  if InputHelper.isLocked() then return end
  if InputHelper.primary then
    InputHelper.lock()
    StampHelper.paste(BackupHelper.peek(), backup.origin)
  elseif InputHelper.alt then
    InputHelper.lock()
    BackupHelper.pop()
  end
end

module = {
  action = Undo
}
