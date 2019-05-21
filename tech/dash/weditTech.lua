require "/scripts/wedit/libs/scriptHooks.lua"
require "/scripts/wedit/libs/include.lua"

local controller = include("/scripts/wedit/controller.lua")
require "/scripts/wedit/actions.lua"

hook("init", controller.init)
hook("update", controller.update)
hook("uninit", controller.uninit)
