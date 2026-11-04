local addonName, ns = ...

-- Niveau d'objet des pièces équipables. Résultat mis en cache par lien
-- (le lien porte les bonus : amélioration, contexte...).

local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo

local CLASSES = {
    [Enum.ItemClass.Weapon]     = true,
    [Enum.ItemClass.Armor]      = true,
    [Enum.ItemClass.Profession] = true,
}

local cache = {}

ns.ItemLevel = {}

-- entry : objet du snapshot (link, classID). Renvoie le niveau ou nil.
function ns.ItemLevel.Get(entry)
    local link = entry.link
    if not link or not CLASSES[entry.classID] then return nil end

    local ilvl = cache[link]
    if ilvl == nil then
        ilvl = GetDetailedItemLevelInfo(link)
        -- Données pas encore en cache client : on réessaiera au prochain rendu.
        if ilvl then cache[link] = ilvl end
    end
    return ilvl
end
