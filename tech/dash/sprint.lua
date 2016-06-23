require "/tech/doubletap.lua"

function init()
  require "/scripts/weditController.lua"
  
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashRunModifier = config.getParameter("dashRunModifier")
  self.groundOnly = config.getParameter("groundOnly")
  self.stopAfterDash = config.getParameter("stopAfterDash")

  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      local direction = dashKey == "left" and -1 or 1
      if not self.dashDirection
          and groundValid()
          and mcontroller.facingDirection() == direction
          and not mcontroller.crouching()
          and not status.resourceLocked("energy")
          and not status.statPositive("activeMovementAbilities") then

        startDash(direction)
      end
    end)
end

function uninit()
  status.clearPersistentEffects("movementAbility")
end

function update(args)
  self.doubleTap:update(args.dt, args.moves)

  if self.dashDirection then
    if args.moves[self.dashDirection > 0 and "right" or "left"]
        and not mcontroller.liquidMovement()
        and not dashBlocked() then

      if mcontroller.facingDirection() == self.dashDirection then
        if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
          mcontroller.controlModifiers({runModifier = self.dashRunModifier})
          
          animator.setAnimationState("dashing", "on")
          animator.setParticleEmitterActive("dashParticles", true)
        else
          endDash()
        end
      else
        animator.setAnimationState("dashing", "off")
        animator.setParticleEmitterActive("dashParticles", false)
      end
    else
      endDash()
    end
  end
end

function groundValid()
  return mcontroller.onGround() or not self.groundOnly
end

function dashBlocked()
  return mcontroller.velocity()[1] == 0
end

function startDash(direction)
  self.dashDirection = direction
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  animator.setFlipped(self.dashDirection == -1)
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
end

function endDash(direction)
  status.clearPersistentEffects("movementAbility")

  if self.stopAfterDash then
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.dashControlForce)
  end

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)

  self.dashDirection = nil
end