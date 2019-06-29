require "/scripts/wedit/libs/include.lua"
require "/scripts/messageutil.lua"
require "/scripts/wedit/libs/scriptHooks.lua"

local Actions = include("/scripts/wedit/actions.lua")
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")
local Config = include("/scripts/wedit/helpers/config.lua")

local controller = {}
module = controller

function controller.init()
  -- Failsafe: If the interface was somehow marked open on init, this ensures it's marked closed. Otherwise it could become impossible to open it again.
  -- The interfaces stay open when warping, but it's a better solution to make users open them again than to have the mod break after a game crash.
  status.setStatusProperty("wedit.compact.open", nil)
  status.setStatusProperty("wedit.dyePicker.open", nil)
  status.setStatusProperty("wedit.huePicker.open", nil)
  status.setStatusProperty("wedit.matmodPicker.open", nil)
  status.setStatusProperty("wedit.materialPicker.open", nil)

  message.setHandler("wedit.schematics.clear", localHandler(function()
    storage.weditSchematics = nil
  end))
end

function controller.update(args)
  -- As all WEdit items are two handed, we only have to check the primary item.
  local primaryItem = world.entityHandItemDescriptor(entity.id(), "primary")
  local action = nil
  if primaryItem and primaryItem.parameters and primaryItem.parameters.shortdescription then action = primaryItem.parameters.shortdescription end

  if action and Actions[action] then
    ItemHelper.setItemData(primaryItem.parameters.wedit)

    -- Determine action for the all in one tool using the compact interface.
    if action == "WE_AllInOne" and status.statusProperty("wedit.compact.open") then
      action = status.statusProperty("wedit.compact.action", "WE_Select")
    end

    controller.executeAction(Actions[action])
  end
end

function controller.uninit()
  -- Mark interfaces for closing.
  if status.statusProperty("wedit.compact.open") then
    status.setStatusProperty("wedit.compact.close", true)
  end
end

function controller.executeAction(m)
  m.action()
end

hook("init", controller.init)
hook("update", controller.update)
hook("uninit", controller.uninit)
