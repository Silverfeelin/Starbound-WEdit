require "/scripts/wedit/controller.lua"

-- Hook init to initialize wedit.
local ini = init
function init()
  if ini then ini() end
  wedit.controller.init()
end

-- Hook update to update wedit.
local upd = update
update = function(...)
  if upd then upd(...) end
  wedit.controller.update(...)
end

-- Hook uninit to uninitialize wedit.
local uni = uninit
uninit = function()
  if uni then uni() end
  wedit.controller.uninit()
end