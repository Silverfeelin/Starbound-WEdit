require "/scripts/wedit/libs/keybinds.lua"
require "/scripts/wedit/libs/scriptHooks.lua"
require "/scripts/messageutil.lua"

local Logger = include("/scripts/wedit/helpers/logger.lua")
local Noclip = {}
module = Noclip

local controlParameters = {
  gravityEnabled = false,
  collisionEnabled = false,
  standingPoly = {{0,0},{0,0}},
  crouchingPoly = {{0,0},{0,0}},
  physicsEffectCategories = {"immovable"},
  mass = 0,
  runSpeed = 0,
  walkSpeed = 0,
  airFriction = 99999,
  airForce = 99999
}

hook("init", function()
  Noclip.key = status.statusProperty("wedit.noclip.bind", "specialTwo")
  Noclip.speed = status.statusProperty("wedit.noclip.speed", 2)

  Noclip.bind = Bind.create(Noclip.key, function()
    Noclip.active = not Noclip.active
    tech.setParentState(Noclip.active and "fly" or nil)

    for _,v in ipairs(Noclip.binds) do
      if Noclip.active then v:rebind() else v:unbind() end
    end
  end, false, noclipBind == "")

  local adjustPosition = function(offset)
    local pos = mcontroller.position()
    mcontroller.setPosition({pos[1] + offset[1], pos[2] + offset[2]})
    mcontroller.setVelocity({0,0})
  end

  Noclip.binds = {}
  table.insert(Noclip.binds, Bind.create("up", function() adjustPosition({0,wedit.getUserConfigData("noclipSpeed")}) end, true, true))
  table.insert(Noclip.binds, Bind.create("down", function() adjustPosition({0,-wedit.getUserConfigData("noclipSpeed")}) end, true, true))
  table.insert(Noclip.binds, Bind.create("left", function() adjustPosition({-wedit.getUserConfigData("noclipSpeed"),0}) end, true, true))
  table.insert(Noclip.binds, Bind.create("right", function() adjustPosition({wedit.getUserConfigData("noclipSpeed"),0}) end, true, true))
  table.insert(Noclip.binds, Bind.create("up=false down=false left=false right=false", function() mcontroller.setVelocity({0,0}) end, false, true))

  message.setHandler("wedit.noclip.setBind", localHandler(function(newBind)
    newBind = newBind or ""
    status.setStatusProperty("wedit.noclip.bind", newBind)

    Noclip.bind:change(newBind)
    if newBind == "" then Noclip.bind:unbind() else Noclip.bind:rebind() end
  end))

  message.setHandler("wedit.noclip.setSpeed", localHandler(function(newSpeed)
    Noclip.speed = math.abs(newSpeed)
    status.setStatusProperty("wedit.noclip.speed", newSpeed)
  end))
end)

hook("update", function()
  if Noclip.active then
    mcontroller.controlParameters(controlParameters)
  end
  Logger.instance:setLogMap("Noclip",
    string.format(Noclip.active and "Press '%s' to stop flying." or "Press '%s' to fly.", Noclip.key))
end)

hook("uninit", function()
  tech.setParentState()
end)
