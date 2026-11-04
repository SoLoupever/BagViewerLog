local addonName, ns = ...

-- Catégories et sous-catégories créées par le joueur (un seul niveau de profondeur).
-- Persistées dans les réglages : { { id, name, parent } }.

local FIRST_ORDER = 100

ns.Custom = {}

local function List()
    return ns.Settings.Table("custom")
end

local function Register(entry, index)
    ns.RegisterCategory({
        id = entry.id, label = entry.name, parent = entry.parent,
        order = FIRST_ORDER + index, custom = true,
    })
end

local function RegisterAll()
    for i, e in ipairs(List()) do Register(e, i) end
end

function ns.Custom.Add(name, parent)
    if parent then
        local p = ns.GetCategory(parent)
        if not p or p.parent then return end
    end
    local seq = (ns.Settings.Get("customSeq") or 0) + 1
    ns.Settings.Set("customSeq", seq)

    local list = List()
    local entry = { id = "custom" .. seq, name = name, parent = parent }
    list[#list + 1] = entry
    Register(entry, #list)
    ns.Fire("CATEGORIES_CHANGED")
end

function ns.Custom.Rename(id, name)
    for _, e in ipairs(List()) do
        if e.id == id then
            e.name = name
            ns.GetCategory(id).label = name
            ns.Fire("CATEGORIES_CHANGED")
            return
        end
    end
end

-- Supprime la catégorie et ses sous-catégories.
function ns.Custom.Remove(id)
    local list, kept = List(), {}
    for _, e in ipairs(list) do
        if e.id == id or e.parent == id then
            ns.UnregisterCategory(e.id)
            ns.Fire("CATEGORY_REMOVED", e.id)
        else
            kept[#kept + 1] = e
        end
    end
    wipe(list)
    for i, e in ipairs(kept) do
        list[i] = e
        Register(e, i)
    end
    ns.Fire("CATEGORIES_CHANGED")
end

RegisterAll()
