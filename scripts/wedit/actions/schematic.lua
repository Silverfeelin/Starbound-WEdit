local BackupHelper = include("/scripts/wedit/helpers/backupHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")
local StampHelper = include("/scripts/wedit/helpers/stampHelper.lua")

--- Function to paste the schematic tied to this schematic item.
-- The link is made through a schematicID, since storing the copy in the actual item causes massive lag.
local function Schematic()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Schematic")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Paste Schematic.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: DELETE Schematic.", {0,-2})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;The paste area is defined by the bottom left point of your selection.", {0,-3})

  if not storage.weditSchematics then return end
  local itemData = ItemHelper.getItemData()
  local schematicID = itemData and itemData.schematicID
  local schematic
  local storageSchematicKey

  for i,v in pairs(storage.weditSchematics) do
    if v.id == schematicID then
      schematic = v.copy
      storageSchematicKey = i
      break
    end
  end

  if SelectionHelper.isValid() and schematicID and schematic then
    local top = SelectionHelper.getStart()[2] + schematic.size[2] - 1
    DebugRenderer.instance:drawRectangle(SelectionHelper.getStart(), {SelectionHelper.getStart()[1] + schematic.size[1] - 1, top}, "cyan")

    if top == SelectionHelper.getEnd()[2] then top = SelectionHelper.getEnd()[2] + 1 end
    DebugRenderer.instance:drawText("^shadow;WEdit Schematic Paste Area", {SelectionHelper.getStart()[1], top + 1}, "cyan")
  else
    DebugRenderer.info:drawPlayerText("^shadow;^yellow;No schematic found! Did you delete it?", {0,-4})
  end

  if InputHelper.primary and SelectionHelper.isValid() and not InputHelper.isLocked() and schematic then
    InputHelper.lock()
    BackupHelper.backup(StampHelper.copy(SelectionHelper.get()))
    StampHelper.paste(schematic, SelectionHelper.getStart())
  elseif InputHelper.alt and not InputHelper.isLocked() and schematic then
    storage.weditSchematics[storageSchematicKey] = nil
  end
end

module = {
  action = Schematic
}
