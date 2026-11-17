local addonName, ns = ...

-- Vue multi-onglets de la banque : une section par onglet, tous visibles.
-- Réglage commun aux banques personnage et bataillon.

local SETTING = "bank_multitab"
local pool, ids, tops, out = {}, {}, {}, {}

-- Même forme qu'une vue du sac (voir modules/View.lua).
local view = {
    id = "banktabs", noFree = true, stack = false, bulk = false,
    tops   = function() return tops end,
    groups = function(snap)
        for i = 1, #tops do
            local t = tops[i]
            out[t.id] = snap.slots[t.tabID]
        end
        return out
    end,
}

function ns.BankTabs.IsMulti()
    return ns.Settings.Get(SETTING) == true
end

function ns.BankTabs.SetMulti(on)
    on = on and true or false
    if on == ns.BankTabs.IsMulti() then return end
    ns.Settings.Set(SETTING, on)
    ns.Fire("BANK_TAB_CHANGED")
end

-- tabs : ns.Bank.GetTabs(type). Une section par onglet, entête = son nom.
function ns.BankTabs.GetMultiView(tabs)
    wipe(tops)
    for i = 1, #tabs do
        local tab = tabs[i]
        local t = pool[i]
        if not t then
            t = { header = true, noAssign = true, count = ns.View.CountText }
            pool[i] = t
        end
        local id = ids[tab.ID]
        if not id then
            id = "bank_multi" .. tab.ID
            ids[tab.ID] = id
        end
        t.id, t.tabID, t.label = id, tab.ID, tab.name or ""
        tops[i] = t
    end
    return view
end
