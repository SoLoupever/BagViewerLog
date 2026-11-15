local addonName, ns = ...

-- Changement de personnage (historique ViewerLog) : zone title, tout à gauche.

ns.UI.RegisterWidget({
    id = "char", area = "title", side = "left", order = 1,
    build = function(parent)
        local b = ns.UI.IconButton(parent, 26, "personnage")

        b:SetScript("OnClick", function(s) ns.Fire("HISTORY_PICK_CHAR", s, "bags") end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("HISTORY_CHAR_TIP"), 1, 1, 1)
            GameTooltip:AddLine(ns.L("HISTORY_CHAR_DESC"), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)
        return b
    end,
})
