local interface = {}

function init()
  status.setStatusProperty("wedit.compact.action", widget.getData("data") or "WE_Select")
  status.setStatusProperty("wedit.compact.open", true)
end

function uninit()
  status.setStatusProperty("wedit.compact.open", false)
end

function actionSelected(_, action)
  status.setStatusProperty("wedit.compact.action", action)
  widget.setData("data", action)
end
