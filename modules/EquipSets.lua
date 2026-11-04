local addonName, ns = ...

-- Ensembles d'équipement : objets cités par un ensemble (C_EquipmentSet).
-- Sous-catégorie d'"equipment".

local inSet   -- itemID -> true, nil = à reconstruire

local function Build()
    inSet = {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local ids = C_EquipmentSet.GetItemIDs(setID)
        if ids then
            -- Valeurs 0 / 1 : emplacement vide ou ignoré.
            for _, id in pairs(ids) do
                if id > 1 then inSet[id] = true end
            end
        end
    end
end

ns.RegisterCategory({
    id = "equipsets", labelKey = "CAT_EQUIPSETS", order = 21, priority = 55,
    parent = "equipment",
    match = function(item)
        if not item.id then return false end
        if not inSet then Build() end
        return inSet[item.id] == true
    end,
})

local frame = CreateFrame("Frame")
frame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
frame:SetScript("OnEvent", function()
    inSet = nil
    ns.Fire("CATEGORIES_CHANGED")
end)
