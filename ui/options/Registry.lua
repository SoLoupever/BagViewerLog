local addonName, ns = ...

-- Registre d'options du menu Options. Chaque module ajoute la sienne.
-- def = { id, order, labelKey, descKey, get = function() -> bool, set = function(bool) }.

local options, sorted = {}, nil

function ns.UI.RegisterOption(def)
    options[#options + 1] = def
    sorted = nil
end

function ns.UI.GetOptions()
    if not sorted then
        sorted = {}
        for i = 1, #options do sorted[i] = options[i] end
        table.sort(sorted, function(a, b) return a.order < b.order end)
    end
    return sorted
end
