local LiquidHelper = {
  names = {}
}
module = LiquidHelper

function LiquidHelper.getName(liquidId)
  if not LiquidHelper.names[liquidId] then
    local cfg = root.liquidConfig(liquidId)
    LiquidHelper.names[liquidId] = cfg and cfg.config.name
  end
  return LiquidHelper.names[liquidId]
end

function LiquidHelper.place(pos, id)
  world.spawnLiquid(pos, id, 1)
end

function LiquidHelper.fill(shape, id)
  for p in shape:each() do
    LiquidHelper.place(p, id)
  end
end

function LiquidHelper.remove(pos)
  world.destroyLiquid(pos)
end

function LiquidHelper.clear(shape)
  for p in shape:each() do
    LiquidHelper.drain(p)
  end
end
