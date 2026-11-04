local addonName, ns = ...

-- Objet tenu au curseur. Notifie via CURSOR_ITEM_CHANGED (itemID ou nil).

local itemID

ns.Cursor = {}

function ns.Cursor.GetItemID()
    return itemID
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CURSOR_CHANGED")
frame:SetScript("OnEvent", function()
    local kind, id = GetCursorInfo()
    local newID = (kind == "item") and id or nil
    if newID ~= itemID then
        itemID = newID
        ns.Fire("CURSOR_ITEM_CHANGED", itemID)
    end
end)
