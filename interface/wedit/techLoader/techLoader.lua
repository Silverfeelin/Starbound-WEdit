--- Tech Loader interface
-- The tech loader notifies the player they haven't equipped the dash tech yet.
-- The interface should only be opened if the character does not have dash
-- equipped and the status property "weditTechLoaderIgnored" is not set.
--
-- LICENSE
-- This file falls under an MIT License, which is part of this project.
-- An online copy can be viewed via the following link:
-- https://github.com/Silverfeelin/Starbound-WEdit/blob/master/LICENSE

require "/scripts/vec2.lua"

local scrolled = false
local scrollDelay = 1

if not techLoader then
  techLoader = {}
end

function init()
  techLoader.scrollWidgets = config.getParameter("scrollWidgets", {})
  techLoader.scrollPositions = {}
  techLoader.scrollOffset = config.getParameter("scrollOffset", {0,0})

  for _,v in ipairs(techLoader.scrollWidgets) do
    techLoader.scrollPositions[v] = widget.getPosition(v)
    widget.setPosition(v, vec2.add(techLoader.scrollPositions[v], techLoader.scrollOffset))
  end
end

function update(dt)
  if not scrolled then
    techLoader.scrollIn(dt)
  end
end

function techLoader.scrollIn(dt)
  scrollDelay = scrollDelay - dt
  if scrollDelay > 0 then return end

  techLoader.scrollOffset[2] = techLoader.scrollOffset[2] + 60 * dt

  if techLoader.scrollOffset[2] > 0 then
    techLoader.scrollOffset[2] = 0
    scrolled = true
  end

  for k,v in ipairs(techLoader.scrollWidgets) do
    widget.setPosition(v, vec2.add(techLoader.scrollPositions[v], techLoader.scrollOffset))
  end
end

function techLoader.equipTech(w, d)
  player.makeTechAvailable("dash")
  player.enableTech("dash")
  player.equipTech("dash")
  techLoader.dismiss()
end

function techLoader.dismiss()
  pane.dismiss()
end

function techLoader.ignore()
  status.setStatusProperty("weditTechLoaderIgnored", true)
  techLoader.dismiss()
end