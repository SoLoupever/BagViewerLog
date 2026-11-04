local addonName, ns = ...

-- Barre de recherche (zone toolbar, remplit l'espace libre).

local C = ns.UI.Colors

ns.UI.RegisterWidget({
    id = "search", area = "toolbar", side = "left", order = 1, flex = true,
    build = function(parent)
        local box = ns.UI.Flat(parent, "inner", "innerBorder", "EditBox")
        box:SetHeight(26)
        box:SetAutoFocus(false)
        box:SetFontObject("GameFontHighlight")
        box:SetTextInsets(8, 8, 0, 0)
        box:SetMaxLetters(40)

        local hint = box:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        hint:SetPoint("LEFT", 8, 0)
        hint:SetText(ns.L("SEARCH_PLACEHOLDER"))

        local function UpdateHint()
            hint:SetShown(box:GetText() == "" and not box:HasFocus())
        end

        box:SetScript("OnTextChanged", function(s)
            ns.Search.Set(s:GetText())
            UpdateHint()
        end)
        box:SetScript("OnEditFocusGained", function(s)
            s:SetBackdropBorderColor(C.btnHoverBorder[1], C.btnHoverBorder[2], C.btnHoverBorder[3], 1)
            UpdateHint()
        end)
        box:SetScript("OnEditFocusLost", function(s)
            s:SetBackdropBorderColor(C.innerBorder[1], C.innerBorder[2], C.innerBorder[3], 1)
            UpdateHint()
        end)
        box:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        box:SetScript("OnEnterPressed", function(s) s:ClearFocus() end)

        -- Fermeture du sac : la recherche repart à zéro.
        ns.On("FRAME_HIDDEN", function()
            box:SetText("")
            box:ClearFocus()
        end)

        return box
    end,
})
