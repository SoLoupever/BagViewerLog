local addonName, ns = ...

-- Bouton de tri (action Blizzard : C_Container.SortBags).

ns.UI.RegisterWidget({
    id = "sort", area = "title", side = "right", order = 3,
    build = function(parent)
        local b = ns.UI.IconButton(parent, 26, "trier")

        b:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
            C_Container.SortBags()
        end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("SORT_TIP_TITLE"), 1, 1, 1)
            GameTooltip:AddLine(ns.L("SORT_TIP_DESC"), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)

        return b
    end,
})
