local addonName, ns = ...

-- Bouton qui ouvre le menu des catégories (zone toolbar).

ns.UI.RegisterWidget({
    id = "menu", area = "toolbar", side = "right", order = 1,
    build = function(parent)
        local b = ns.UI.Button(parent, 90, 26, ns.L("MENU_BTN"))
        b:SetScript("OnClick", function() ns.Fire("MENU_TOGGLE") end)
        return b
    end,
})
