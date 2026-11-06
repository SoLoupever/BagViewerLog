local addonName, ns = ...

-- Objets récents : un objet dont la quantité augmente passe dans la catégorie
-- "Nouveaux objets" pendant DURATION secondes, puis retourne dans sa catégorie.
-- Sac ouvert, un objet expiré reste en "nouveaux" ; il part à la fermeture.
-- Suivi aussi sac fermé (INVENTORY_SCANNED est émis dans les deux cas).

local DURATION = 15

local recent = {}   -- itemID -> expiration (GetTime)
local last          -- totaux du scan précédent
local holding = false

ns.Recent = {}

function ns.Recent.IsRecent(itemID)
    local t = recent[itemID]
    return t ~= nil and (holding or t > GetTime())
end

-- Délai en cours (hors maintien sac ouvert).
local function Running(itemID)
    local t = recent[itemID]
    return t ~= nil and t > GetTime()
end

ns.RegisterCategory({
    id = "new", labelKey = "CAT_NEW", order = 0, priority = 0, noAssign = true,
    match = function(item) return ns.Recent.IsRecent(item.id) end,
})

local function Purge()
    local now = GetTime()
    for id, t in pairs(recent) do
        if t <= now then recent[id] = nil end
    end
end

local function Expire()
    if not holding then Purge() end
end

-- Ouverture : les expirés sont déjà partis avant le classement.
ns.On("INVENTORY_ACTIVE", function(on)
    if on then
        Purge()
        holding = true
    else
        holding = false
        Purge()
    end
end)

ns.On("INVENTORY_SCANNED", function(totals)
    if last then
        local now, found = GetTime(), false
        for id, n in pairs(totals) do
            -- Délai en cours : il n'est pas prolongé.
            if n > (last[id] or 0) and not Running(id) then
                recent[id] = now + DURATION
                found = true
            end
        end
        if found then C_Timer.After(DURATION + 0.1, Expire) end
    end
    last = totals
end)
