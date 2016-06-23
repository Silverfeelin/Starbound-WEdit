require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/util.lua"

function init()
  require "/scripts/weditController.lua"
  
  initCommonParameters()

  self.chargePitchAdjust = config.getParameter("chargePitchAdjust")
  self.chargeEnergy = config.getParameter("chargeEnergy")
  self.chargeTime = config.getParameter("chargeTime")
  self.launchVelocity = config.getParameter("launchVelocity")
  self.chargeEnergyPerSecond = self.chargeEnergy / self.chargeTime[2]

  self.boostMovementParameters = util.mergeTable(copy(self.transformedMovementParameters), config.getParameter("boostMovementParameters"))
  self.boostTime = config.getParameter("boostTime")

  self.chargeTimer = 0
  self.boostTimer = 0
end

function uninit()
  animator.setParticleEmitterActive("chargeLeft", false)
  animator.setParticleEmitterActive("chargeRight", false)
  animator.stopAllSounds("chargeLoop")
  storePosition()
  deactivate()
end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special"] == 1 then
    attemptActivation()
    if self.active then
      self.chargeDirection = mcontroller.facingDirection()
      self.chargeTimer = 0
    end
  end
  self.specialLast = args.moves["special"] == 1

  if self.active then
    self.boostTimer = math.max(0, self.boostTimer - args.dt)
    if self.chargeDirection then
      if self.specialLast and not mcontroller.onGround() then
        -- wait to hit the ground before charging
        stopChargeEffects()
      elseif self.specialLast and (self.chargeTimer == self.chargeTime[2] or status.overConsumeResource("energy", self.chargeEnergyPerSecond * args.dt)) then
        self.chargeTimer = math.min(self.chargeTimer + args.dt, self.chargeTime[2])
        self.angularVelocity = -self.chargeDirection * self.launchVelocity[1] * chargeRatio()
        mcontroller.controlModifiers({movementSuppressed = true, facingSuppressed = true})
        mcontroller.controlApproachXVelocity(0, 1000)
        startChargeEffects()
        animator.setSoundPitch("chargeLoop", 1.0 + chargeRatio(), 0)
      else
        if self.chargeTimer >= self.chargeTime[1] then
          local launchVelocity = vec2.mul({self.launchVelocity[1] * self.chargeDirection, self.launchVelocity[2]}, chargeRatio())
          mcontroller.setVelocity(launchVelocity)
          animator.playSound("launch")
          self.boostTimer = self.boostTime
        else
          self.angularVelocity = 0
        end
        stopChargeEffects()
        animator.setSoundPitch("chargeLoop", 1.0, 0)
        self.chargeDirection = nil
      end
    else
      updateAngularVelocity(args.dt)
    end

    if self.boostTimer > 0 then
      mcontroller.controlParameters(self.boostMovementParameters)
    else
      mcontroller.controlParameters(self.transformedMovementParameters)
    end

    status.setResourcePercentage("energyRegenBlock", 1.0)

    updateRotationFrame(args.dt)
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function chargeRatio()
  return self.chargeTimer / self.chargeTime[2]
end

function startChargeEffects()
  if not self.chargeSoundPlaying then
    animator.playSound("chargeLoop", -1)
    self.chargeSoundPlaying = true
  end
  if self.chargeTimer >= self.chargeTime[1] then
    animator.setParticleEmitterActive("charge" .. (self.chargeDirection < 0 and "Left" or "Right"), true)
  end
end

function stopChargeEffects()
  if self.chargeSoundPlaying then
    animator.stopAllSounds("chargeLoop")
    self.chargeSoundPlaying = false
  end
  animator.setParticleEmitterActive("chargeLeft", false)
  animator.setParticleEmitterActive("chargeRight", false)
end