local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")

local function AllInOne()
  if status.statusProperty("wedit.compact.open") then return end
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: All in One")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Open Compact Interface.", {0,-1})

  if not InputHelper.isLocked() and (InputHelper.primary or InputHelper.alt) then
    InputHelper.lock()
    world.sendEntityMessage(entity.id(), "interact", "ScriptPane", "/interface/wedit/compact/compact.config")
  end
end

module = {
  action = AllInOne
}
