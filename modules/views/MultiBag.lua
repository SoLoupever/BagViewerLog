local addonName, ns = ...

-- Vue "multi-sacs" : une section par sac (sac à dos, 4 sacs, composants).

local FIRST_BAG, LAST_BAG = 0, 5
local LABELS = {
    [0] = "BAGS_BACKPACK", "VIEW_BAG_1", "VIEW_BAG_2", "VIEW_BAG_3", "VIEW_BAG_4", "VIEW_REAGENT",
}

local TOPS, KEY = {}, {}
for bag = FIRST_BAG, LAST_BAG do
    KEY[bag] = "view_bag" .. bag
    TOPS[#TOPS + 1] = {
        id = KEY[bag], labelKey = LABELS[bag],
        header = true, noAssign = true, count = ns.View.CountText,
    }
end

local out = {}

ns.View.Register({
    id = "multibag", labelKey = "VIEW_MULTIBAG", order = 3,
    noFree = true, stack = false,
    tops   = function() return TOPS end,
    groups = function(snap)
        local bags = ns.View.GetSlots(snap)
        for bag = FIRST_BAG, LAST_BAG do out[KEY[bag]] = bags[bag] end
        return out
    end,
})
