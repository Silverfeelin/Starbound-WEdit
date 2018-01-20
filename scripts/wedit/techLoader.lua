local ini = init

-- Opens the tech loader interface, unless the player has ignored it or already has the dash tech equipped.
init = function()
  if ini then ini() end
  if not status.statusProperty("weditTechLoaderIgnored", false) and player.equippedTech("body") ~= "dash" then
    player.interact("ScriptPane", "/interface/wedit/techLoader/techLoader.config")
  end
end
