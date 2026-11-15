local addonName, ns = ...

-- Vue par onglet de la banque (mode compact) : un onglet = ses emplacements
-- réels, objets et vides. Sans choix, la banque reste classée par catégories.

ns.BankTabs = {}

local selected   -- ID de l'onglet choisi | nil
local top = { header = true, noAssign = true, count = ns.View.CountText }
local TOPS, out = { top }, {}

-- Même forme qu'une vue du sac (voir modules/View.lua).
local view = {
    id = "banktab", noFree = true, stack = false, bulk = false,
    tops   = function() return TOPS end,
    groups = function(snap)
        out[top.id] = snap.slots[selected]
        return out
    end,
}

-- tabs : ns.Bank.GetTabs(type). Renvoie l'index et l'onglet choisis ;
-- le choix est effacé si l'onglet n'existe plus (autre type de banque).
function ns.BankTabs.Resolve(tabs)
    if not selected then return nil end
    for i = 1, #tabs do
        if tabs[i].ID == selected then return i, tabs[i] end
    end
    selected = nil
end

function ns.BankTabs.Set(tabID)
    if tabID == selected then return end
    selected = tabID
    ns.Fire("BANK_TAB_CHANGED", tabID)
end

-- Vue de l'onglet tab (entête = son nom).
function ns.BankTabs.GetView(tab)
    top.id, top.label = "bank_tab" .. tab.ID, tab.name or ""
    return view
end
