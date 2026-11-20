local addonName, ns = ...

-- Clé mythique+ : détection, niveau et catégorie dédiée.

local IsItemKeystoneByID = C_Item.IsItemKeystoneByID

local isKey = {}   -- itemID -> bool

ns.Keystone = {}

function ns.Keystone.IsKeystone(entry)
    local id = entry.id
    if not id then return false end
    local v = isKey[id]
    if v == nil then
        v = IsItemKeystoneByID(id)
        isKey[id] = v
    end
    return v
end

-- Clé du sac = celle du joueur : niveau en direct, sinon lien keystone:itemID:mapID:niveau.
function ns.Keystone.GetLevel(entry)
    if not ns.Keystone.IsKeystone(entry) then return nil end
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if level and level > 0 then return level end
    level = entry.link and entry.link:match("keystone:%d+:%d+:(%d+)")
    return level and tonumber(level)
end

-- Le niveau change sans vider l'emplacement : relance un rendu.
local queued = false
local function QueueRefresh()
    if queued then return end
    queued = true
    C_Timer.After(0.3, function()
        queued = false
        ns.Fire("CATEGORIES_CHANGED")
    end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ITEM_CHANGED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("CHALLENGE_MODE_RESET")
frame:SetScript("OnEvent", function(_, event, _, newLink)
    if event == "ITEM_CHANGED" and not (newLink and newLink:find("keystone:", 1, true)) then return end
    QueueRefresh()
end)

ns.RegisterCategory({
    id = "keystone", labelKey = "CAT_KEYSTONE", order = 5, priority = 5,
    match = ns.Keystone.IsKeystone,
})
