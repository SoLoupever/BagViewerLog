local addonName, ns = ...

-- Composants d'artisanat (flag isCraftingReagent de GetItemInfo), cache par objet.
-- Tout objet du sac de composants en est un.

local GetItemInfo = C_Item.GetItemInfo
local REAGENT_INDEX = 17   -- isCraftingReagent dans les retours de GetItemInfo
local REAGENT_BAG = Enum.BagIndex.ReagentBag

local cache = {}

ns.Reagent = {}

-- entry : objet du snapshot (id, bag).
function ns.Reagent.Is(entry)
    local id = entry.id
    if not id then return false end
    local r = cache[id]
    if r == nil then
        r = select(REAGENT_INDEX, GetItemInfo(id))
        -- Données pas encore en cache client : on réessaiera au prochain rendu.
        if r ~= nil then cache[id] = r end
    end
    return r == true or entry.bag == REAGENT_BAG
end
