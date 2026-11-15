local addonName, ns = ...

-- Bouton engrenage : ouvre le menu Options (zone title).

ns.UI.RegisterWidget({
    id = "options", area = "title", side = "right", order = 2,
    build = function(parent)
        local b = ns.UI.IconButton(parent, 26, "reglages")

        b:SetScript("OnClick", function() ns.Fire("OPTIONS_TOGGLE") end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("OPTIONS_TITLE"), 1, 1, 1)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)
        return b
    end,
})
