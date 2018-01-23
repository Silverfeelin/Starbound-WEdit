local interface = {}
local forceClosed = false

function init()
  -- Prevent multiples dye pickers.
  -- If the value is somehow true while the interface is closed, a reload should fix this.
  -- controller.lua forces them back to false on init.
  if status.statusProperty("wedit.compact.open") then
    forceClosed = true
    pane.dismiss()
  end

  updateToggleInfoButton("toggleInfo", status.statusProperty("wedit.showingInfo"))

  status.setStatusProperty("wedit.compact.action", widget.getData("data") or "WE_Select")
  status.setStatusProperty("wedit.compact.open", true)
end

function update(dt)
  if status.statusProperty("wedit.compact.close", false) then
    status.setStatusProperty("wedit.compact.close", nil)
    pane.dismiss()
  end
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

function toggleInfo(w, data)
  local on = not data
  world.sendEntityMessage(player.id(), "wedit.showInfo", on)
  updateToggleInfoButton(w, on)
end

function updateToggleInfoButton(w, on)
  widget.setData(w, on)
  widget.setButtonImages(w, {
    base = on and "/interface/wedit/compact/infoselected.png" or "/interface/wedit/compact/info.png",
    hover = on and "/interface/wedit/compact/infoselected.png?brightness=15" or "/interface/wedit/compact/info.png?brightness=15"
  })
end
