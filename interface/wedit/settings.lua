--- https://github.com/Silverfeelin/Starbound-WEdit

weditInterface = {}

local widgets = {
  noclipBind = "weditScroll.noClipBind",
  noclipSpeed = "weditScroll.noClipSpeed",
  delay = "weditScroll.delay",
  clearSchematics = "weditScroll.clearSchematics",
  lineSpacing = "weditScroll.lineSpacing",
  brushShape = "weditScroll.brushShape",
  pencilSize = "weditScroll.pencilSize",
  blockSize = "weditScroll.blockSize",
  matmodSize = "weditScroll.matmodSize"
}

local brushShapes = {
  square = -1,
  circle = 0
}

function init()
  widget.setText(widgets.noclipBind, weditInterface.getConfigData("noclip.bind") or "specialTwo")
  widget.setText(widgets.noclipSpeed, weditInterface.getConfigData("noclipSpeed") or 0.75)
  widget.setChecked(widgets.clearSchematics, false)
  widget.setText(widgets.lineSpacing, weditInterface.getConfigData("info.lineSpacing") or 1)
  widget.setSelectedOption(widgets.brushShape, weditInterface.getConfigData("brushShapeIndex") or -1)
  widget.setText(widgets.pencilSize, weditInterface.getConfigData("pencilSize") or 1)
  widget.setText(widgets.blockSize, weditInterface.getConfigData("blockSize") or 1)
  widget.setText(widgets.matmodSize, weditInterface.getConfigData("matmodSize") or 1)
end

function weditInterface.setConfigData(key, value)
  status.setStatusProperty("wedit." .. key, value)
end

function weditInterface.getConfigData(key, default)
  local config = status.statusProperty("wedit." .. key)
  if config ~= nil then return config else return default end
end

function weditInterface.changeNoClipBind()
  local bind = widget.getText(widgets.noclipBind)
  world.sendEntityMessage(player.id(), "wedit.noclip.setBind", bind)
end

function weditInterface.changeNoClipSpeed()
  local speed = tonumber(widget.getText(widgets.noclipSpeed)) or 0.75
  world.sendEntityMessage(player.id(), "wedit.noclip.setSpeed", speed)
end

function weditInterface.changeClearSchematics()
  weditInterface.setConfigData("clearSchematics", widget.getChecked(widgets.clearSchematics))
end

function weditInterface.changeLineSpacing()
  local spacing = tonumber(widget.getText(widgets.lineSpacing)) or 1
  world.sendEntityMessage(player.id(), "wedit.info.setLineSpacing", spacing)
end

function weditInterface.changeBrushShape(_, data)
  local cfg = status.statusProperty("wedit.brush") or {}
  cfg.shape = data
  cfg.shapeIndex = brushShapes[data]
  status.setStatusProperty("wedit.brush", cfg)
  
  world.sendEntityMessage(player.id(), "wedit.updateBrush")
end

function weditInterface.changePencilSize()
  local size = tonumber(widget.getText(widgets.pencilSize)) or 1

  local cfg = status.statusProperty("wedit.brush") or {}
  cfg.pencilSize = size
  status.setStatusProperty("wedit.brush", cfg)

  world.sendEntityMessage(player.id(), "wedit.updateBrush")
end

function weditInterface.changeBlockSize()
  local size = tonumber(widget.getText(widgets.blockSize)) or 1

  local cfg = status.statusProperty("wedit.brush") or {}
  cfg.blockSize = size
  status.setStatusProperty("wedit.brush", cfg)

  world.sendEntityMessage(player.id(), "wedit.updateBrush")
end

function weditInterface.changeMatmodSize()
  local size = tonumber(widget.getText(widgets.matmodSize)) or 1
  
  local cfg = status.statusProperty("wedit.brush") or {}
  cfg.modSize = size
  status.setStatusProperty("wedit.brush", cfg)

  world.sendEntityMessage(player.id(), "wedit.updateBrush")
end
