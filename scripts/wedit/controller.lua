--- WEdit controller (https://github.com/Silverfeelin/Starbound-WEdit)
-- Handles input and executes actions.
--
-- LICENSE
-- This file falls under an MIT License, which is part of this project.
-- An online copy can be viewed via the following link:
-- https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

wedit = {}
wedit.actions = wedit.actions or {}
-- Load dependencies
require "/scripts/wedit/libs/keybinds.lua"
require "/scripts/messageutil.lua"
-- Core library
require "/scripts/wedit/wedit.lua"
require "/scripts/wedit/libs/include.lua"

local debugRenderer = include("/scripts/wedit/helpers/debugRenderer.lua").instance
local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local SelectionHelper = include("/scripts/wedit/helpers/selectionHelper.lua")

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
  sb.logInfo("updateColor %s", layer)
  local tile = world.material(tech.aimPosition(), layer)
  if tile then
    controller.selectedBlock = tile
  else
    controller.selectedBlock = false
  end

  return tile or false
end

function controller.validLine()
  local line = controller.lineSelection
  if not line then return false end
  return not not (line[1] and line[1][1] and line[2] and line[2][1])
end

--- Draws rectangle(s) indicating the current selection and paste area.
function controller.showSelection()
  -- Draw selections if they have been made.
  if SelectionHelper.isValid() then
    if storage.weditCopy and storage.weditCopy.size then
      local copy = storage.weditCopy
      local top = SelectionHelper.getStart()[2] + copy.size[2]
      debugRenderer:drawRectangle(SelectionHelper.getStart(), {SelectionHelper.getStart()[1] + copy.size[1], top}, "cyan")

      if top == SelectionHelper.getEnd()[2] then top = SelectionHelper.getEnd()[2] + 1 end
      debugRenderer:drawText("^shadow;WEdit Paste Selection", {SelectionHelper.getStart()[1], top}, "cyan")
    end
  end
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

  if controller.noclipBind then
    if cfg.noclipBind == "" then
      controller.noclipBind:unbind()
    else
      controller.noclipBind:rebind()
      controller.noclipBind:change(cfg.noclipBind)
    end
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

  -- Holds the noclip toggle Bind
  controller.noclipBind = nil
  -- Default noclip status (on tech selection or character load)
  controller.noclipping = false
  -- Selected liquid ID. Expected to have name and liquidId at all times.
  controller.liquid = { name = "water", liquidId = 1 }
  -- Number used by WE_Ruler to determien the line selection stage.
  controller.lineStage = 0
  -- Table used to store the current line selection coordinates.
  -- [1] Starting point, [2] Ending point.
  controller.lineSelection = {{},{}}
  -- String used to hold the block used by tools such as the Pencil and Paint Bucket
  controller.selectedBlock = "dirt"
  -- Table used to store copies of areas prior to commands such as fill.
  controller.backup = {}
  -- Shows usage text below the character. 0 = nothing, 1 = variables , 2 = usage & variables.
  controller.showInfo = true
  status.setStatusProperty("wedit.showingInfo", true)

  -- Load config once while still initializing.
  controller.updateUserConfig()

  -- #region NoClip Binds

  -- Set up noclip using Keybinds.
  local noclipBind = wedit.getUserConfigData("noclipBind");
  controller.noclipBind = Bind.create(noclipBind, function()
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
  end, false, noclipBind == "")

  local adjustPosition = function(offset)
    local pos = mcontroller.position()
    mcontroller.setPosition({pos[1] + offset[1], pos[2] + offset[2]})
    mcontroller.setVelocity({0,0})
  end
  controller.noclipBinds = {}
  table.insert(controller.noclipBinds, Bind.create("up", function() adjustPosition({0,wedit.getUserConfigData("noclipSpeed")}) end, true, true))
  table.insert(controller.noclipBinds, Bind.create("down", function() adjustPosition({0,-wedit.getUserConfigData("noclipSpeed")}) end, true, true))
  table.insert(controller.noclipBinds, Bind.create("left", function() adjustPosition({-wedit.getUserConfigData("noclipSpeed"),0}) end, true, true))
  table.insert(controller.noclipBinds, Bind.create("right", function() adjustPosition({wedit.getUserConfigData("noclipSpeed"),0}) end, true, true))
  table.insert(controller.noclipBinds, Bind.create("up=false down=false left=false right=false", function() mcontroller.setVelocity({0,0}) end, false, true))

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
  InputHelper.update(args)
  wedit.update(args)

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

    controller.executeAction(wedit.actions[action])
  end

  if SelectionHelper.isValid() then
    SelectionHelper.render(debugRenderer)
    controller.showSelection()
  end
end

--- Uninit function, called in the main uninit callback.
function controller.uninit()
  tech.setParentState()

  -- Mark interfaces for closing.
  if status.statusProperty("wedit.compact.open") then
    status.setStatusProperty("wedit.compact.close", true)
  end
end

-- #endregion

-- #region WEdit Tools

function controller.executeAction(m)
  -- TODO: Remove and call m.action directly.
  if type(m) == "function" then m() else m.action() end
end

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
