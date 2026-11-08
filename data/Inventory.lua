local addonName, ns = ...

-- Données du sac : lecture de ViewerLogAPI.GetBags (ViewerLog_Items), groupées
-- par catégorie. Le nombre d'emplacements vient de C_Container.
-- Reconstruction complète uniquement UI ouverte (SetActive) ; sac fermé, seuls
-- les totaux sont lus (INVENTORY_SCANNED), pour suivre les nouveaux objets.
-- Entrées réutilisées par emplacement ; sans changement, rien n'est notifié.

local C_Container, C_Item = C_Container, C_Item

-- Enum.BagIndex.Backpack .. Enum.BagIndex.ReagentBag
local FIRST_BAG, LAST_BAG = 0, 5
local REAGENT_BAG = Enum.BagIndex.ReagentBag

local static = {}   -- itemID -> { icon, classID, subClassID, quality }
local pool   = {}   -- bagID -> slot -> entrée réutilisée
local snapshot = { groups = {}, free = {}, freeReagent = {}, used = 0, total = 0 }
local items = {}    -- objets du passage en cours
local active, scheduled = false, false

-- Deux tampons alternés : un module garde les totaux du scan précédent.
local buffers, cur = { {}, {} }, 1

local function GetStatic(id)
    local s = static[id]
    if not s then
        local _, _, _, _, icon, classID, subClassID = C_Item.GetItemInfoInstant(id)
        s = { icon = icon, classID = classID, subClassID = subClassID }
        static[id] = s
    end
    if s.quality == nil then s.quality = C_Item.GetItemQualityByID(id) end
    return s
end

ns.GetItemStatic = GetStatic

-- Entrée de (bag, slot), objet (e = { id, count, link }) ou vide (e = nil).
-- Renvoie l'entrée et true si son contenu a changé.
function ns.FillSlot(bag, slot, e)
    local perBag = pool[bag]
    if not perBag then
        perBag = {}
        pool[bag] = perBag
    end
    local x = perBag[slot]
    if not x then
        x = { bag = bag, slot = slot }
        perBag[slot] = x
    end

    if e then
        local id, count, link = e.id, e.count, e.link
        local s = GetStatic(id)
        local changed = x.id ~= id or x.rawCount ~= count or x.link ~= link
                        or x.quality ~= s.quality
        x.id, x.count, x.rawCount, x.link = id, count, count, link
        x.icon, x.classID, x.subClassID, x.quality = s.icon, s.classID, s.subClassID, s.quality
        return x, changed
    end

    local changed = x.id ~= nil
    if changed then
        x.id, x.count, x.rawCount, x.link = nil, nil, nil, nil
        x.icon, x.classID, x.subClassID, x.quality = nil, nil, nil, nil
    end
    return x, changed
end

-- Libère les entrées d'un conteneur (banque fermée).
function ns.DropSlots(bag)
    pool[bag] = nil
end

local function GetBagData()
    return ns.vl.GetBags and ns.vl.GetBags(UnitName("player"), GetRealmName())
end

local function Rebuild(force)
    local bags = GetBagData()
    local totals = buffers[cur]
    wipe(totals)
    wipe(items)
    local groups, free, freeReagent = snapshot.groups, snapshot.free, snapshot.freeReagent
    wipe(free)
    wipe(freeReagent)

    local used, total, n, dirty = 0, 0, 0, false

    for bag = FIRST_BAG, LAST_BAG do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        local bagData  = bags and bags[bag]
        total = total + numSlots

        for slot = 1, numSlots do
            local e = bagData and bagData[slot]
            local x, changed = ns.FillSlot(bag, slot, e)
            if changed then dirty = true end
            if e then
                used = used + 1
                n = n + 1
                items[n] = x
                totals[x.id] = (totals[x.id] or 0) + (x.count or 1)
            else
                local list = bag == REAGENT_BAG and freeReagent or free
                list[#list + 1] = x
            end
        end
    end

    if not (force or dirty or total ~= snapshot.total) then return end

    -- Les modules peuvent réagir aux quantités avant le classement.
    ns.Fire("INVENTORY_SCANNED", totals)
    cur = 3 - cur

    for _, list in pairs(groups) do wipe(list) end
    for i = 1, n do
        local item = items[i]
        local cat = ns.ResolveCategory(item)
        local list = groups[cat]
        if not list then
            list = {}
            groups[cat] = list
        end
        list[#list + 1] = item
    end

    -- Les modules peuvent regrouper les objets d'une catégorie.
    ns.Fire("INVENTORY_GROUPED", groups)

    snapshot.used, snapshot.total = used, total
    ns.Fire("INVENTORY_CHANGED", snapshot)
end

-- Sac fermé : totaux par objet uniquement.
local function ScanTotals()
    local bags = GetBagData()
    if not bags then return end
    local totals = buffers[cur]
    wipe(totals)
    for bag = FIRST_BAG, LAST_BAG do
        local bagData = bags[bag]
        if bagData then
            for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
                local e = bagData[slot]
                if e then totals[e.id] = (totals[e.id] or 0) + (e.count or 1) end
            end
        end
    end
    ns.Fire("INVENTORY_SCANNED", totals)
    cur = 3 - cur
end

ns.Inventory = {}

function ns.Inventory.Get()
    return snapshot
end

-- Actif : reconstruit tout de suite, puis suit les changements du sac.
function ns.Inventory.SetActive(on)
    active = on
    ns.Fire("INVENTORY_ACTIVE", on)
    if on then Rebuild(true) end
end

-- BAG_UPDATE_DELAYED arrive après les BAG_UPDATE ; le scanner de ViewerLog_Items
-- écrit à la frame suivante, d'où le court délai.
local function OnTimer()
    scheduled = false
    if active then Rebuild(false) else ScanTotals() end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function()
    if scheduled then return end
    scheduled = true
    C_Timer.After(0.1, OnTimer)
end)

-- Ces événements changent le classement des objets.
for _, ev in ipairs({ "ASSIGN_CHANGED", "CATEGORIES_CHANGED", "VIEW_CHANGED" }) do
    ns.On(ev, function()
        if active then Rebuild(true) end
    end)
end
