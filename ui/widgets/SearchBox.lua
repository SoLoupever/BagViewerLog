local addonName, ns = ...

-- Barre de recherche (zone toolbar, remplit l'espace libre).

ns.UI.RegisterWidget({
    id = "search", area = "toolbar", side = "left", order = 1, flex = true,
    build = function(parent)
        local box = ns.UI.EditBox(parent, 26, 40)

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
        box:HookScript("OnEditFocusGained", UpdateHint)
        box:HookScript("OnEditFocusLost", UpdateHint)

        -- Fermeture du sac : la recherche repart à zéro.
        ns.On("FRAME_HIDDEN", function()
            box:SetText("")
            box:ClearFocus()
        end)

        return box
    end,
})
