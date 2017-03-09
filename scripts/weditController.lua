--[[
  WEdit (https://github.com/Silverfeelin/Starbound-WEdit)

  To load this script, it has to be required -inside- the init function of a base tech script (EG. distortionsphere.lua).
  To use this script, the chosen base tech has to be active on your character. Further usage instructions can be found on the official page linked above.

  Hit ALT + 0 in NP++ to fold all, and get an overview of the contents of this script.
]]

local startTime = os.clock()

require "/scripts/wedit.lua"
require "/scripts/weditActions.lua"
require "/scripts/keybinds.lua"

local controller = { }
wedit.controller = controller

function controller.setConfigData(key, value)
  root.setConfigurationPath("wedit." .. key, value)
end
function controller.getConfigData(key)
  return root.getConfigurationPath("wedit." .. key)
end

-- Failsafe: If the WEdit configuration table wasn't set, set it.
if not root.getConfigurationPath("wedit") then root.setConfigurationPath("wedit", {}) end

-- Failsafe: If the interface was somehow marked open on init, this ensure it's marked closed.
status.setStatusProperty("wedit.compact.open", false)

-- Default noclip status (on tech selection or character load)
controller.noclipping = false
-- Indices for selected materials, used by the Modifier and Hydrator.
controller.modIndex = 1
controller.liquidIndex = 1
-- Variables used to determine if LMB and/or RMB are held down this tick.
controller.primaryFire, controller.altFire = false, false
controller.fireLocked = false
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
controller.line = {{},{}}
-- String used to determine what layer tools such as the Eraser, Color Picker, Paint Bucket and Pencil affect.
controller.layer = "foreground"
-- String used to hold the block used by tools such as the Pencil and Paint Bucket
controller.selectedBlock = "dirt"
-- Table used to store copies of areas prior to commands such as fill.
controller.backup = {}
-- Table used to display information in certain colors. { title & operations, description, variables }
controller.colors = { "^orange;", "^yellow;", "^red;"}
-- Variable used to determine when to poll the config for updates from the MUI configuration interface.
controller.lastUpdate = os.clock()

----------------------------------------
--          Useful functions          --
-- Primary for use within this script --
----------------------------------------

--[[
  Returns the currently selected matmod.
  @return - Selected matmod.
]]
function controller.getSelectedMod()
  return wedit.mods[controller.modIndex]
end

--[[
  Returns the currently selected block for displaying purposes (false = air, nil = none)
  @return - Block name, where non-strings are converted for displaying.
]]
function controller.selectedBlockToString()
  if controller.selectedBlock == nil then
    return "none"
  elseif controller.selectedBlock == false then
    return "air"
  else
    return controller.selectedBlock
  end
end

--[[
  Sets the selected block to the one under the cursor, on the given layer.
  @param [layer] - Layer to select block from. Defaults to
  controller.layer.
  @return - Tile or false.
]]
function controller.updateColor(layer)
  if type(layer) ~= "string" then layer = controller.layer end

  local tile = world.material(tech.aimPosition(), layer)
  if tile then
    controller.selectedBlock = tile
  else
    controller.selectedBlock = false
  end

  return tile or false
end

--[[
  Returns a value indicating whether there's currently a valid selection.
  Does this by confirming both the bottom left and top right point are set.
]]
function controller.validSelection()
  return next(controller.selection[1]) and next(controller.selection[2]) and true or false
end

--[[
  Draws rectangle(s) indicating the current selection and paste area, if a valid selection is made.
]]
function controller.showSelection()
  -- Draw selections if they have been made.
  if controller.validSelection() then
    wedit.debugRectangle(controller.selection[1], controller.selection[2])
    wedit.debugText(string.format("^shadow;WEdit Selection (%sx%s)", controller.selection[2][1] - controller.selection[1][1], controller.selection[2][2] - controller.selection[1][2]), {controller.selection[1][1], controller.selection[2][2]}, "green")

    if storage.weditCopy and storage.weditCopy.size then
      local copy = storage.weditCopy
      local top = controller.selection[1][2] + copy.size[2]
      wedit.debugRectangle(controller.selection[1], {controller.selection[1][1] + copy.size[1], top}, "cyan")

      if top == controller.selection[2][2] then top = controller.selection[2][2] + 1 end
      wedit.debugText("^shadow;WEdit Paste Selection", {controller.selection[1][1], top}, "cyan")
    end
  end
end

--[[
  Sets fireLocked to true, indicating that certain actions should not activate until both fire buttons are released.
]]
function controller.fireLock()
  controller.fireLocked = true
end

--[[
  Checks if the starbound.config file contains updated parameters for WEdit,
  before loading them. Overwrites data in wedit.user, which is prioritized over
  wedit.default.
  @see wedit.config, wedit.user, wedit.default
]]
function controller.updateUserConfig(initializing)
  if initializing or controller.getConfigData("updateConfig") then
    controller.setConfigData("updateConfig", false)

    -- Load config data
    local cfg = root.getConfigurationPath("wedit")
    for k in pairs(wedit.user) do
      wedit.user[k] = nil
    end
    for k,v in pairs(cfg) do
      wedit.user[k] = v
    end

    if wedit.config.clearSchematics then
      storage.weditSchematics = {}
      controller.setConfigData("clearSchematics", false)
      wedit.user.clearSchematics = false
    end
  end
end

--[[
  Returns a corrected asset path to the given image.
  @param path - Nil or path leading up to the image. Path should end with a /.
  @param image - Absolute asset path or just the file name (including the extension).
  @return - Absolute asset path to the image.
]]
function controller.fixImagePath(path, image)
  return not path and image or image:find("^/") and image or (path .. image):gsub("//", "/")
end

----------------------
-- Script Callbacks --
----------------------

--[[
  Update function, called in the main update callback.
]]
function controller.update(args)
  -- Update parameters every 2.5 seconds
  local clock = os.clock()
  if clock > controller.lastUpdate + 1 then
    controller.lastUpdate = clock
    controller.updateUserConfig()
  end

  -- Check if LMB / RMB are held down this game tick.
  controller.primaryFire = args.moves["primaryFire"]
  controller.altFire = args.moves["altFire"]

  -- Removes the lock on your fire keys (LMB/RMB) if both have been released.
  if controller.fireLocked and not controller.primaryFire and not controller.altFire then
    controller.fireLocked = false
  end

  -- Set noclip movement parameters, if noclipping is enabled.
  if controller.noclipping then
    mcontroller.controlParameters({
      gravityEnabled = false,
      collisionEnabled = false,
      standingPoly = {},
      crouchingPoly = {},
      mass = 0,
      runSpeed = 0,
      walkSpeed = 0
    })
    wedit.setLogMap("Noclip", string.format("Press '%s' to stop flying.", wedit.config.noclipBind))
  else
    wedit.setLogMap("Noclip", string.format("Press '%s' to fly.", wedit.config.noclipBind))
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

--[[
  Uninit function, called in the main uninit callback.
]]
function controller.uninit()
  tech.setParentState()
end

-- Alter update callback.
local oldUpdate = update
update = function(args)
  oldUpdate(args)
  controller.update(args)
end

-- Alter uninit callback.
local oldUninit = uninit
uninit = function()
  oldUninit()
  controller.uninit()
end

------------------
-- Noclip Binds --
------------------

-- Set up noclip using Keybinds.
Bind.create(wedit.config.noclipBind, function()
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
end
controller.noclipBinds = {}
table.insert(controller.noclipBinds, Bind.create("up", function() adjustPosition({0,wedit.config.noclipSpeed}) end, true))
table.insert(controller.noclipBinds, Bind.create("down", function() adjustPosition({0,-wedit.config.noclipSpeed}) end, true))
table.insert(controller.noclipBinds, Bind.create("left", function() adjustPosition({-wedit.config.noclipSpeed,0}) end, true))
table.insert(controller.noclipBinds, Bind.create("right", function() adjustPosition({wedit.config.noclipSpeed,0}) end, true))
for _,v in ipairs(controller.noclipBinds) do
  v:unbind()
end

-----------------
-- WEdit Tools --
-----------------

--[[
  Returns parameters for a trianglium ore used for WEdit tools.
  Vanilla parameters such as blueprints and radio messages are removed.
  @param shortDescription - Visual item name, used to identify WEdit functions.
  @param description - Item description displayed in the item tooltip.
  @param category - Item header, displayed below the item shortDescription.
  @param inventoryIcon - Path to an icon. Supports directives.
  @param rarity - Item rarity. Defaults to common.
  @return - Altered item parameters (for a triangliumore).
]]
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

----------
-- Done --
----------

-- Load config once while still initializing.
controller.updateUserConfig(true)

-- Script loaded.
loadTime = os.clock() - startTime
sb.logInfo("WEdit Controller: Initialized WEdit in %s seconds", loadTime)
