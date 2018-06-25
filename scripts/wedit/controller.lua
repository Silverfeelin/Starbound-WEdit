--- WEdit controller (https://github.com/Silverfeelin/Starbound-WEdit)
-- Handles input and executes actions.
--
-- LICENSE
-- This file falls under an MIT License, which is part of this project.
-- An online copy can be viewed via the following link:
-- https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE
--
-- USAGE
-- To load this script:
-- 1. require "/scripts/wedit/controller.lua"
-- 2. On init, call wedit.controller.init(). This will internally initialize wedit, so wedit.init() shouldn't be called.
-- 3. On update, call wedit.controller.update(args). This will internally update wedit, so wedit.update(args) shouldn't be called.

wedit = {}
wedit.controller = {}
wedit.actions = {}
local controller = wedit.controller

-- Load dependencies
require "/scripts/wedit/keybinds.lua"
require "/scripts/messageutil.lua"
-- Load core library
require "/scripts/wedit/wedit.lua"
-- Load tool actions
require "/scripts/wedit/actions.lua"

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

-- Primarily for use within this script

--- Masks wedit.info, and only works if controller.showInfo is true.
-- @param ... wedit.info arguments
-- @see wedit.info
function controller.info(...)
  if controller.showInfo then
    wedit.info(...)
  end
end

--- Returns the currently selected matmod.
-- Defaults to grass.
-- @return Selected matmod.
function controller.getSelectedMod()
  return controller.mod or "grass"
end

-- Returns the currently selected block for displaying purposes.
-- false = "air", nil = "none"
-- @return Block name.
function controller.selectedBlockToString()
  return controller.blockToString(controller.selectedBlock)
end

--- Returns a string representation of a block.
-- false = "air", nil = "none".
-- @return Block name.
function controller.blockToString(block)
  if block == nil then
    return "none"
  elseif block == false then
    return "air"
  else
    return block
  end
end

--- Sets the selected block to the one under the cursor.
-- controller.selectedBlock is set to the returned value.
-- @param layer Layer to select block from.
-- @return Material name or false (air).
function controller.updateColor(layer)
  local tile = world.material(tech.aimPosition(), layer)
  if tile then
    controller.selectedBlock = tile
  else
    controller.selectedBlock = false
  end

  return tile or false
end

--- Returns a value indicating whether there's currently a valid selection.
-- Done by confirming both the bottom left and top right point are set.
-- @return True if a valid selection is made, false otherwise.
function controller.validSelection()
  return next(controller.selection[1]) and next(controller.selection[2]) and true or false
end

function controller.validLine()
  local line = controller.lineSelection
  if not line then return false end
  return not not (line[1] and line[1][1] and line[2] and line[2][1])
end

--- Draws rectangle(s) indicating the current selection and paste area.
function controller.showSelection()
  -- Draw selections if they have been made.
  if controller.validSelection() then
    wedit.debugRenderer:drawRectangle(controller.selection[1], controller.selection[2])
    wedit.debugRenderer:drawText(string.format("^shadow;WEdit Selection (%sx%s)", controller.selection[2][1] - controller.selection[1][1], controller.selection[2][2] - controller.selection[1][2]), {controller.selection[1][1], controller.selection[2][2]}, "green")

    if storage.weditCopy and storage.weditCopy.size then
      local copy = storage.weditCopy
      local top = controller.selection[1][2] + copy.size[2]
      wedit.debugRenderer:drawRectangle(controller.selection[1], {controller.selection[1][1] + copy.size[1], top}, "cyan")

      if top == controller.selection[2][2] then top = controller.selection[2][2] + 1 end
      wedit.debugRenderer:drawText("^shadow;WEdit Paste Selection", {controller.selection[1][1], top}, "cyan")
    end
  end
end

--- Disables certain actions until lmb and rmb are released.
-- Sets fireLocked to true. This indicates that certain actions should not activate until both fire buttons are released.
function controller.fireLock()
  controller.fireLocked = true
end

--- Disables certain actions until shift, lmb and rmb are released.
-- Sets shiftFireLocked and fireLocked to true. This indicates that certain actions should not activate until both fire buttons and shift are released.
-- fireLocked may be false when shiftFireLocked is true, if the user is only holding shift.
function controller.shiftFireLock()
  controller.fireLocked = true
  controller.shiftFireLocked = true
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

  if wedit.getUserConfigData("clearSchematics") then
    storage.weditSchematics = {}
    controller.setUserConfig("clearSchematics", false)
    wedit.user.clearSchematics = false
  end
end

--- Returns a corrected asset path to the given image.
-- @param path Nil or path leading up to the image. Path should end with a /.
-- @param image Absolute asset path or just the file name (including the extension).
-- @return Absolute asset path to the image.
function controller.fixImagePath(path, image)
  return not path and image or
    image:find("^/") and image or
    (path .. image):gsub("//", "/")
end

-- #endregion

-- #region Script Callbacks

function controller.init()
  wedit.init()

  -- Failsafe: If the interface was somehow marked open on init, this ensures it's marked closed. Otherwise it could become impossible to open it again.
  -- The interfaces stay open when warping, but it's a better solution to make users open them again than to have the mod break after a game crash.
  status.setStatusProperty("wedit.compact.open", nil)
  status.setStatusProperty("wedit.dyePicker.open", nil)
  status.setStatusProperty("wedit.matmodPicker.open", nil)
  status.setStatusProperty("wedit.materialPicker.open", nil)

  -- Default noclip status (on tech selection or character load)
  controller.noclipping = false
  -- Selected liquid ID. Expected to have name and liquidId at all times.
  controller.liquid = { name = "water", liquidId = 1 }
  -- Variables used to determine if LMB and/or RMB are held down.
  controller.primaryFire, controller.altFire = false, false
  controller.fireLocked = false
  -- Used to determine if Shift is held down.
  controller.shiftHeld = false
  -- Number used by WE_Select to determine the selection stage (0: Nothing, 1: Selecting).
  controller.selectStage = 0
  -- Table used to store the current raw selection coordinates.
  -- [1] Start selection or nil, [2] End selection or nil.
  controller.rawSelection = {}
  -- Table used to store the current selection coordinates, converted to block coordinates.
  -- [1] Bottom left corner of selection, [2] Top right corner of selection.
  controller.selection = {{},{}}
  -- Number used by WE_Ruler to determien the line selection stage.
  controller.lineStage = 0
  -- Table used to store the current line selection coordinates.
  -- [1] Starting point, [2] Ending point.
  controller.lineSelection = {{},{}}
  -- String used to hold the block used by tools such as the Pencil and Paint Bucket
  controller.selectedBlock = "dirt"
  -- Table used to store copies of areas prior to commands such as fill.
  controller.backup = {}
  -- Table used to display information in certain colors. { title & operations, description, variables }
  controller.colors = { "^orange;", "^yellow;", "^red;"}
  wedit.colors = controller.colors
  -- Shows usage text below the character. 0 = nothing, 1 = variables , 2 = usage & variables.
  controller.showInfo = true
  status.setStatusProperty("wedit.showingInfo", true)

  -- Load config once while still initializing.
  controller.updateUserConfig()

  -- #region NoClip Binds

  -- Set up noclip using Keybinds.
  Bind.create(wedit.getUserConfigData("noclipBind"), function()
    controller.noclipping = not controller.noclipping
    if controller.noclipping then
      tech.setParentState("fly")
      for i,v in ipairs(controller.noclipBinds) do
        v:rebind()
      end
    else
      tech.setParentState()
      for i,v in ipairs(controller.noclipBinds) do
        v:unbind()
      end
    end
  end)

  local adjustPosition = function(offset)
    local pos = mcontroller.position()
    mcontroller.setPosition({pos[1] + offset[1], pos[2] + offset[2]})
    mcontroller.setVelocity({0,0})
  end
  controller.noclipBinds = {}
  table.insert(controller.noclipBinds, Bind.create("up", function() adjustPosition({0,wedit.getUserConfigData("noclipSpeed")}) end, true))
  table.insert(controller.noclipBinds, Bind.create("down", function() adjustPosition({0,-wedit.getUserConfigData("noclipSpeed")}) end, true))
  table.insert(controller.noclipBinds, Bind.create("left", function() adjustPosition({-wedit.getUserConfigData("noclipSpeed"),0}) end, true))
  table.insert(controller.noclipBinds, Bind.create("right", function() adjustPosition({wedit.getUserConfigData("noclipSpeed"),0}) end, true))
  table.insert(controller.noclipBinds, Bind.create("up=false down=false left=false right=false", function() mcontroller.setVelocity({0,0}) end, false))
  for _,v in ipairs(controller.noclipBinds) do
    v:unbind()
  end

  -- #endregion

  -- #region Message Handlers

  message.setHandler("wedit.updateConfig", localHandler(controller.updateUserConfig))
  -- Allow picker interfaces to change values.
  message.setHandler("wedit.updateColor", localHandler(function(data)
    controller.selectedBlock = data
  end))
  message.setHandler("wedit.updateLiquid", localHandler(function(data)
    controller.liquid = data
  end))
  message.setHandler("wedit.updateMatmod", localHandler(function(data)
    controller.mod = data
  end))
  message.setHandler("wedit.showInfo", localHandler(function(bool)
    controller.showInfo = bool
    status.setStatusProperty("wedit.showingInfo", bool)
  end))

  -- #endregion

  sb.logInfo("WEdit Controller: Initialized WEdit.")
end

--- Update function, called in the main update callback.
function controller.update(args)
  wedit.update(args)

  -- Check if LMB / RMB are held down this game tick.
  controller.primaryFire = args.moves["primaryFire"]
  controller.altFire = args.moves["altFire"]
  controller.shiftHeld = not args.moves["run"]

  -- Removes the lock on your fire keys (LMB/RMB) if both have been released.
  if controller.fireLocked and not controller.primaryFire and not controller.altFire then
    controller.fireLocked = false
  end

  if controller.shiftFireLocked and not controller.shiftHeld and not controller.primaryFire and not controller.altFire then
    controller.shiftFireLocked = false
  end

  -- Set noclip movement parameters, if noclipping is enabled.
  if controller.noclipping then
    mcontroller.controlParameters({
      gravityEnabled = false,
      collisionEnabled = false,
      standingPoly = {},
      crouchingPoly = {},
      physicsEffectCategories = {"immovable"},
      mass = 0,
      runSpeed = 0,
      walkSpeed = 0,
      airFriction = 99999,
      airForce = 99999
    })
    wedit.logger:setLogMap("Noclip", string.format("Press '%s' to stop flying.", wedit.getUserConfigData("noclipBind")))
  else
    wedit.logger:setLogMap("Noclip", string.format("Press '%s' to fly.", wedit.getUserConfigData("noclipBind")))
  end

  -- As all WEdit items are two handed, we only have to check the primary item.
  local primaryItem = world.entityHandItemDescriptor(entity.id(), "primary")
  local action = nil
  if primaryItem and primaryItem.parameters and primaryItem.parameters.shortdescription then action = primaryItem.parameters.shortdescription end

  if action and type(wedit.actions[action]) == "function" then
    controller.itemData = primaryItem.parameters.wedit

    -- Determine action for the all in one tool using the compact interface.
    if action == "WE_AllInOne" and status.statusProperty("wedit.compact.open") then
      action = status.statusProperty("wedit.compact.action", "WE_Select")
    end

    wedit.actions[action]()
  end

  if controller.validSelection() then
    controller.showSelection()
  end
end

--- Uninit function, called in the main uninit callback.
function controller.uninit()
  tech.setParentState()

  -- Mark interfaces for closing.
  if status.statusProperty("wedit.compact.open", false) then
    status.setStatusProperty("wedit.compact.close", true)
  end
end

-- #endregion

-- #region WEdit Tools

--- Returns parameters for a trianglium ore used for WEdit tools.
-- Vanilla parameters such as blueprints and radio messages are removed.
-- @param shortDescription Visual item name, used to identify WEdit functions.
-- @param description Item description displayed in the item tooltip.
-- @param category Item header, displayed below the item shortDescription.
-- @param inventoryIcon Path to an icon. Supports directives.
-- @param rarity Item rarity. Defaults to common.
-- @return Altered item parameters (for a triangliumore).
function controller.spawnOreParameters(shortDescription, description, category, inventoryIcon, rarity)
 rarity = rarity or "common"
  return {
    itemTags = jarray(),
    radioMessagesOnPickup = jarray(),
    learnBlueprintsOnPickup = jarray(),
    twoHanded = true,
    shortdescription = shortDescription,
    category = category,
    description = description,
    inventoryIcon = inventoryIcon,
    rarity = rarity
  }
end

-- #endregion
