local addonName, ns = ...

-- Bouton qui affiche les sacs équipés (zone title).

ns.UI.RegisterWidget({
    id = "bags", area = "title", side = "right", order = 4,
    build = function(parent)
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(26, 26)
        b:SetNormalTexture("Interface\\Buttons\\Button-Backpack-Up")
        b:SetPushedTexture("Interface\\Buttons\\Button-Backpack-Down")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        b:SetScript("OnClick", function() ns.Fire("BAGS_TOGGLE") end)
        b:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("BAGS_TIP_TITLE"), 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)

        return b
    end,
})
