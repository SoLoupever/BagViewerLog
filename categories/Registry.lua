local addonName, ns = ...

-- Registre de catégories. Un module ajoute la sienne via ns.RegisterCategory.
-- def = { id, labelKey | label (texte libre), order (affichage), priority
--         (résolution, bas = d'abord), match = function(item) -> bool,
--         parent (id d'une catégorie racine), noAssign, custom }.
-- Sans match : catégorie de repli ou manuelle.
-- Surcharges : ns.RegisterOverride(fn(item) -> id|nil), prioritaires.

local cats, overrides = {}, {}
local byPriority, byOrder, tops, kids

local function Invalidate()
    byPriority, byOrder, tops, kids = nil, nil, nil, nil
end

local function BuildLists()
    if byOrder then return end
    byOrder, tops, kids = {}, {}, {}
    for _, def in pairs(cats) do byOrder[#byOrder + 1] = def end
    table.sort(byOrder, function(a, b) return a.order < b.order end)
    for _, def in ipairs(byOrder) do
        if def.parent and cats[def.parent] then
            local list = kids[def.parent]
            if not list then
                list = {}
                kids[def.parent] = list
            end
            list[#list + 1] = def
        else
            tops[#tops + 1] = def
        end
    end
end

function ns.RegisterCategory(def)
    cats[def.id] = def
    Invalidate()
end

function ns.UnregisterCategory(id)
    cats[id] = nil
    Invalidate()
end

function ns.RegisterOverride(fn)
    overrides[#overrides + 1] = fn
end

function ns.GetCategory(id)
    return cats[id]
end

function ns.GetCategoryLabel(def)
    return def.label or ns.L(def.labelKey)
end

function ns.GetTopCategories()
    BuildLists()
    return tops
end

local NONE = {}
function ns.GetChildren(id)
    BuildLists()
    return kids[id] or NONE
end

function ns.ResolveCategory(item)
    for i = 1, #overrides do
        local id = overrides[i](item)
        if id and cats[id] then return id end
    end
    if not byPriority then
        byPriority = {}
        for _, def in pairs(cats) do
            if def.match then byPriority[#byPriority + 1] = def end
        end
        table.sort(byPriority, function(a, b) return a.priority < b.priority end)
    end
    for i = 1, #byPriority do
        if byPriority[i].match(item) then return byPriority[i].id end
    end
    return "other"
end
