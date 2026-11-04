local addonName, ns = ...

-- Pastille du niveau d'objet, coin bas-gauche, couleur de la qualité.

local GetItemQualityColor = C_Item.GetItemQualityColor

ns.UI.RegisterBadge({
    id = "ilvl", point = "BOTTOMLEFT", offsetX = 3, offsetY = 2,
    get = function(entry)
        local ilvl = ns.ItemLevel.Get(entry)
        if not ilvl then return nil end
        if entry.quality then return ilvl, GetItemQualityColor(entry.quality) end
        return ilvl
    end,
})
