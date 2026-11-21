local addonName, ns = ...

-- Pied de banque : or déposé, dépôt / retrait (types qui le permettent : bataillon).
-- ns.UI.BankMoneyFooter.New(parent, anchor) -> { Update(bankType) }.

local PAD = 12

local function Toggle(which, other, bankType)
    StaticPopup_Hide(other)
    if StaticPopup_Visible(which) then
        StaticPopup_Hide(which)
    else
        StaticPopup_Show(which, nil, nil, { bankType = bankType })
    end
end

ns.UI.BankMoneyFooter = {}

function ns.UI.BankMoneyFooter.New(parent, anchor)
    local F = {}
    local bankType

    local deposit = ns.UI.Button(parent, 90, 26, ns.L("BANK_DEPOSIT_MONEY"))
    deposit:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
    deposit:SetScript("OnClick", function()
        if bankType then Toggle("BANK_MONEY_DEPOSIT", "BANK_MONEY_WITHDRAW", bankType) end
    end)

    local withdraw = ns.UI.Button(parent, 90, 26, ns.L("BANK_WITHDRAW_MONEY"))
    withdraw:SetPoint("LEFT", deposit, "RIGHT", 6, 0)
    withdraw:SetScript("OnClick", function()
        if bankType then Toggle("BANK_MONEY_WITHDRAW", "BANK_MONEY_DEPOSIT", bankType) end
    end)

    local money = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    money:SetPoint("LEFT", withdraw, "RIGHT", 12, 0)

    local function Refresh()
        if not bankType then return end
        money:SetText(C_CurrencyInfo.GetCoinTextureString(C_Bank.FetchDepositedMoney(bankType) or 0))
        deposit:SetEnabled(C_Bank.CanDepositMoney(bankType))
        withdraw:SetEnabled(C_Bank.CanWithdrawMoney(bankType))
    end

    function F.Update(newType)
        local ok = newType and C_Bank.DoesBankTypeSupportMoneyTransfer(newType)
        if bankType ~= (ok and newType or nil) then
            StaticPopup_Hide("BANK_MONEY_DEPOSIT")
            StaticPopup_Hide("BANK_MONEY_WITHDRAW")
        end
        bankType = ok and newType or nil
        deposit:SetShown(ok)
        withdraw:SetShown(ok)
        money:SetShown(ok)
        Refresh()
    end

    -- Fermé, les événements ne coûtent rien.
    local ev = CreateFrame("Frame", nil, parent)
    ev:RegisterEvent("ACCOUNT_MONEY")
    ev:RegisterEvent("PLAYER_MONEY")
    ev:SetScript("OnEvent", function()
        if ev:IsVisible() then Refresh() end
    end)

    F.Update(nil)
    return F
end
