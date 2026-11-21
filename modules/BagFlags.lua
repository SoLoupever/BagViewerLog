local addonName, ns = ...

-- Filtres de sacs natifs Blizzard (C_Container.SetBagSlotFlag).

local Flags = Enum.BagSlotFlags
local BACKPACK, FIRST_BAG, LAST_BAG = 0, 1, 4

-- Même ordre et mêmes atlas que le menu Blizzard.
local FILTERS = {
    { flag = Flags.ClassEquipment,      key = "BAGFLAG_EQUIPMENT",   icon = "bags-icon-equipment" },
    { flag = Flags.ClassConsumables,    key = "BAGFLAG_CONSUMABLES", icon = "bags-icon-consumables" },
    { flag = Flags.ClassProfessionGoods, key = "BAGFLAG_TRADEGOODS", icon = "bags-icon-profession-goods" },
    { flag = Flags.ClassJunk,           key = "BAGFLAG_JUNK",        icon = "bags-icon-junk" },
    { flag = Flags.ClassQuestItems,     key = "BAGFLAG_QUEST",       icon = "bags-icon-questitem" },
    { flag = Flags.ClassReagents,       key = "BAGFLAG_REAGENTS",    icon = "bags-icon-reagents" },
}

ns.BagFlags = {}

function ns.BagFlags.GetFilters()
    return FILTERS
end

-- Sacs 1 à 4 non professionnels (règle du menu Blizzard).
function ns.BagFlags.CanFilter(bag)
    if bag < FIRST_BAG or bag > LAST_BAG then return false end
    local invID = C_Container.ContainerIDToInventoryID(bag)
    return not (invID and IsInventoryItemProfessionBag("player", invID))
end

function ns.BagFlags.Get(bag, flag)
    return C_Container.GetBagSlotFlag(bag, flag)
end

function ns.BagFlags.Set(bag, flag, on)
    C_Container.SetBagSlotFlag(bag, flag, on and true or false)
    ns.Fire("BAGFLAGS_CHANGED", bag)
end

-- Premier filtre actif : { flag, key, icon } | nil.
function ns.BagFlags.GetActive(bag)
    if not ns.BagFlags.CanFilter(bag) then return nil end
    for i = 1, #FILTERS do
        if C_Container.GetBagSlotFlag(bag, FILTERS[i].flag) then return FILTERS[i] end
    end
end

function ns.BagFlags.GetIgnoreSort(bag)
    if bag == BACKPACK then return C_Container.GetBackpackAutosortDisabled() end
    return C_Container.GetBagSlotFlag(bag, Flags.DisableAutoSort)
end

function ns.BagFlags.SetIgnoreSort(bag, on)
    if bag == BACKPACK then
        C_Container.SetBackpackAutosortDisabled(on and true or false)
    else
        C_Container.SetBagSlotFlag(bag, Flags.DisableAutoSort, on and true or false)
    end
    ns.Fire("BAGFLAGS_CHANGED", bag)
end

function ns.BagFlags.GetIgnoreJunk(bag)
    if bag == BACKPACK then return C_Container.GetBackpackSellJunkDisabled() end
    return C_Container.GetBagSlotFlag(bag, Flags.ExcludeJunkSell)
end

function ns.BagFlags.SetIgnoreJunk(bag, on)
    if bag == BACKPACK then
        C_Container.SetBackpackSellJunkDisabled(on and true or false)
    else
        C_Container.SetBagSlotFlag(bag, Flags.ExcludeJunkSell, on and true or false)
    end
    ns.Fire("BAGFLAGS_CHANGED", bag)
end

-- Le serveur confirme les changements (autre addon, menu Blizzard).
local f = CreateFrame("Frame")
f:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
f:SetScript("OnEvent", function(_, _, bag) ns.Fire("BAGFLAGS_CHANGED", bag) end)
