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

-- itemIDs classés à la main dans la catégorie (triés), remplit out.
function ns.Assign.GetItems(catID, out)
    out = out or {}
    wipe(out)
    for itemID, id in pairs(Store()) do
        if id == catID then out[#out + 1] = itemID end
    end
    table.sort(out)
    return out
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
