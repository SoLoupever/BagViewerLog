local addonName, ns = ...

-- Bouton de fermeture (zone title).

ns.UI.RegisterWidget({
    id = "close", area = "title", side = "right", order = 1,
    build = function(parent)
        local b = ns.UI.Button(parent, 26, 26, "X")
        b:SetScript("OnClick", function() ns.Fire("CLOSE_REQUESTED") end)
        return b
    end,
})
