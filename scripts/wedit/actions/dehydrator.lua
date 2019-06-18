local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local LiquidHelper = include("/scripts/wedit/helpers/liquidHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

local function Dehydrator()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: Dehydrator")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Dehydrate selection.", {0,-1})

  if InputHelper.isLocked() or not SelectionHelper.isValid() then return end
  if InputHelper.primary then
    InputHelper.lock()
    LiquidHelper.clear(SelectionHelper.get())
  end
end

module = {
  action = Dehydrator
}
