local addonName, ns = ...

-- Fenêtre banque / bataillon de l'historique ViewerLog : zone title, après le
-- bouton de personnage.

ns.UI.RegisterWidget({
    id = "history", area = "title", side = "left", order = 2,
    build = function(parent)
        local b = ns.UI.IconButton(parent, 26, "banque")

        b:SetScript("OnClick", function() ns.Fire("HISTORY_TOGGLE", "bank") end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("HISTORY_BANK_TIP"), 1, 1, 1)
            GameTooltip:AddLine(ns.L("HISTORY_BANK_DESC"), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)
        return b
    end,
})
