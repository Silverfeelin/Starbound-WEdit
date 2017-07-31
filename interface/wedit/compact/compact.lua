local interface = {}
local forceClosed = false

function init()
  -- Prevent multiples dye pickers.
  -- If the value is somehow true while the interface is closed, a reload should fix this.
  -- weditController.lua forces them back to false on init.
  if status.statusProperty("wedit.compact.open") then
    forceClosed = true
    pane.dismiss()
  end

  status.setStatusProperty("wedit.compact.action", widget.getData("data") or "WE_Select")
  status.setStatusProperty("wedit.compact.open", true)
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.compact.open", nil)
  end
end

function actionSelected(_, action)
  status.setStatusProperty("wedit.compact.action", action)
  widget.setData("data", action)
end
