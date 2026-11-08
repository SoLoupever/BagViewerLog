local addonName, ns = ...

-- Vente groupée : clic droit sur une catégorie du sac, marchand ouvert.
-- Vend au plus MAX_SELL emplacements, dans l'ordre d'affichage.
-- Écoute CATEGORY_CONTEXT (liste d'entrées) ; ne connaît aucun widget.

local MAX_SELL = 5
local GetInfo = C_Container.GetContainerItemInfo
local Use = C_Container.UseContainerItem

local open = false

ns.Vendor = {}

function ns.Vendor.IsOpen()
    return open
end

-- Renvoie le nombre d'emplacements vendus.
function ns.Vendor.Sell(list)
    local sold = 0
    for i = 1, #list do
        if sold >= MAX_SELL then break end
        local e = list[i]
        local info = GetInfo(e.bag, e.slot)
        -- Emplacement relu en direct : le snapshot peut avoir un léger retard.
        if info and info.itemID == e.id and not info.hasNoValue and not info.isLocked then
            Use(e.bag, e.slot)
            sold = sold + 1
        end
    end
    return sold
end

ns.On("CATEGORY_CONTEXT", function(def, list)
    if not open then return end
    if ns.Vendor.Sell(list) == 0 then
        UIErrorsFrame:AddExternalErrorMessage(ns.L("VENDOR_NOTHING"))
    end
end)

ns.On("CATEGORY_CONTEXT_TIP", function(tip, def)
    if open then
        tip:AddLine(ns.L("VENDOR_SELL_TIP"):format(MAX_SELL), 1, 1, 1, true)
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")
frame:SetScript("OnEvent", function(_, event)
    open = event == "MERCHANT_SHOW"
end)
