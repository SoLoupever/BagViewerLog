local addonName, ns = ...

-- Type de banque : bataillon.

ns.Bank.RegisterType({
    id = "warband", labelKey = "BANK_WARBAND", order = 2,
    bankType = Enum.BankType.Account,
    getData = function(tabID)
        local bank = ns.vl.GetWarbandBank and ns.vl.GetWarbandBank()
        return bank and bank[tabID]
    end,
})
