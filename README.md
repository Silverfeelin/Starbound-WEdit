# Starbound WEdit
WEdit is a tech mod that allows you to edit the world around you on a larger scale through various functions and features not present in the game.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Using a different tech](#using-a-different-tech)
- [Features](#features)
- [Planned](#planned)
- [Potential Issues](#potential-issues)
- [Contributing](#contributing)
- [Licenses](#licenses)

## Installation
* [Download](https://github.com/Silverfeelin/Starbound-WEdit/releases) the release for the current version of Starbound.
* Place the `WEdit.pak` file in your mods folder (eg. `D:\Steam\steamapps\common\Starbound\mods\`). Overwrite the existing file if necessary.
* Activate the `dash` tech on your character.
 * In singleplayer, use `/enabletech dash` and `/spawnitem techconsole` with your cursor pointed near your character. Place the tech console down and activate the tech from the tech console.
* Bind `WEdit Toggle Noclip` in the controls menu. In `/debug`, it will show *Press 'g'* regardless of your choice.
 * The actual bind used is `PlayerTechAction2`. Other mods that use this bind may cause conflicts.

## Usage
> It is recommended to have `/debug` on at all times while using WEdit. Although WEdit will function fine without enabling the debug mode, vital information can only be seen with this mode enabled.  
> If `/debug` does not work for you, manually set `allowAdminCommandsFromAnyone` to true in your `/storage/starbound.config`.

To use any of the features WEdit offers, you must first obtain all WEdit Tools.

By opening your basic crafting menu (`C` by default), you can craft the `WE_ItemBox`. Note that this will add a bunch of items to your tools/etc. tab in your inventory when used. If there's not enough space in your inventory, the items will be dropped on the ground at the position of your character.  
Just like any other WEdit tool, this tool requires the `dash` tech to be active on your character to function.

You can also obtain them by running the below command in singleplayer. The command will spawn the item at the position of your cursor.  
If you can't paste the command, your copy probably ends with a line break character. Line breaks prevent pasting in chat, so make sure you've only copied the actual command!
```
/spawnitem silverore 1 '{"itemTags":[], "radioMessagesOnPickup":[], "learnBlueprintsOnPickup":[], "twoHanded":true, "shortdescription":"WE_ItemBox", "category":"^orange;WEdit: Item Box", "description":"^yellow;^yellow;Primary Fire: Spawn Tools.^reset;", "inventoryIcon":"/objects/floran/chestfloran1/chestfloran1icon.png"}'
```

By holding one of the WEdit tools, you can access the corresponding feature. The usage of each feature is described in the [Wiki - Features](https://github.com/Silverfeelin/Starbound-WEdit/wiki/Features) section. Generally, the left and right mouse buttons (primary fire and alt fire) are used to activate the items.

You can also toggle the built-in noclip mode by pressing your second tech action key (`G` by default).

## Using a different tech
* Unpack `WEdit.pak`.
* Remove `/tech/dash/dash.lua` from the unpacked mod.
* Copy a different tech script from unpacked assets for the current version of the game.
* Place the copied tech script in the unpacked WEdit folder. Make sure the file name and directories match up with those of the game assets (eg. `\assets\tech\jump\multijump.lua` to `\unpackedWEdit\tech\jump\multijump.lua`).
* Open the new tech script in a text editor of your choice.
* Start a new line following the line `function init()`, and place the code below on this new line.
```
require "/scripts/weditController.lua"
```
* Save the file.
* Delete the original packed mod.
* (Optional) Repack the unpacked and updated mod.
* (Optional) Enable the new tech using `/enabletech <techname>` in singleplayer. Activate the tech through a tech console, obtainable by using the command `/spawnitem techconsole`.

## Features
A full list of features can be found on the [WEdit Wiki](https://github.com/Silverfeelin/Starbound-WEdit/wiki).

## Planned
No additional features planned yet. Feel free to suggest them [on the discussion page](http://community.playstarbound.com/threads/wedit.116953/)!

## Potential Issues
* Blocks can not be placed directly in front of or behind empty space, when there are no adjacent blocks on the same layer. Some actions may not yield the result you expected initially because of this. The script tries to work around this issue by running the same actions multiple times.
* Server lag can cause synchronization issues; the script continues working while the world hasn't updated yet.
* Undo Tool should not be completely relied upon; it's probably pretty buggy. It is recommended to back up worlds before making any major changes.

## Contributing
If you have any suggestions or feedback that might help improve this mod, please do post them [on the discussion page](http://community.playstarbound.com/threads/wedit.116953/)!
You can also create pull requests and contribute directly to the mod!

## Licenses
Most of the icons used for the tools are courtesy of [Yusuke Kamiyamane](http://p.yusukekamiyamane.com/about/), and can be found in his [Fugue Icons](http://p.yusukekamiyamane.com/) pack. Some have been modified slightly to fit better into the game.
The icon pack mentioned above falls under the [Creative Commons 3.0 license](http://creativecommons.org/licenses/by/3.0/).
