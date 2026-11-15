local addonName, ns = ...

-- Bouton qui affiche les sacs équipés (zone title).

ns.UI.RegisterWidget({
    id = "bags", area = "title", side = "right", order = 4,
    build = function(parent)
        local b = ns.UI.IconButton(parent, 26, "bourse")

        b:SetScript("OnClick", function() ns.Fire("BAGS_TOGGLE") end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("BAGS_TIP_TITLE"), 1, 1, 1)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)

        return b
    end,
})
