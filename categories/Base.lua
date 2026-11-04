local addonName, ns = ...

-- Catégories de base, par classe d'objet (Enum.ItemClass).

local IC = Enum.ItemClass

local function ByClass(...)
    local set = {}
    for i = 1, select("#", ...) do set[select(i, ...)] = true end
    return function(item) return set[item.classID] == true end
end

ns.RegisterCategory({
    id = "junk", labelKey = "CAT_JUNK", order = 70, priority = 1,
    match = function(item) return item.quality == Enum.ItemQuality.Poor end,
})

ns.RegisterCategory({
    id = "quest", labelKey = "CAT_QUEST", order = 50, priority = 2,
    match = ByClass(IC.Questitem),
})

ns.RegisterCategory({
    id = "equipment", labelKey = "CAT_EQUIPMENT", order = 10, priority = 3,
    match = ByClass(IC.Weapon, IC.Armor, IC.Profession),
})

ns.RegisterCategory({
    id = "consumable", labelKey = "CAT_CONSUMABLE", order = 20, priority = 4,
    match = ByClass(IC.Consumable, IC.ItemEnhancement),
})

ns.RegisterCategory({
    id = "tradegoods", labelKey = "CAT_TRADEGOODS", order = 30, priority = 5,
    match = ByClass(IC.Tradegoods, IC.Gem, IC.Reagent),
})

ns.RegisterCategory({
    id = "recipe", labelKey = "CAT_RECIPE", order = 40, priority = 6,
    match = ByClass(IC.Recipe),
})

ns.RegisterCategory({
    id = "misc", labelKey = "CAT_MISC", order = 60, priority = 7,
    match = ByClass(IC.Miscellaneous, IC.Container, IC.Key, IC.Battlepet,
                    IC.WoWToken, IC.Glyph, IC.Housing),
})

-- Repli.
ns.RegisterCategory({
    id = "other", labelKey = "CAT_OTHER", order = 80, priority = 99,
})
