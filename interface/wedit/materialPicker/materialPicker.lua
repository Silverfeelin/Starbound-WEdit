function init()
  -- Prevent multiples material pickers.
  -- If the value is somehow true while the interface is closed, a reload should fix this.
  -- controller.lua forces them back to false on init.
  if status.statusProperty("wedit.materialPicker.open") then
    forceClosed = true
    pane.dismiss()
  end

  status.setStatusProperty("wedit.materialPicker.open", true)
end

function uninit()
  if not forceClosed then
    status.setStatusProperty("wedit.materialPicker.open", nil)
  end
end

function pickMaterial(w, data)
  world.sendEntityMessage(player.id(), "wedit.setMaterial", data)
end
