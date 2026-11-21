local addonName, ns = ...

-- Dernier type de banque affiché (personnage / bataillon), rouvert tel quel.

local KEY = "bank_last_type"

ns.BankMemory = {}

function ns.BankMemory.Get()
    return ns.Settings.Get(KEY)
end

ns.On("BANK_TYPE_CHANGED", function(id)
    ns.Settings.Set(KEY, id)
end)
