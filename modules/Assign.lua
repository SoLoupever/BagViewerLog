local addonName, ns = ...

-- Classement manuel : itemID -> catégorie (prioritaire sur les règles).

ns.Assign = {}

local function Store()
    return ns.Settings.Table("assign")
end

function ns.Assign.Set(itemID, catID)
    Store()[itemID] = catID
    ns.Fire("ASSIGN_CHANGED")
end

function ns.Assign.Clear(itemID)
    Store()[itemID] = nil
    ns.Fire("ASSIGN_CHANGED")
end

ns.RegisterOverride(function(item)
    return Store()[item.id]
end)

-- Catégorie supprimée : ses classements disparaissent.
ns.On("CATEGORY_REMOVED", function(catID)
    local store = Store()
    for itemID, id in pairs(store) do
        if id == catID then store[itemID] = nil end
    end
end)
