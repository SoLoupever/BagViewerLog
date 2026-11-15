local addonName, ns = ...

-- Vue d'historique : banque de bataillon (commune à tous les personnages).

ns.History.RegisterView({
    id = "warband", labelKey = "BANK_WARBAND", order = 3, shared = true,
    getData = function()
        return ns.vl.GetWarbandBank and ns.vl.GetWarbandBank()
    end,
})
