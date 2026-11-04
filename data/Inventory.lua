local addonName, ns = ...

-- Données du sac : lecture de ViewerLogAPI.GetBags (ViewerLog_Items), groupées
-- par catégorie. Le nombre d'emplacements vient de C_Container.
-- Actif uniquement quand l'UI est ouverte (SetActive).

local C_Container, C_Item = C_Container, C_Item

-- Enum.BagIndex.Backpack .. Enum.BagIndex.ReagentBag
local FIRST_BAG, LAST_BAG = 0, 5

local static = {}   -- itemID -> { icon, classID, subClassID, quality }
local snapshot = { groups = {}, free = {}, used = 0, total = 0 }
local active, scheduled = false, false

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

local function Rebuild()
    local bags = ns.vl.GetBags and ns.vl.GetBags(UnitName("player"), GetRealmName())
    local groups, free, items, totals = {}, {}, {}, {}
    local used, total = 0, 0

    for bag = FIRST_BAG, LAST_BAG do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        local bagData  = bags and bags[bag]
        total = total + numSlots

        for slot = 1, numSlots do
            local e = bagData and bagData[slot]
            if e then
                used = used + 1
                local s = GetStatic(e.id)
                local item = {
                    bag = bag, slot = slot, id = e.id, count = e.count, link = e.link,
                    icon = s.icon, classID = s.classID, subClassID = s.subClassID,
                    quality = s.quality,
                    name = e.link and e.link:match("%[(.-)%]"),
                }
                items[#items + 1] = item
                totals[e.id] = (totals[e.id] or 0) + (e.count or 1)
            else
                free[#free + 1] = { bag = bag, slot = slot }
            end
        end
    end

    -- Les modules peuvent réagir aux quantités avant le classement.
    ns.Fire("INVENTORY_SCANNED", totals)

    for i = 1, #items do
        local item = items[i]
        local cat = ns.ResolveCategory(item)
        local list = groups[cat]
        if not list then
            list = {}
            groups[cat] = list
        end
        list[#list + 1] = item
    end

    snapshot = { groups = groups, free = free, used = used, total = total }
    ns.Fire("INVENTORY_CHANGED", snapshot)
end

ns.Inventory = {}

function ns.Inventory.Get()
    return snapshot
end

-- Actif : reconstruit tout de suite, puis suit les changements du sac.
function ns.Inventory.SetActive(on)
    active = on
    if on then Rebuild() end
end

-- BAG_UPDATE_DELAYED arrive après les BAG_UPDATE ; le scanner de ViewerLog_Items
-- écrit à la frame suivante, d'où le court délai.
local frame = CreateFrame("Frame")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function()
    if not active or scheduled then return end
    scheduled = true
    C_Timer.After(0.1, function()
        scheduled = false
        if active then Rebuild() end
    end)
end)

-- Ces événements changent le classement des objets.
for _, ev in ipairs({ "RECENT_EXPIRED", "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
    ns.On(ev, function()
        if active then Rebuild() end
    end)
end
