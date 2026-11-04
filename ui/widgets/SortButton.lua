local addonName, ns = ...

-- Bouton de tri (icône et action Blizzard : C_Container.SortBags).

ns.UI.RegisterWidget({
    id = "sort", area = "toolbar", side = "right", order = 1,
    build = function(parent)
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(28, 26)
        b:SetNormalAtlas("bags-button-autosort-up")
        b:SetPushedAtlas("bags-button-autosort-down")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        b:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
            C_Container.SortBags()
        end)
        b:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("SORT_TIP_TITLE"), 1, 1, 1)
            GameTooltip:AddLine(ns.L("SORT_TIP_DESC"), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)

        return b
    end,
})
