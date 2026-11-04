local addonName, ns = ...

-- Type de banque : personnage.

ns.Bank.RegisterType({
    id = "character", labelKey = "BANK_CHARACTER", order = 1,
    bankType = Enum.BankType.Character,
    getData = function(tabID)
        local bank = ns.vl.GetBank and ns.vl.GetBank(UnitName("player"), GetRealmName())
        return bank and bank[tabID]
    end,
})
