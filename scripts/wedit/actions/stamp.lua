require "/scripts/wedit/libs/scriptHooks.lua"

local Rectangle = include("/scripts/wedit/objects/shapes/rectangle.lua")

local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")

local data = {
  selection = {{},{}},
  rawSelection = {}
}

local function Stamp()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Stamp Tool")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Copy selection.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Paste selection.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Shift + Primary Fire: Forget copy.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-4})

  if InputHelper.isShiftLocked() then return end
  if not InputHelper.shift then
    if not SelectionHelper.isValid() then return end
    if InputHelper.primary then
      InputHelper.shiftLock()
      storage.wedit_copy = StampHelper.copy(SelectionHelper.get(), nil, true)
    elseif InputHelper.alt and storage.wedit_copy then
      InputHelper.shiftLock()
      BackupHelper.backup(StampHelper.copy(SelectionHelper.get()))
      StampHelper.paste(storage.wedit_copy, SelectionHelper.getStart())
    end
  elseif InputHelper.primary then
    storage.wedit_copy = nil
    InputHelper.shiftLock()
  end
end

module = {
  action = Stamp,
  data = data
}

hook("update", function()
  if not SelectionHelper.isValid() then return end
  if not storage.wedit_copy or not storage.wedit_copy.size then return end
  -- Draw stamp selection
  local copy = storage.wedit_copy
  local top = SelectionHelper.getStart()[2] + copy.size[2] - 1
  DebugRenderer.instance:drawRectangle(SelectionHelper.getStart(), {SelectionHelper.getStart()[1] + copy.size[1] - 1, top}, "cyan")
  if top == SelectionHelper.getEnd()[2] then top = top + 1 end
  DebugRenderer.instance:drawText(string.format("^shadow;WEdit Paste Selection (%sx%s)", copy.size[1], copy.size[2]), {SelectionHelper.getStart()[1], top + 1}, "cyan")
end)
