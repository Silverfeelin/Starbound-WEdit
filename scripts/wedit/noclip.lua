require "/scripts/wedit/libs/keybinds.lua"
require "/scripts/wedit/libs/scriptHooks.lua"
require "/scripts/messageutil.lua"

local Logger = include("/scripts/wedit/helpers/logger.lua")
local Config = include("/scripts/wedit/helpers/config.lua")

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

local function toggleNoclip(val)
  if val ~= nil then
    Noclip.active = val
  else
    Noclip.active = not Noclip.active
  end
  tech.setParentState(Noclip.active and "fly" or nil)

  for _,v in ipairs(Noclip.binds) do
    if Noclip.active then v:rebind() else v:unbind() end
  end
end

function Noclip.setBind(newBind)
  newBind = newBind or ""

  local cfg = status.statusProperty("wedit.noclip") or {}
  cfg.bind = newBind
  Noclip.key = newBind
  status.setStatusProperty("wedit.noclip", cfg)
  
  Noclip.bind:change(newBind)
  if newBind == "" then
    Noclip.bind:unbind()
    toggleNoclip(false);
  else
    Noclip.bind:rebind()
  end
end

function Noclip.setSpeed(newSpeed)
  newSpeed = newSpeed or 0.75
  newSpeed = math.abs(newSpeed)

  local cfg = status.statusProperty("wedit.noclip") or {}
  cfg.speed = newSpeed
  status.setStatusProperty("wedit.noclip", cfg)
  
  Noclip.speed = newSpeed
end

hook("init", function()
  local cfg = status.statusProperty("wedit.noclip") or {}
  Noclip.key = cfg.bind or "specialTwo"
  Noclip.speed = cfg.speed or 0.75

  Noclip.bind = Bind.create(Noclip.key, function() toggleNoclip() end, false, Noclip.key == "")

  local adjustPosition = function(offset)
    local pos = mcontroller.position()
    mcontroller.setPosition({pos[1] + offset[1], pos[2] + offset[2]})
    mcontroller.setVelocity({0,0})
  end

  Noclip.binds = {}
  table.insert(Noclip.binds, Bind.create("up", function() adjustPosition({0,Noclip.speed}) end, true, true))
  table.insert(Noclip.binds, Bind.create("down", function() adjustPosition({0,-Noclip.speed}) end, true, true))
  table.insert(Noclip.binds, Bind.create("left", function() adjustPosition({-Noclip.speed,0}) end, true, true))
  table.insert(Noclip.binds, Bind.create("right", function() adjustPosition({Noclip.speed,0}) end, true, true))
  table.insert(Noclip.binds, Bind.create("up=false down=false left=false right=false", function() mcontroller.setVelocity({0,0}) end, false, true))

  message.setHandler("wedit.noclip.setBind", localHandler(Noclip.setBind))
  message.setHandler("wedit.noclip.setSpeed", localHandler(Noclip.setSpeed))
end)


hook("update", function()
  if Noclip.active then
    mcontroller.controlParameters(controlParameters)
  end
  if Noclip.key ~= "" then
    Logger.instance:setLogMap("Noclip", string.format(Noclip.active and "Press '%s' to stop flying." or "Press '%s' to fly.", Noclip.key))
  end
end)

hook("uninit", function()
  tech.setParentState()
end)
