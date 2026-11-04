local addonName, ns = ...

-- Or du joueur (zone footer).

ns.UI.RegisterWidget({
    id = "money", area = "footer", side = "right", order = 1,
    build = function(parent)
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetJustifyH("RIGHT")

        local function Update()
            fs:SetText(C_CurrencyInfo.GetCoinTextureString(GetMoney()))
        end

        local ev = CreateFrame("Frame", nil, parent)
        ev:RegisterEvent("PLAYER_MONEY")
        ev:SetScript("OnEvent", Update)
        ns.On("INVENTORY_CHANGED", Update)

        return fs
    end,
})
