function init()
  -- Prevent multiples matmod pickers.
  -- If the value is somehow true while the interface is closed, a reload should fix this.
  -- weditController.lua forces them back to false on init.
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
