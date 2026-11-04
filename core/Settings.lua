local addonName, ns = ...

-- Réglages dans ViewerLogDB.modules["bagviewerlog"] (stockage par module du noyau).

local MODULE = "bagviewerlog"
local DEFAULTS = {}

ns.Settings = {}

local function Store()
    return ns.vl.GetModuleData(MODULE)
end

function ns.Settings.Get(key)
    local v = Store()[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

function ns.Settings.Set(key, value)
    Store()[key] = value
end

-- Sous-table persistante, créée à la demande.
function ns.Settings.Table(key)
    local s = Store()
    s[key] = s[key] or {}
    return s[key]
end
