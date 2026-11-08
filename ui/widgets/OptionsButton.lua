local addonName, ns = ...

-- Bouton engrenage : ouvre le menu Options (zone title).

ns.UI.RegisterWidget({
    id = "options", area = "title", side = "right", order = 2,
    build = function(parent)
        local b = ns.UI.Button(parent, 26, 26, "")
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 3, -3)
        tex:SetPoint("BOTTOMRIGHT", -3, 3)
        tex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
        tex:SetVertexColor(1, 0.85, 0)

        b:SetScript("OnClick", function() ns.Fire("OPTIONS_TOGGLE") end)
        b:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("OPTIONS_TITLE"), 1, 1, 1)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)
        return b
    end,
})
