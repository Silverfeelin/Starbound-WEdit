require "/scripts/wedit/libs/scriptHooks.lua"
require "/scripts/wedit/libs/include.lua"

local InputHelper = include("/scripts/wedit/helpers/inputHelper.lua")
local taskManager = include("/scripts/wedit/helpers/taskManager.lua").instance
local controller = include("/scripts/wedit/controller.lua")
local Noclip = include("/scripts/wedit/helpers/noclip.lua")

require "/scripts/wedit/actions.lua"

hook("init", wedit.init)
hook("init", controller.init)

hook("update",  function() taskManager:update() end)
hook("update", controller.update)
hook("update",  wedit.update)

hook("uninit", controller.uninit)
