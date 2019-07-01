require "/scripts/wedit/libs/include.lua"

local Actions = {}
module = Actions

-- Load actions
Actions.WE_AllInOne = include("/scripts/wedit/actions/allInOne.lua")
Actions.WE_Block = include("/scripts/wedit/actions/block.lua")
Actions.WE_BlockPinner = include("/scripts/wedit/actions/blockPinner.lua")
Actions.WE_ColorPicker = include("/scripts/wedit/actions/colorPicker.lua")
Actions.WE_Dehydrator = include("/scripts/wedit/actions/dehydrator.lua")
Actions.WE_Dye = include("/scripts/wedit/actions/dye.lua")
Actions.WE_Erase = include("/scripts/wedit/actions/erase.lua")
Actions.WE_Fill = include("/scripts/wedit/actions/fill.lua")
Actions.WE_Flip = include("/scripts/wedit/actions/flip.lua")
Actions.WE_Hydrator = include("/scripts/wedit/actions/hydrator.lua")
Actions.WE_Mod = include("/scripts/wedit/actions/mod.lua")
Actions.WE_Modifier = include("/scripts/wedit/actions/modifier.lua")
Actions.WE_ModPinner = include("/scripts/wedit/actions/modPinner.lua")
Actions.WE_Pencil = include("/scripts/wedit/actions/pencil.lua")
Actions.WE_Replace = include("/scripts/wedit/actions/replace.lua")
Actions.WE_Ruler = include("/scripts/wedit/actions/ruler.lua")
Actions.WE_SchematicMaker = include("/scripts/wedit/actions/schematicMaker.lua")
Actions.WE_Schematic = include("/scripts/wedit/actions/schematic.lua")
Actions.WE_Select = include("/scripts/wedit/actions/select.lua")
Actions.WE_Stamp = include("/scripts/wedit/actions/stamp.lua")
Actions.WE_Undo = include("/scripts/wedit/actions/undo.lua")
