local Palette = {
  material = "dirt",
  mod = "grass",
  liquid = {
    name = "water",
    liquidId = 1
  }
}

module = Palette

-- #region Material

function Palette.getMaterial()
  return Palette.material
end

function Palette.getMaterialName(mat)
  if not mat then mat = Palette.material end
  return mat or mat == nil and "none" or mat == false and "air"
end

function Palette.setMaterial(material)
  Palette.material = material
end

function Palette.fromWorld(layer)
  local material = world.material(tech.aimPosition(), layer) or false
  Palette.setMaterial(material)
  return material
end

-- #endregion

-- #region Mod

function Palette.getMod()
  return Palette.mod
end

function Palette.setMod(mod)
  Palette.mod = mod
end

-- #endregion

-- #region Liquid

function Palette.getLiquid()
  return Palette.liquid
end

function Palette.setLiquid(liquid)
  Palette.liquid = liquid
end

-- #endregion
