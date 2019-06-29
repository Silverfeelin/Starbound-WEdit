local interface = {}
local forceClosed = false

function init()
  if status.statusProperty("wedit.compact.open") then
    forceClosed = true
    pane.dismiss()
  end

  updateToggleInfoButton("toggleInfo", status.statusProperty("wedit.info.visible"))

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
  if forceClosed then return end
  status.setStatusProperty("wedit.compact.open", nil)
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
