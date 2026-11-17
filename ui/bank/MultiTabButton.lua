local addonName, ns = ...

-- Bascule de la vue multi-onglets de la banque (personnage et bataillon).

local C = ns.UI.Colors

ns.UI.RegisterWidget({
    id = "bankmulti", area = "bankbar", side = "right", order = 2,
    build = function(parent)
        local b = ns.UI.Button(parent, 120, 26, ns.L("BANK_MULTITAB"))

        local function Mark()
            local on = ns.BankTabs.IsMulti()
            local c = on and C.btnHoverBorder or C.btnBorder
            b:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            b.selected = on
        end

        b:SetScript("OnLeave", function(s)
            s:SetBackdropColor(C.btnBg[1], C.btnBg[2], C.btnBg[3], C.btnBg[4])
            Mark()
            GameTooltip_Hide()
        end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("BANK_MULTITAB_TIP"), 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnClick", function()
            ns.BankTabs.SetMulti(not ns.BankTabs.IsMulti())
        end)

        ns.On("BANK_TAB_CHANGED", Mark)
        Mark()
        return b
    end,
})
