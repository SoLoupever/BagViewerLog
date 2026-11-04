local addonName, ns = ...

-- Remplace l'affichage des banques Blizzard. Le BankFrame doit rester "affiché"
-- (son OnHide ferme l'interaction avec le banquier) : on le rend invisible et
-- minuscule au lieu de le masquer.

local bf = _G.BankFrame
if not bf then return end

bf:HookScript("OnShow", function(self)
    self:SetAlpha(0)
    self:SetScale(0.001)
    ns.UI.Bank.Show()
end)

bf:HookScript("OnHide", function()
    ns.UI.Bank.Hide()
end)
