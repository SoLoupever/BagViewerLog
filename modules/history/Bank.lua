local addonName, ns = ...

-- Vue d'historique : banque du personnage.

ns.History.RegisterView({
    id = "bank", labelKey = "BANK_TITLE", order = 2,
    getData = function(name, realm)
        return ns.vl.GetBank and ns.vl.GetBank(name, realm)
    end,
})
