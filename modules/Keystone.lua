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

-- Lien keystone:itemID:mapID:niveau:..., sinon la clé possédée par le joueur.
function ns.Keystone.GetLevel(entry)
    if not ns.Keystone.IsKeystone(entry) then return nil end
    local level = entry.link and entry.link:match("keystone:%d+:%d+:(%d+)")
    if level then return tonumber(level) end
    return C_MythicPlus.GetOwnedKeystoneLevel()
end

ns.RegisterCategory({
    id = "keystone", labelKey = "CAT_KEYSTONE", order = 5, priority = 5,
    match = ns.Keystone.IsKeystone,
})
