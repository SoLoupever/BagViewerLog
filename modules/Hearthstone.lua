local addonName, ns = ...

-- Pierre de foyer : l'objet renvoyé par C_Container.PlayerHasHearthstone.

local hearthID   -- itemID, false si aucune, nil = à relire

local function Get()
    if hearthID == nil then
        hearthID = C_Container.PlayerHasHearthstone() or false
    end
    return hearthID
end

ns.On("INVENTORY_SCANNED", function() hearthID = nil end)

ns.RegisterCategory({
    id = "hearthstone", labelKey = "CAT_HEARTHSTONE", order = 8, priority = 7,
    match = function(item) return item.id ~= nil and item.id == Get() end,
})
