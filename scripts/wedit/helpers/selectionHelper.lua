local SelectionHelper = {}
module = SelectionHelper

SelectionHelper.selection = nil

function SelectionHelper.isValid()
  return not not SelectionHelper.selection
end

function SelectionHelper.getSelection()
  return SelectionHelper.selection
end

function SelectionHelper.getStart()
  return SelectionHelper.selection and SelectionHelper.selection.bl
end

function SelectionHelper.getEnd()
  return SelectionHelper.selection and SelectionHelper.selection.tr
end

function SelectionHelper.setSelection(rect)
  SelectionHelper.selection = rect
end

function SelectionHelper.clearSelection()
  SelectionHelper.selection = nil
end

function SelectionHelper.render(debugRenderer)
  if not SelectionHelper.isValid() then return end
  local s, e = SelectionHelper.getStart(), SelectionHelper.getEnd()
  debugRenderer:drawRectangle(s, e)
  debugRenderer:drawText(
    string.format("^shadow;WEdit Selection (%sx%s)", e[1] - s[1], e[2] - s[2]),
    { s[1], e[2] + 1 },
    "green"
  )
end
