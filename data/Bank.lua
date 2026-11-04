local addonName, ns = ...

-- Données de banque : registre de types (personnage, bataillon), onglets via
-- C_Bank, objets via ViewerLogAPI (fournis par chaque type : getData).
-- def = { id, labelKey, order, bankType (Enum.BankType), getData(tabID) }.

ns.Bank = {}

local types, sorted = {}, nil
local active, scheduled = false, false

function ns.Bank.RegisterType(def)
    types[def.id] = def
    sorted = nil
end

function ns.Bank.GetType(id)
    return types[id]
end

-- Types consultables à ce banquier.
function ns.Bank.GetTypes()
    if not sorted then
        sorted = {}
        for _, d in pairs(types) do sorted[#sorted + 1] = d end
        table.sort(sorted, function(a, b) return a.order < b.order end)
    end
    local list = {}
    for _, d in ipairs(sorted) do
        if C_Bank.CanViewBank(d.bankType) then list[#list + 1] = d end
    end
    return list
end

-- { { ID, name, icon, ... } } des onglets achetés.
function ns.Bank.GetTabs(id)
    local d = types[id]
    return d and C_Bank.FetchPurchasedBankTabData(d.bankType) or {}
end

-- Un élément par emplacement de l'onglet, dans l'ordre : objet ou vide.
function ns.Bank.GetSlots(id, tabID)
    local d = types[id]
    local list = {}
    if not d then return list end

    local data = d.getData(tabID)
    for slot = 1, C_Container.GetContainerNumSlots(tabID) or 0 do
        local e = data and data[slot]
        if e then
            local s = ns.GetItemStatic(e.id)
            list[slot] = {
                bag = tabID, slot = slot, id = e.id, count = e.count, link = e.link,
                icon = s.icon, classID = s.classID, subClassID = s.subClassID,
                quality = s.quality,
                name = e.link and e.link:match("%[(.-)%]"),
            }
        else
            list[slot] = { bag = tabID, slot = slot }
        end
    end
    return list
end

-- Tous les onglets du type fusionnés, classés par catégorie comme le sac :
-- { groups = { catID -> objets }, free = { emplacements vides }, numTabs }.
function ns.Bank.GetSnapshot(id)
    local groups, free = {}, {}
    local tabs = ns.Bank.GetTabs(id)
    for _, tab in ipairs(tabs) do
        for _, e in ipairs(ns.Bank.GetSlots(id, tab.ID)) do
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
    return { groups = groups, free = free, numTabs = #tabs }
end

-- Actif : suit les changements (BANK_CHANGED). Le scanner de ViewerLog_Items
-- n'écrit qu'après l'ouverture : un second rafraîchissement le rattrape.
function ns.Bank.SetActive(on)
    active = on
    if on then
        C_Timer.After(1.5, function()
            if active then ns.Fire("BANK_CHANGED") end
        end)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function()
    if not active or scheduled then return end
    scheduled = true
    C_Timer.After(0.1, function()
        scheduled = false
        if active then ns.Fire("BANK_CHANGED") end
    end)
end)
