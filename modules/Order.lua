local addonName, ns = ...

-- Ordre des catégories choisi par le joueur, par groupe de frères (racines ou
-- enfants d'un parent). Réglage "order" = { [parentID | "root"] = { ids } }.

local ROOT = "root"

ns.Order = {}

local function Store()
    return ns.Settings.Table("order")
end

local function Siblings(parent)
    local src = parent and ns.GetChildren(parent) or ns.GetTopCategories()
    local ids = {}
    for i = 1, #src do ids[i] = src[i].id end
    return ids
end

local function IndexOf(ids, id)
    for i = 1, #ids do
        if ids[i] == id then return i end
    end
end

local function Save(parent, ids)
    Store()[parent or ROOT] = ids
    ns.SetCategoryOrder(parent, ids)
    ns.Fire("CATEGORIES_CHANGED")
end

-- dir = -1 monte, 1 descend ; les catégories système sont enjambées.
function ns.Order.Move(id, dir)
    local def = ns.GetCategory(id)
    if not def then return end
    local ids = Siblings(def.parent)
    local i = IndexOf(ids, id)
    local j = i + dir
    while ids[j] do
        local d = ns.GetCategory(ids[j])
        if d and not d.noAssign then break end
        j = j + dir
    end
    if not ids[j] then return end
    table.remove(ids, i)
    table.insert(ids, j, id)
    Save(def.parent, ids)
end

-- Place id juste avant (ou après) targetID, au sein du même groupe.
function ns.Order.MoveTo(id, targetID, after)
    local def, target = ns.GetCategory(id), ns.GetCategory(targetID)
    if not def or not target or id == targetID or def.parent ~= target.parent then return end
    local ids = Siblings(def.parent)
    table.remove(ids, IndexOf(ids, id))
    local t = IndexOf(ids, targetID)
    table.insert(ids, after and t + 1 or t, id)
    Save(def.parent, ids)
end

-- Catégorie supprimée : elle sort des listes.
ns.On("CATEGORY_REMOVED", function(catID)
    local store = Store()
    store[catID] = nil
    for key, ids in pairs(store) do
        local i = IndexOf(ids, catID)
        if i then
            table.remove(ids, i)
            ns.SetCategoryOrder(key ~= ROOT and key or nil, ids)
        end
    end
end)

for key, ids in pairs(Store()) do
    ns.SetCategoryOrder(key ~= ROOT and key or nil, ids)
end
