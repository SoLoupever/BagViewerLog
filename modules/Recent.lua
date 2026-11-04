local addonName, ns = ...

-- Objets récents : un objet dont la quantité augmente passe dans la catégorie
-- "Nouveaux objets" pendant DURATION secondes, puis retourne dans sa catégorie.
-- Suivi uniquement sac ouvert (base remise à zéro à la fermeture).

local DURATION = 8

local recent = {}   -- itemID -> expiration (GetTime)
local last          -- totaux du scan précédent

ns.Recent = {}

function ns.Recent.IsRecent(itemID)
    local t = recent[itemID]
    return t ~= nil and t > GetTime()
end

ns.RegisterCategory({
    id = "new", labelKey = "CAT_NEW", order = 0, priority = 0, noAssign = true,
    match = function(item) return ns.Recent.IsRecent(item.id) end,
})

ns.On("INVENTORY_SCANNED", function(totals)
    if last then
        local now = GetTime()
        for id, n in pairs(totals) do
            if n > (last[id] or 0) then
                recent[id] = now + DURATION
                C_Timer.After(DURATION + 0.1, function() ns.Fire("RECENT_EXPIRED") end)
            end
        end
    end
    last = totals
end)

ns.On("FRAME_HIDDEN", function()
    last = nil
    wipe(recent)
end)
