local addonName, ns = ...

-- Modes d'affichage du sac (catégories, un seul sac, multi-sacs).
-- def = { id, order, labelKey, tops() -> blocs racines, children(id) (optionnel),
--         groups(snap) -> { blocID -> entrées }, noFree (pas de bloc "Vide"),
--         stack = false (pas de fusion des armes identiques) }.
-- Un bloc avec header = true est une section à en-tête (def.count(liste) -> texte).
-- Une vue ne change que la présentation : le classement reste dans ns.Inventory.

local FIRST_BAG, LAST_BAG = 0, 5

local views, byId, sorted = {}, {}, nil
local enabled = false
local dirty = true
local bags, main = {}, {}   -- sac -> emplacements ; sacs 0..4 réunis

ns.View = {}

function ns.View.Register(def)
    views[#views + 1] = def
    byId[def.id] = def
    sorted = nil
end

function ns.View.GetAll()
    if not sorted then
        sorted = {}
        for i = 1, #views do sorted[i] = views[i] end
        table.sort(sorted, function(a, b) return a.order < b.order end)
    end
    return sorted
end

-- Vues actives seulement si l'UI le demande (panneau latéral présent).
function ns.View.GetCurrent()
    if not enabled then return byId.category end
    return byId[ns.Settings.Get("view")] or byId.category
end

function ns.View.GetCurrentID()
    return ns.View.GetCurrent().id
end

-- Le classement dépend de la vue (fusions) : l'inventaire se reconstruit.
function ns.View.Set(id)
    if not byId[id] or id == ns.View.GetCurrentID() then return end
    ns.Settings.Set("view", id)
    ns.Fire("VIEW_CHANGED", id)
end

function ns.View.SetEnabled(on)
    on = on and true or false
    if on == enabled then return end
    enabled = on
    ns.Fire("VIEW_CHANGED", ns.View.GetCurrentID())
end

-- Une fonction du noyau (ex. "stack") est-elle permise par la vue courante ?
function ns.View.Allows(feature)
    return ns.View.GetCurrent()[feature] ~= false
end

local function Add(e)
    local list = bags[e.bag]
    if not list then
        list = {}
        bags[e.bag] = list
    end
    list[#list + 1] = e
    if e.id then list.used = (list.used or 0) + 1 end
end

-- Tous les emplacements (objets et vides) par sac, dans l'ordre.
-- Recalculé seulement quand l'inventaire a changé.
-- Renvoie bags (bag -> liste) et main (sacs 0 à 4 réunis).
function ns.View.GetSlots(snap)
    if dirty then
        for _, list in pairs(bags) do
            wipe(list)
            list.used = 0
        end
        wipe(main)
        for _, list in pairs(snap.groups) do
            for i = 1, #list do Add(list[i]) end
        end
        for i = 1, #snap.free do Add(snap.free[i]) end
        for i = 1, #snap.freeReagent do Add(snap.freeReagent[i]) end

        local usedMain = 0
        for bag = FIRST_BAG, LAST_BAG do
            local list = bags[bag]
            if not list then
                list = { used = 0 }
                bags[bag] = list
            end
            table.sort(list, function(a, b) return a.slot < b.slot end)
            if bag < LAST_BAG then
                for i = 1, #list do main[#main + 1] = list[i] end
                usedMain = usedMain + list.used
            end
        end
        main.used = usedMain
        dirty = false
    end
    return bags, main
end

-- Texte du compteur d'en-tête : "utilisés / total".
function ns.View.CountText(list)
    return (list.used or 0) .. " / " .. #list
end

ns.On("INVENTORY_CHANGED", function() dirty = true end)
