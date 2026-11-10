local addonName, ns = ...

-- Pied du cadre de guilde : or du coffre, dépôt / retrait, accès au cadre Blizzard.
-- ns.UI.GuildFooter.New(parent, onBlizzard) -> { Update() }.

local C = ns.UI.Colors
local PAD = 12

local function Toggle(which, other)
    StaticPopup_Hide(other)
    if StaticPopup_Visible(which) then StaticPopup_Hide(which) else StaticPopup_Show(which) end
end

ns.UI.GuildFooter = {}

function ns.UI.GuildFooter.New(parent, onBlizzard)
    local F = {}

    local blizz = ns.UI.Button(parent, 160, 26, ns.L("GUILD_BLIZZARD"))
    blizz:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PAD, PAD)
    blizz:SetScript("OnClick", onBlizzard)
    local hover = blizz:GetScript("OnEnter")
    blizz:SetScript("OnEnter", function(s)
        hover(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOP")
        GameTooltip:AddLine(ns.L("GUILD_BLIZZARD_TIP"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    local leave = blizz:GetScript("OnLeave")
    blizz:SetScript("OnLeave", function(s)
        leave(s)
        GameTooltip_Hide()
    end)

    local deposit = ns.UI.Button(parent, 90, 26, ns.L("GUILD_DEPOSIT_MONEY"))
    deposit:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", PAD, PAD)
    deposit:SetScript("OnClick", function() Toggle("GUILDBANK_DEPOSIT", "GUILDBANK_WITHDRAW") end)

    local withdraw = ns.UI.Button(parent, 90, 26, ns.L("GUILD_WITHDRAW_MONEY"))
    withdraw:SetPoint("LEFT", deposit, "RIGHT", 6, 0)
    withdraw:SetScript("OnClick", function() Toggle("GUILDBANK_WITHDRAW", "GUILDBANK_DEPOSIT") end)

    local money = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    money:SetPoint("LEFT", withdraw, "RIGHT", 12, 0)

    function F.Update()
        money:SetText(C_CurrencyInfo.GetCoinTextureString(ns.Guild.GetMoney()))
        withdraw:SetEnabled(CanWithdrawGuildBankMoney())
    end

    return F
end
