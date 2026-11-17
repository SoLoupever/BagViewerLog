local addonName, ns = ...

-- Bouton de tri de la banque affichée (C_Container.SortBank).

ns.UI.RegisterWidget({
    id = "banksort", area = "bankbar", side = "right", order = 1,
    build = function(parent)
        local b = ns.UI.IconButton(parent, 26, "trier")

        b:SetScript("OnClick", function()
            local def = ns.Bank.GetViewedType()
            if not def or C_Bank.FetchNumPurchasedBankTabs(def.bankType) == 0 then return end
            PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
            C_Container.SortBank(def.bankType)
        end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("BANK_SORT_TIP_TITLE"), 1, 1, 1)
            GameTooltip:AddLine(ns.L("BANK_SORT_TIP_DESC"), 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)

        return b
    end,
})
