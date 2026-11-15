local addonName, ns = ...

-- Icône du tier de qualité, coin haut-gauche, dans la banque seulement.

ns.UI.RegisterBadge({
    id = "tier", icon = true, size = 18,
    point = "TOPLEFT", offsetX = 2, offsetY = -2,
    get = function(entry)
        if not ns.Bank.IsTab(entry.bag) then return nil end
        return ns.Tier.Get(entry)
    end,
})
