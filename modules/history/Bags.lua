local addonName, ns = ...

-- Vue d'historique : sacs du personnage.

ns.History.RegisterView({
    id = "bags", labelKey = "HISTORY_BAGS", order = 1,
    getData = function(name, realm)
        return ns.vl.GetBags and ns.vl.GetBags(name, realm)
    end,
})
