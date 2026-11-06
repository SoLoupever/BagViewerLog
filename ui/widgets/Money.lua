local addonName, ns = ...

-- Or du joueur (zone footer).

ns.UI.RegisterWidget({
    id = "money", area = "footer", side = "right", order = 1,
    build = function(parent)
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetJustifyH("RIGHT")

        local shown
        local function Update()
            local money = GetMoney()
            if money == shown then return end
            shown = money
            fs:SetText(C_CurrencyInfo.GetCoinTextureString(money))
        end

        -- Mis à jour à l'affichage ; fermé, l'événement ne coûte rien.
        local ev = CreateFrame("Frame", nil, parent)
        ev:RegisterEvent("PLAYER_MONEY")
        ev:SetScript("OnShow", Update)
        ev:SetScript("OnEvent", function()
            if ev:IsVisible() then Update() end
        end)

        Update()
        return fs
    end,
})
