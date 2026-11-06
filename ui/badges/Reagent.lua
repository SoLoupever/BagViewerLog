local addonName, ns = ...

-- Fleur Blizzard des composants, coin haut-droit.

ns.UI.RegisterBadge({
    id = "reagent", atlas = "bags-icon-reagents", size = 14,
    point = "TOPRIGHT", offsetX = -2, offsetY = -2,
    get = function(entry)
        return ns.Reagent.Is(entry) or nil
    end,
})
