function init()
  if status.statusProperty("wedit.liquidPicker.open") then
    forceClosed = true
    pane.dismiss()
    return
  end

   status.setStatusProperty("wedit.liquidPicker.open", true)
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.liquidPicker.open", nil)
  end
end

function pickLiquid(w, data)
  world.sendEntityMessage(player.id(), "wedit.updateLiquid", data)
end