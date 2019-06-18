local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local ModHelper = include("/scripts/wedit/helpers/modHelper.lua")
local Palette = include("/scripts/wedit/helpers/palette.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

local function ModRemover()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: MatMod Remover")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Remove from foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Remove from background.", {0,-2})

  DebugRenderer.instance:drawBlock(tech.aimPosition())

  if InputHelper.isLocked() then return end
  if InputHelper.primary then
    ModHelper.remove(tech.aimPosition(), "foreground")
  elseif InputHelper.alt then
    ModHelper.remove(tech.aimPosition(), "background")
  end
end

module = {
  action = ModRemover
}