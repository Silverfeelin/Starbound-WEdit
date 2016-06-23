require "/tech/doubletap.lua"

function init()
  require "/scripts/weditController.lua"
  
  self.mode = "none"
  self.blinkTimer = 0
  self.dashDirection = 0
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.blinkOutTime = config.getParameter("blinkOutTime")
  self.blinkInTime = config.getParameter("blinkInTime")
  self.groundOnly = config.getParameter("groundOnly")
  self.dashMaxDistance = config.getParameter("dashDistance")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CCCCFFFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      if self.mode == "none"
          and self.dashCooldownTimer == 0
          and groundValid()
          and not mcontroller.crouching()
          and not status.statPositive("activeMovementAbilities") then

        self.targetPosition = findTargetPosition(dashKey == "left" and -1 or 1, self.dashMaxDistance)
        if self.targetPosition then self.mode = "start" end
      end
    end)
end

function uninit()
  tech.setParentDirectives()
  status.clearPersistentEffects("movementAbility")
end

function update(args)
  if self.dashCooldownTimer > 0 then
    self.dashCooldownTimer = math.max(0, self.dashCooldownTimer - args.dt)
    if self.dashCooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

  self.doubleTap:update(args.dt, args.moves)

  if self.mode == "start" then
    mcontroller.setVelocity({0, 0})
    tech.setToolUsageSuppressed(true)
    self.mode = "out"
    self.blinkTimer = 0
    animator.playSound("activate")
    status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  elseif self.mode == "out" then
    tech.setParentDirectives("?multiply=00000000")
    animator.setAnimationState("blinking", "out")
    mcontroller.setVelocity({0, 0})
    self.blinkTimer = self.blinkTimer + args.dt

    if self.blinkTimer > self.blinkOutTime then
      mcontroller.setPosition(self.targetPosition)
      self.targetPosition = nil
      self.mode = "in"
      self.blinkTimer = 0
    end
  elseif self.mode == "in" then
    tech.setParentDirectives()
    animator.setAnimationState("blinking", "in")
    mcontroller.setVelocity({0, 0})
    self.blinkTimer = self.blinkTimer + args.dt

    if self.blinkTimer > self.blinkInTime then
      tech.setToolUsageSuppressed(false)
      self.mode = "none"
      self.dashCooldownTimer = self.dashCooldown
      status.clearPersistentEffects("movementAbility")
    end
  end
end

function groundValid()
  return mcontroller.onGround() or not self.groundOnly
end

function findTargetPosition(dir, maxDist)
  local dist = 1
  local targetPosition
  local collisionPoly = mcontroller.collisionPoly()
  local testPos = mcontroller.position()
  while dist <= maxDist do
    testPos[1] = testPos[1] + dir
    if not world.polyCollision(collisionPoly, testPos, {"Null", "Block", "Dynamic"}) then
      local oneDown = {testPos[1], testPos[2] - 1}
      if not world.polyCollision(collisionPoly, oneDown, {"Null", "Block", "Dynamic"}) then
        testPos = oneDown
      end
    else
      local oneUp = {testPos[1], testPos[2] + 1}
      if not world.polyCollision(collisionPoly, oneUp, {"Null", "Block", "Dynamic"}) then
        testPos = oneUp
      else
        break
      end
    end
    targetPosition = testPos
    dist = dist + 1
  end

  if targetPosition then
    local towardGround = {testPos[1], testPos[2] - 0.8}
    local groundPosition = world.resolvePolyCollision(collisionPoly, towardGround, 0.8)
    if groundPosition and not (groundPosition[1] == towardGround[1] and groundPosition[2] == towardGround[2]) then
      targetPosition = groundPosition
    end
  end

  return targetPosition
end
