require "/scripts/wedit/scriptHooks.lua"
require "/scripts/wedit/controller.lua"

hook("init", wedit.controller.init)
hook("update", wedit.controller.update)
hook("uninit", wedit.controller.uninit)
