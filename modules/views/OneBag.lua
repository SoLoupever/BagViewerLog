local addonName, ns = ...

-- Vue "un seul sac" : tous les emplacements des sacs, puis le sac de composants.

local MAIN    = { id = "view_main",    labelKey = "VIEW_MAIN",    header = true, noAssign = true, count = ns.View.CountText }
local REAGENT = { id = "view_reagent", labelKey = "VIEW_REAGENT", header = true, noAssign = true, count = ns.View.CountText }
local TOPS = { MAIN, REAGENT }
local REAGENT_BAG = Enum.BagIndex.ReagentBag
local out = {}

ns.View.Register({
    id = "onebag", labelKey = "VIEW_ONEBAG", order = 2,
    noFree = true, stack = false, bulk = false,
    tops   = function() return TOPS end,
    groups = function(snap)
        local bags, main = ns.View.GetSlots(snap)
        out[MAIN.id], out[REAGENT.id] = main, bags[REAGENT_BAG]
        return out
    end,
})
