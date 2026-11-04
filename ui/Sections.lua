local addonName, ns = ...

-- En-têtes de catégorie (réutilisés). Clic = replier / déplier.
-- Flèche : atlas du Housing (common-icon-backarrow), tournée selon l'état.
-- Une instance par cadre (sac, banque) : ns.UI.NewSections().

local C = ns.UI.Colors

local ARROW_ATLAS = "common-icon-backarrow"
local ROT_EXPANDED, ROT_COLLAPSED = math.pi / 2, math.pi   -- bas, droite

local function Create(parent)
    local h = CreateFrame("Button", nil, parent)
    h:SetHeight(18)

    h.arrow = h:CreateTexture(nil, "ARTWORK")
    h.arrow:SetSize(14, 14)
    h.arrow:SetAtlas(ARROW_ATLAS)
    h.arrow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])

    h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h.label:SetPoint("LEFT", h.arrow, "RIGHT", 6, 0)
    h.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

    h.count = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h.count:SetPoint("LEFT", h.label, "RIGHT", 6, 0)
    h.count:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)

    h.line = h:CreateTexture(nil, "ARTWORK")
    h.line:SetHeight(1)
    h.line:SetPoint("BOTTOMRIGHT", 0, 0)
    h.line:SetColorTexture(C.accentDim[1], C.accentDim[2], C.accentDim[3], 0.8)

    h:SetScript("OnEnter", function(s) s.arrow:SetVertexColor(1, 1, 1) end)
    h:SetScript("OnLeave", function(s)
        s.arrow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    end)

    return h
end

function ns.UI.NewSections()
    local S = {}
    local pool, used = {}, 0

    function S.Reset()
        for i = 1, used do pool[i]:Hide() end
        used = 0
    end

    -- Place l'en-tête à la hauteur y (px sous le haut de parent), décalé de indent.
    -- count : nombre ou texte. onToggle(id) au clic.
    function S.Acquire(parent, y, id, text, count, collapsed, onToggle, indent)
        indent = indent or 0
        used = used + 1
        local h = pool[used]
        if not h then
            h = Create(parent)
            pool[used] = h
        end
        h.arrow:ClearAllPoints()
        h.arrow:SetPoint("LEFT", h, "LEFT", indent, 0)
        h.arrow:SetRotation(collapsed and ROT_COLLAPSED or ROT_EXPANDED)
        h.line:ClearAllPoints()
        h.line:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", indent, 0)
        h.line:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", 0, 0)
        h.label:SetFontObject(indent > 0 and "GameFontNormalSmall" or "GameFontNormal")
        h.label:SetText(text)
        h.count:SetText("(" .. count .. ")")
        h:SetScript("OnClick", function() onToggle(id) end)
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
        h:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
        h:Show()
        return h
    end

    return S
end
