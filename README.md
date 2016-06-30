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
* Place the `WEdit.modpak` file in your mods folder (eg. `D:\Steam\steamapps\common\Starbound\mods\`). Overwrite the existing file if necessary.
* Activate the `dash` tech on your character.
 * In singleplayer, use `/enabletech dash` and `/spawnitem techconsole` with your cursor pointed near your character. Place the tech console down and activate the tech from the tech console.

## Usage
> It is recommended to have `/debug` on at all times while using WEdit. Although WEdit will function fine without enabling the debug mode, vital information can only be seen with this mode enabled.

To use any of the features WEdit offers, you must first obtain all WEdit Tools. You can obtain them by running the below command in singleplayer, and then using the item given to you. The command will spawn the item at the position of your cursor.
Note that this will add 13 items to your tools/etc. tab in your inventory. If there's not enough space in your inventory, the items will be dropped on the ground at the position of your character.
```
/spawnitem silverore 1 '{"itemTags":[], "radioMessagesOnPickup":[], "learnBlueprintsOnPickup":[], "twoHanded":true, "shortdescription":"WE_ItemBox", "category":"^orange;WEdit: Item Box", "description":"^yellow;^yellow;Primary Fire: Spawn Tools.^reset;", "inventoryIcon":"/objects/floran/chestfloran1/chestfloran1icon.png"}'
```
By holding one of these tools, you can access the corresponding feature. The usage of each feature is described in the below section [Features](#features). Generally, the left and right mouse buttons (primary fire and alt fire) are used to activate the items.

You can toggle the built-in noclip mode by pressing your second tech action key (`G` by default).

## Using a different tech
* Unpack `WEdit.modpak`.
* Remove `/tech/dash/dash.lua` from the unpacked mod.
* Copy a different tech script from unpacked assets for the current version of the game.
* Place the copied tech script in the unpacked WEdit folder. Make sure the file name and directories match up with those of the game assets (eg. `\assets\tech\jump\multijump.lua` to `\unpackedWEdit\tech\jump\multijump.lua`).
* Open the new tech script in a text editor of your choice.
* Start a new line following the line `function init()`, and place the code below on this new line.
```
require "/scripts/weditController.lua"
```
* Save the file.
* Repack the unpacked mod. Make sure you first delete the original packed mod.
* (Optional) Enable the new tech using `/enabletech <techname>` in singleplayer. Activate the tech through a tech console, obtainable by using the command `/spawnitem techconsole`.

## Features
Quick Navigation: [Selection Tool](#selection-tool), [Layer Tool](#layer-tool), [Color Picker](#color-picker), [Paint Bucket](#paint-bucket), [Eraser](#eraser), [Replace Tool](#replace-tool), [Pencil](#pencil), [Stamp](#stamp), [Modifier](#modifier), [Ruler](#ruler), [Hydrator](#hydrator), [Dehydrator](#dehydrator), [Undo Tool](#undo-tool).

#### Selection Tool
This tool allows you to select an area, which is used by the following tools: [Paint Bucket](#paint-bucket), [Eraser](#eraser), [Replace Tool](#replace-tool), [Stamp](#stamp), [Hydrator](#hydrator), [Dehydrator](#dehydrator).

* Hold the left mouse button down and drag the cursor to select an area. Release the mouse button to confirm your selection.
* Press the right mouse button to remove the current selection.

![Selection Tool](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/selection-new.png "Selection Tool")  
[Back to Features](#features)

#### Layer Tool
This tool allows you to select either the foreground or background layer in the world, which is used by the following tools: [Replace Tool](#replace-tool), [Modifier](#modifier), [Ruler](#ruler).

* Press the left mouse button to select the foreground layer.
* Press the right mouse button to select the background layer.

![Layer Tool](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/layer-new.png "Layer Tool")  
[Back to Features](#features)

#### Color Picker
This tool allows you to select your active block, which is used by the following tools: [Paint Bucket](#paint-bucket), [Replace Tool](#replace-tool), [Pencil](#pencil), [Ruler](#ruler).

* Press the left mouse button while hovering over a block in the foreground to select it.
* Press the right mouse button while hovering over a block in the background to select it.

![Color Picker](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/colorpicker-new.png "Color Picker")  
[Back to Features](#features)

#### Paint Bucket
This tool allows you to fill an empty space in your current selection.  
Requires selections made with the [Selection Tool](#selection-tool) and the [Color Picker](#color-picker).

* Press the left mouse button to fill empty space in the foreground.
* Press the right mouse button to fill empty space in the background.

![Paint Bucket](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/paintbucket-new.png "Paint Bucket")  
[Back to Features](#features)

#### Eraser
This tool allows you to remove all blocks in your current selection.  
Requires selections made with the [Selection Tool](#selection-tool) and the [Color Picker](#color-picker).

* Press the left mouse button to erase blocks in the foreground.
* Press the right mouse button to erase blocks in the background.

![Eraser](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/eraser-new.png "Eraser")  
[Back to Features](#features)

#### Replace Tool
This tool allows you to replace a specific or all blocks in your current selection with a new one.
Requires selections made with the [Selection Tool](#selection-tool), [Layer Tool](#layer-tool) and the [Color Picker](#color-picker).

* Press the left mouse button to replace all blocks matching the one you're currently hovering over.
* Press the right mouse button to replace all blocks.

![Replace Tool](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/replace-new.png "Replace Tool")  
[Back to Features](#features)

#### Pencil
This tool allows you to freely draw. Existing blocks will be replaced when you draw over them.  
Requires a selection made with the [Color Picker](#color-picker).

* Hold the left mouse button down to draw in the foreground.
* Hold the right mouse button down to draw in the background.

![Pencil](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/pencil-new.png "Pencil")  
[Back to Features](#features)

#### Stamp
This tool allows you to copy all blocks, objects, liquids and matmods in your current selection. After that, you can paste the copied area elsewhere.  
Requires a selection made with the [Selection Tool](#selection-tool).

* Press the left mouse button to create a copy of your current selection.
* Press the right mouse button to paste the copy. The bottom left corner of your current selection is used to determine the paste area.

![Stamp](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/stamp-new.png "Stamp")  
[Back to Features](#features)

#### Modifier
This tool allows you to apply matmods to blocks. Matmods are modifications to blocks, such as grass or minerals.  
Requires a selection made with the [Layer Tool](#layer-tool).

* Hold the left mouse button to apply the matmod to blocks you're hovering over.
* Press the right mouse button to scroll through the list of available matmods.

![Modifier](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/modifier-new.png "Modifier")  
[Back to Features](#features)

#### Ruler
This tool allows you to draw straight lines between two points.  
Requires selections made with the [Layer Tool](#layer-tool) and the [Color Picker](#color-picker).

* Press and hold the left mouse button down to make a selection.
* Press the right mouse button to fill the selection.

![Ruler](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/ruler-new.png "Ruler")  
[Back to Features](#features)

#### Hydrator
This tool allows you to fill your current selection with a liquid.  
Requires a selection made with the [Selection Tool](#selection-tool).

* Press the left mouse button to fill the selection.
* Press the right mouse button to scroll through the available liquids.

![Hydrator](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/hydrator-new.png "Hydrator")  
[Back to Features](#features)

#### Dehydrator
This tool allows you to drain all liquids in your current selection.  
Requires a selection made with the [Selection Tool](#selection-tool).

* Press the left mouse button to drain the selection.

![Dehydrator](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/dehydrator-new.png "Dehydrator")  
[Back to Features](#features)

#### Undo Tool
This tool allows you to undo any action from the following tools: [Paint Bucket](#paint-bucket), [Eraser](#eraser), [Replace Tool](#replace-tool), [Stamp](#stamp).

* Press the left mouse button to undo the last step in your undo history.
* Press the right mouse button to remove the last step in your undo history, and thus go back a step.

![Undo Tool](https://raw.githubusercontent.com/Silverfeelin/Starbound-WEdit/master/readme/undo-new.png "Undo Tool")  
[Back to Features](#features)

## Planned
No additional features planned yet. Feel free to suggest them [on the discussion page]!

## Potential Issues
* Blocks can not be placed directly in front of or behind empty space, when there are no adjacent blocks on the same layer. Some actions may not yield the result you expected initially because of this. The script tries to work around this issue by running the same actions multiple times.
* Server lag can cause synchronization issues; the script continues working while the world hasn't updated yet.
* Undo Tool should not be completely relied upon; it's probably pretty buggy. It is recommended to back up worlds before making any major changes.

## Contributing
If you have any suggestions or feedback that might help improve this mod, please do post them [on the discussion page]!
You can also create pull requests and contribute directly to the mod!

## Licenses
Most of the icons used for the tools are courtesy of [Yusuke Kamiyamane](http://p.yusukekamiyamane.com/about/), and can be found in his [Fugue Icons](http://p.yusukekamiyamane.com/) pack. Some have been modified slightly to fit better into the game.
The icon pack mentioned above falls under the [Creative Commons 3.0 license](http://creativecommons.org/licenses/by/3.0/).
