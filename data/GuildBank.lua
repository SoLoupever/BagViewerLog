local addonName, ns = ...

-- Coffre de guilde : API Blizzard (onglets, emplacements), lue en direct.
-- Un onglet = un conteneur virtuel (ns.VBAG_BASE + index). Vue fusionnée
-- ("Tous") ou filtrée sur un onglet. Snapshot reconstruit seulement quand les
-- données changent ; GUILD_CHANGED n'est émis que si le contenu a changé.

local SLOTS = 98   -- emplacements par onglet (constante locale de Blizzard)

ns.Guild = {}

local snap = { groups = {}, free = {}, numTabs = 0 }
local tabs = {}          -- { index, name, icon, canView, canDeposit }
local built = {}         -- bagID -> true
local filter             -- nil = tous les onglets
local active, scheduled, stale = false, false, true
local tabsKey = ""

local EV = {
    "GUILDBANKBAGSLOTS_CHANGED", "GUILDBANK_ITEM_LOCK_CHANGED",
    "GUILDBANK_UPDATE_TABS", "GUILDBANK_UPDATE_MONEY",
}

local function ReadTabs()
    local n = GetNumGuildBankTabs() or 0
    local key = ""
    for i = 1, n do
        local name, icon, canView, canDeposit = GetGuildBankTabInfo(i)
        local t = tabs[i]
        if not t then
            t = {}
            tabs[i] = t
        end
        t.index, t.name, t.icon, t.canView, t.canDeposit = i, name, icon, canView, canDeposit
        key = key .. i .. (canView and "v" or "-") .. (canDeposit and "d" or "-") .. (name or "")
    end
    for i = #tabs, n + 1, -1 do tabs[i] = nil end
    if filter and not (tabs[filter] and tabs[filter].canView) then filter = nil end
    return n, key
end

local function Build()
    local groups, free = snap.groups, snap.free
    for _, list in pairs(groups) do wipe(list) end
    wipe(free)

    local n, key = ReadTabs()
    local dirty = key ~= tabsKey or n ~= snap.numTabs
    tabsKey, snap.numTabs = key, n

    for t = 1, n do
        local tab = tabs[t]
        if tab.canView and (not filter or filter == t) then
            local bag = ns.VBAG_BASE + t
            built[bag] = true
            for slot = 1, SLOTS do
                local texture, count, locked, _, quality = GetGuildBankItemInfo(t, slot)
                local link = texture and GetGuildBankItemLink(t, slot)
                local id = link and C_Item.GetItemInfoInstant(link)
                local e, changed
                if id then
                    e, changed = ns.FillSlot(bag, slot,
                        { id = id, count = count, link = link, quality = quality, locked = locked })
                else
                    e, changed = ns.FillSlot(bag, slot, nil)
                end
                if changed then dirty = true end
                if e.id then
                    local cat = ns.ResolveCategory(e)
                    local list = groups[cat]
                    if not list then
                        list = {}
                        groups[cat] = list
                    end
                    list[#list + 1] = e
                elseif not texture and tab.canDeposit then
                    free[#free + 1] = e
                end
            end
        end
    end
    stale = false
    return dirty
end

function ns.Guild.Get()
    if stale then Build() end
    return snap
end

-- { { index, name, icon, canView, canDeposit } } (liste réutilisée).
function ns.Guild.GetTabs()
    ReadTabs()
    return tabs
end

function ns.Guild.GetFilter()
    return filter
end

-- Onglet de dépôt Blizzard (clic droit depuis le sac) aligné sur la vue.
local function SyncCurrentTab()
    local target = filter
    if not target then
        for i = 1, #tabs do
            if tabs[i].canDeposit then target = i break end
        end
    end
    if target and GetCurrentGuildBankTab() ~= target then SetCurrentGuildBankTab(target) end
end

function ns.Guild.SetFilter(t)
    if filter == t then return end
    filter = t
    stale = true
    ReadTabs()
    if t then QueryGuildBankTab(t) end
    SyncCurrentTab()
    ns.Fire("GUILD_CHANGED")
end

function ns.Guild.GetMoney()
    return GetGuildBankMoney() or 0
end

local function Refresh()
    scheduled = false
    if not active then return end
    local dirty = Build()
    if dirty then ns.Fire("GUILD_CHANGED") end
end

local function QueryAll()
    local n = GetNumGuildBankTabs() or 0
    for i = 1, n do
        local _, _, canView = GetGuildBankTabInfo(i)
        if canView then QueryGuildBankTab(i) end
    end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event)
    if event == "GUILDBANK_UPDATE_MONEY" then
        ns.Fire("GUILD_MONEY_CHANGED")
        return
    end
    if event == "GUILDBANK_UPDATE_TABS" then QueryAll() end
    stale = true
    if scheduled then return end
    scheduled = true
    C_Timer.After(0.1, Refresh)
end)

-- Actif : écoute et interroge tous les onglets lisibles. Fermé : tout est libéré.
function ns.Guild.SetActive(on)
    if on == active then return end
    active = on
    for i = 1, #EV do
        if on then frame:RegisterEvent(EV[i]) else frame:UnregisterEvent(EV[i]) end
    end
    if on then
        stale, tabsKey = true, ""
        ReadTabs()
        QueryAll()
        SyncCurrentTab()
    else
        for bag in pairs(built) do ns.DropSlots(bag) end
        wipe(built)
        wipe(snap.groups)
        wipe(snap.free)
        snap.numTabs = 0
        filter, stale = nil, true
    end
end

-- Le classement change : tout est à reclasser.
for _, ev in ipairs({ "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
    ns.On(ev, function() stale = true end)
end
