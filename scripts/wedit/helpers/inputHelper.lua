local InputHelper = {}
module = InputHelper

function InputHelper.update(args)
  InputHelper.primary = args.moves.primaryFire
  InputHelper.alt = args.moves.altFire
  InputHelper.shift = not args.moves.run

  -- Unlock when mouse buttons are not held.
  if InputHelper.locked and not InputHelper.primary and not InputHelper.alt then
    InputHelper.unlock();
  end

  -- Unlock when shift and mouse buttons are not held.
  if InputHelper.shiftLocked and not InputHelper.shift and not InputHelper.primary and not InputHelper.alt then
    InputHelper.shiftUnlock()
  end
end

function InputHelper.lock() InputHelper.locked = true end
function InputHelper.shiftLock() InputHelper.shiftLocked = true; InputHelper.lock() end

function InputHelper.isLocked() return InputHelper.locked end
function InputHelper.isShiftLocked() return InputHelper.shiftLocked or InputHelper.isLocked() end

function InputHelper.unlock() InputHelper.locked = nil end
function InputHelper.shiftUnlock() InputHelper.shiftLocked = nil end

function InputHelper.log()
  sb.logInfo("Primary: %s, Alt: %s, Shift: %s", InputHelper.primary, InputHelper.alt, InputHelper.shift)
  sb.logInfo("Lock: %s, Shift lock: %s", InputHelper.isLocked(), InputHelper.isShiftLocked())
end
