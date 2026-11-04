local addonName, ns = ...

-- Jouets : objets connus de la collection de jouets (C_ToyBox.GetToyInfo).

local GetToyInfo = C_ToyBox.GetToyInfo

local isToy = {}   -- itemID -> bool

ns.RegisterCategory({
    id = "toy", labelKey = "CAT_TOY", order = 56, priority = 42,
    match = function(item)
        local id = item.id
        if not id then return false end
        local v = isToy[id]
        if v == nil then
            v = GetToyInfo(id) ~= nil
            isToy[id] = v
        end
        return v
    end,
})
