--- WEdit controller (https://github.com/Silverfeelin/Starbound-WEdit)
-- Executes actions.

wedit = wedit or {}
wedit.user = wedit.user or {}
wedit.default = wedit.default or {}

require "/scripts/wedit/libs/include.lua"
require "/scripts/messageutil.lua"
require "/scripts/wedit/libs/scriptHooks.lua"

include("/scripts/wedit/wedit.lua")
local Actions = include("/scripts/wedit/actions.lua")
local ItemHelper = include("/scripts/wedit/helpers/itemHelper.lua")

local controller = {}
module = controller

--- Sets a value under the "wedit" status property.
-- @param key wedit table key.
-- @param value Property value.
-- @see controller.getUserConfig
function controller.setUserConfig(key, value)
  local cfg = status.statusProperty("wedit") or {}
  cfg[key] = value
  status.setStatusProperty("wedit", cfg)
end

--- Gets a value under the "wedit" status property.
-- @param key wedit table key.
-- @see controller.setUserConfig
function controller.getUserConfig(key)
  local cfg = status.statusProperty("wedit") or {}
  return key == nil and cfg or cfg[key]
end

-- #region Useful functions

function controller.validLine()
  local line = controller.lineSelection
  if not line then return false end
  return not not (line[1] and line[1][1] and line[2] and line[2][1])
end

--- Updates the wedit.user configuration
-- Clears schematics if requested.
-- @see wedit.user
function controller.updateUserConfig()
    -- Load config data
  local cfg = controller.getUserConfig()

  for k in pairs(wedit.user) do
    wedit.user[k] = nil
  end
  for k,v in pairs(cfg) do
    wedit.user[k] = v
  end
end

-- #endregion

-- #region Script Callbacks

function controller.init()
  -- Failsafe: If the interface was somehow marked open on init, this ensures it's marked closed. Otherwise it could become impossible to open it again.
  -- The interfaces stay open when warping, but it's a better solution to make users open them again than to have the mod break after a game crash.
  status.setStatusProperty("wedit.compact.open", nil)
  status.setStatusProperty("wedit.dyePicker.open", nil)
  status.setStatusProperty("wedit.huePicker.open", nil)
  status.setStatusProperty("wedit.matmodPicker.open", nil)
  status.setStatusProperty("wedit.materialPicker.open", nil)

  -- Number used by WE_Ruler to determien the line selection stage.
  controller.lineStage = 0
  -- Table used to store the current line selection coordinates.
  -- [1] Starting point, [2] Ending point.
  controller.lineSelection = {{},{}}

  -- Load config once while still initializing.
  controller.updateUserConfig()

  -- #region Message Handlers

  message.setHandler("wedit.updateConfig", localHandler(controller.updateUserConfig))

  -- #endregion

  sb.logInfo("WEdit Controller: Initialized WEdit.")
end

--- Update function, called in the main update callback.
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

--- Uninit function, called in the main uninit callback.
function controller.uninit()
  -- Mark interfaces for closing.
  if status.statusProperty("wedit.compact.open") then
    status.setStatusProperty("wedit.compact.close", true)
  end
end

-- #endregion

-- #region WEdit Tools

function controller.executeAction(m)
  -- TODO: Remove and call m.action directly once all actions have been ported.
  if not m then return end
  if type(m) == "function" then m() else m.action() end
end

-- #endregion

hook("init", controller.init)
hook("update", controller.update)
hook("uninit", controller.uninit)
