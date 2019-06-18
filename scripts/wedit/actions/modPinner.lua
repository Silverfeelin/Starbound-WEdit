local AssetHelper = include("/scripts/wedit/helpers/assetHelper.lua")
local DebugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua")
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")

local function ModPinner()
  DebugRenderer.info:drawPlayerText("^shadow;^orange;WEdit: MatMod Pinner")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Primary Fire: Pin foreground.", {0,-1})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Alt Fire: Pin background.", {0,-2})

  DebugRenderer.instance:drawBlock(tech.aimPosition())

  local fg, bg = world.mod(tech.aimPosition(), "foreground"), world.mod(tech.aimPosition(), "background")
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Foreground Mod: ^red;" .. (fg or "None") .. "^yellow;.", {0,-3})
  DebugRenderer.info:drawPlayerText("^shadow;^yellow;Background Mod: ^red;" .. (bg or "None") .. "^yellow;.", {0,-4})

  if InputHelper.isLocked() then return end
  if InputHelper.primary or InputHelper.alt then
    InputHelper.lock()
    local mod = InputHelper.primary and fg or InputHelper.alt and bg
    if not mod then return end

    local path = "/tiles/mods/"
    local icon = root.assetJson(path .. mod .. ".matmod").renderParameters.texture .. "?crop=0;0;16;16"
    icon = AssetHelper.fixPath(path, icon)

    local params = ItemHelper.oreParameters("WE_Mod", "^yellow;Primary Fire: Modify foreground.\nAlt Fire: Modify background.", "^orange;WEdit: " .. mod .. " MatMod", icon, "essential")
    params.wedit = { mod = mod }

    world.spawnItem("triangliumore", mcontroller.position(), 1, params)
  end
end

module = {
  action = ModPinner
}
