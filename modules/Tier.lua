local addonName, ns = ...

-- Tier de qualité d'artisanat (composants et pièces fabriquées).
-- Cache par lien (le lien porte les bonus) ; false = pas de tier.

local GetReagentInfo = C_TradeSkillUI.GetItemReagentQualityInfo
local GetCraftedInfo = C_TradeSkillUI.GetItemCraftedQualityInfo

local MAX_CACHE = 512
local cache, size = {}, 0

ns.Tier = {}

-- entry : objet du snapshot (id, link). Renvoie l'atlas du tier ou nil.
function ns.Tier.Get(entry)
    local key = entry.link or entry.id
    if not key then return nil end

    local atlas = cache[key]
    if atlas == nil then
        local info = GetReagentInfo(key) or GetCraftedInfo(key)
        atlas = info and info.iconInventory or false
        if size >= MAX_CACHE then
            wipe(cache)
            size = 0
        end
        cache[key] = atlas
        size = size + 1
    end
    return atlas or nil
end
