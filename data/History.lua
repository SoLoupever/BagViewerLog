local addonName, ns = ...

-- Historique ViewerLog (lecture seule) : sacs / banque d'un personnage connu et
-- banque de bataillon. Une vue = ns.History.RegisterView({ id, labelKey, order,
-- shared (indépendante du personnage), getData(name, realm) -> { bagID -> { slot -> entrée } } }).
-- Snapshot par vue, reconstruit seulement s'il est périmé. Chaque conteneur
-- source devient un conteneur virtuel (ns.HBAG_BASE + 100 + bagID).

ns.History = {}

local views, sorted = {}, nil
local char, realm                -- personnage consulté (défaut : le joueur)
local snaps, stale, built = {}, {}, {}
local ids = {}                   -- bagID source (réutilisé)

function ns.History.RegisterView(def)
    views[def.id] = def
    sorted = nil
end

function ns.History.GetView(id)
    return views[id]
end

function ns.History.GetViews()
    if not sorted then
        sorted = {}
        for _, d in pairs(views) do sorted[#sorted + 1] = d end
        table.sort(sorted, function(a, b) return a.order < b.order end)
    end
    return sorted
end

function ns.History.GetChar()
    return char or UnitName("player"), realm or GetRealmName()
end

function ns.History.GetCharData()
    local name, realmName = ns.History.GetChar()
    return ns.vl.GetCharacter(name, realmName)
end

-- { { name, realm, class } } trié par serveur puis nom.
function ns.History.GetChars()
    local list = {}
    ns.vl.ForEachCharacter(function(name, realmName, data)
        if data.class then list[#list + 1] = { name = name, realm = realmName, class = data.class } end
    end)
    table.sort(list, function(a, b)
        if a.realm ~= b.realm then return a.realm < b.realm end
        return a.name < b.name
    end)
    return list
end

local function Release()
    for bag in pairs(built) do ns.DropSlots(bag) end
    wipe(built)
    for id in pairs(snaps) do stale[id] = true end
end

function ns.History.SetChar(name, realmName)
    local curName, curRealm = ns.History.GetChar()
    if name == curName and realmName == curRealm then return end
    char, realm = name, realmName
    Release()
    ns.Fire("HISTORY_CHANGED")
end

local function Build(id)
    local def = views[id]
    local snap = snaps[id]
    if not snap then
        snap = { groups = {}, free = {}, numTabs = 0, count = 0 }
        snaps[id] = snap
    end
    local groups = snap.groups
    for _, list in pairs(groups) do wipe(list) end

    local data = def.getData(ns.History.GetChar())
    local numTabs, count = 0, 0
    if data then
        wipe(ids)
        for bagID in pairs(data) do
            if type(bagID) == "number" then ids[#ids + 1] = bagID end
        end
        table.sort(ids)
        for i = 1, #ids do
            local src = ids[i]
            local slots = data[src]
            local last = 0
            for slot in pairs(slots) do
                if type(slot) == "number" and slot > last then last = slot end
            end
            if last > 0 then
                numTabs = numTabs + 1
                local bag = ns.HBAG_BASE + 100 + src
                built[bag] = true
                for slot = 1, last do
                    local e = slots[slot]
                    if type(e) == "number" then e = { id = e, count = 1 } end
                    if e and e.id then
                        local x = ns.FillSlot(bag, slot, e)
                        local cat = ns.ResolveCategory(x)
                        local list = groups[cat]
                        if not list then
                            list = {}
                            groups[cat] = list
                        end
                        list[#list + 1] = x
                        count = count + 1
                    end
                end
            end
        end
    end
    snap.numTabs, snap.count = numTabs, count
    stale[id] = nil
    return snap
end

function ns.History.Get(id)
    if stale[id] or not snaps[id] then Build(id) end
    return snaps[id]
end

-- Actif : les snapshots sont reconstruits. Fermé : tout est libéré.
function ns.History.SetActive(on)
    if on then
        for id in pairs(snaps) do stale[id] = true end
    else
        Release()
        wipe(snaps)
    end
end

-- Le classement change : tout est à reclasser.
for _, ev in ipairs({ "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
    ns.On(ev, function()
        for id in pairs(snaps) do stale[id] = true end
    end)
end
