local addonName, ns = ...

-- Bouton de fermeture Blizzard (zone title).

ns.UI.RegisterWidget({
    id = "close", area = "title", side = "right", order = 1,
    build = function(parent)
        local b = CreateFrame("Button", nil, parent, "UIPanelCloseButtonNoScripts")
        b:SetSize(26, 26)
        b:SetScript("OnClick", function() ns.Fire("CLOSE_REQUESTED") end)
        return b
    end,
})
