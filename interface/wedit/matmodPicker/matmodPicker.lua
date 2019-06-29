function init()
  if status.statusProperty("wedit.matmodPicker.open") then
    forceClosed = true
    pane.dismiss()
    return
  end

  status.setStatusProperty("wedit.matmodPicker.open", true)
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.matmodPicker.open", nil)
  end
end

function pickMod(w, data)
  world.sendEntityMessage(player.id(), "wedit.updateMatmod", data)
end
