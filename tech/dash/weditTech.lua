require "/scripts/wedit/controller.lua"

-- Hook init to initialize wedit.
local ini = init
function init()
  ini()
  wedit.controller.init()
end

-- Hook update to update wedit.
local upd = update
update = function(...)
  upd(...)
  wedit.controller.update(...)
end

-- Hook uninit to uninitialize wedit.
local uni = uninit
uninit = function()
  uni()
  wedit.controller.uninit()
end