local addonName, ns = ...

-- Données de banque : registre de types (personnage, bataillon), onglets via
-- C_Bank, objets via ViewerLogAPI (fournis par chaque type : getData).
-- def = { id, labelKey, order, bankType (Enum.BankType), getData(tabID) }.
-- Un snapshot par type, reconstruit seulement s'il est périmé ; BANK_CHANGED
-- n'est émis que si le contenu du type affiché a changé.

ns.Bank = {}

local types, sorted = {}, nil
local typeList = {}
local snaps, stale, built = {}, {}, {}   -- id -> snapshot | périmé | tabID -> true
local viewed
local active, scheduled = false, false

function ns.Bank.RegisterType(def)
    types[def.id] = def
    sorted = nil
end

function ns.Bank.GetType(id)
    return types[id]
end

-- Types consultables à ce banquier (liste réutilisée à chaque appel).
function ns.Bank.GetTypes()
    if not sorted then
        sorted = {}
        for _, d in pairs(types) do sorted[#sorted + 1] = d end
        table.sort(sorted, function(a, b) return a.order < b.order end)
    end
    wipe(typeList)
    for i = 1, #sorted do
        local d = sorted[i]
        if C_Bank.CanViewBank(d.bankType) then typeList[#typeList + 1] = d end
    end
    return typeList
end

-- { { ID, name, icon, ... } } des onglets achetés.
function ns.Bank.GetTabs(id)
    local d = types[id]
    return d and C_Bank.FetchPurchasedBankTabData(d.bankType) or {}
end

-- Tous les onglets du type fusionnés, classés par catégorie comme le sac :
-- { groups = { catID -> objets }, free = { emplacements vides }, numTabs }.
-- Renvoie le snapshot et true si son contenu a changé.
local function Build(id)
    local d = types[id]
    local snap = snaps[id]
    if not snap then
        snap = { groups = {}, free = {}, numTabs = 0 }
        snaps[id] = snap
    end
    local groups, free = snap.groups, snap.free
    for _, list in pairs(groups) do wipe(list) end
    wipe(free)

    local dirty = false
    local tabs = ns.Bank.GetTabs(id)
    for _, tab in ipairs(tabs) do
        local tabID = tab.ID
        built[tabID] = true
        local data = d.getData(tabID)
        for slot = 1, C_Container.GetContainerNumSlots(tabID) or 0 do
            local e, changed = ns.FillSlot(tabID, slot, data and data[slot])
            if changed then dirty = true end
            if e.id then
                local cat = ns.ResolveCategory(e)
                local list = groups[cat]
                if not list then
                    list = {}
                    groups[cat] = list
                end
                list[#list + 1] = e
            else
                free[#free + 1] = e
            end
        end
    end
    if #tabs ~= snap.numTabs then dirty = true end
    snap.numTabs = #tabs
    stale[id] = nil
    return snap, dirty
end

function ns.Bank.Get(id)
    viewed = id
    if stale[id] or not snaps[id] then Build(id) end
    return snaps[id]
end

local function MarkStale()
    for id in pairs(snaps) do stale[id] = true end
end

-- Relit le type affiché, les autres seront reconstruits à l'affichage.
local function Refresh()
    if not active or not viewed or not types[viewed] then return end
    local dirty = false
    for id in pairs(snaps) do
        if id == viewed then
            local _, d = Build(id)
            dirty = d
        else
            stale[id] = true
        end
    end
    if dirty then ns.Fire("BANK_CHANGED") end
end

-- Actif : suit les changements. Le scanner de ViewerLog_Items n'écrit qu'après
-- l'ouverture : un second relevé le rattrape. Fermé : tout est libéré.
function ns.Bank.SetActive(on)
    active = on
    if on then
        MarkStale()
        C_Timer.After(1.5, Refresh)
    else
        for tabID in pairs(built) do ns.DropSlots(tabID) end
        wipe(built)
        wipe(snaps)
        wipe(stale)
        viewed = nil
    end
end

-- Le classement change : tout est à reclasser.
for _, ev in ipairs({ "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
    ns.On(ev, MarkStale)
end

local function OnTimer()
    scheduled = false
    Refresh()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function()
    if not active or scheduled then return end
    scheduled = true
    C_Timer.After(0.1, OnTimer)
end)
