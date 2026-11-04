local addonName, ns = ...

-- Pastille du niveau de clé mythique+, coin bas-gauche.

local GetKeystoneLevelRarityColor = C_ChallengeMode.GetKeystoneLevelRarityColor

ns.UI.RegisterBadge({
    id = "keystone", point = "BOTTOMLEFT", offsetX = 3, offsetY = 2,
    get = function(entry)
        local level = ns.Keystone.GetLevel(entry)
        if not level then return nil end
        local text = string.format(ns.L("KEYSTONE_LEVEL_FMT"), level)
        local color = GetKeystoneLevelRarityColor(level)
        if color then return text, color:GetRGB() end
        return text
    end,
})
