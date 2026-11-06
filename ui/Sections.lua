local addonName, ns = ...

-- En-têtes de catégorie (réutilisés). Clic = replier / déplier.
-- Sous-catégories : simple libellé (sans flèche, ligne ni compteur).
-- Flèche : atlas du Housing (common-icon-backarrow), tournée selon l'état.
-- Une instance par cadre (sac, banque) : ns.UI.NewSections().

local C = ns.UI.Colors

local SECTION_H = 18
local ARROW_ATLAS = "common-icon-backarrow"
local ROT_EXPANDED, ROT_COLLAPSED = math.pi / 2, math.pi   -- bas, droite

local function Click(s)
    s.onToggle(s.id)
end

local function Create(parent)
    local h = CreateFrame("Button", nil, parent)
    h:SetHeight(SECTION_H)

    h.arrow = h:CreateTexture(nil, "ARTWORK")
    h.arrow:SetSize(14, 14)
    h.arrow:SetAtlas(ARROW_ATLAS)
    h.arrow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])

    h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h.label:SetWordWrap(false)
    h.label:SetPoint("LEFT", h.arrow, "RIGHT", 6, 0)
    h.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

    h.count = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h.count:SetPoint("LEFT", h.label, "RIGHT", 6, 0)
    h.count:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)

    h.line = h:CreateTexture(nil, "ARTWORK")
    h.line:SetHeight(1)
    h.line:SetPoint("BOTTOMRIGHT", 0, 0)
    h.line:SetColorTexture(C.accentDim[1], C.accentDim[2], C.accentDim[3], 0.8)

    h:SetScript("OnClick", Click)
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

    local function Take(parent)
        used = used + 1
        local h = pool[used]
        if not h then
            h = Create(parent)
            pool[used] = h
        end
        return h
    end

    local function Place(h, parent, y)
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
        h:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
        h:Show()
    end

    -- Place l'en-tête à la hauteur y (px sous le haut de parent).
    -- count : nombre ou texte. onToggle(id) au clic.
    -- Mise en forme et textes réécrits seulement s'ils changent.
    function S.Acquire(parent, y, id, text, count, collapsed, onToggle)
        local h = Take(parent)
        h.id, h.onToggle = id, onToggle
        if h.mode ~= "header" then
            h.mode, h.text, h.countText, h.collapsed = "header", nil, nil, nil
            h.arrow:ClearAllPoints()
            h.arrow:SetPoint("LEFT", h, "LEFT", 0, 0)
            h.arrow:Show()
            h.line:ClearAllPoints()
            h.line:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 0, 0)
            h.line:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", 0, 0)
            h.line:Show()
            h.count:Show()
            h.label:ClearAllPoints()
            h.label:SetPoint("LEFT", h.arrow, "RIGHT", 6, 0)
            h.label:SetFontObject("GameFontNormal")
            h.label:SetWidth(0)
            h:EnableMouse(true)
        end
        collapsed = collapsed and true or false
        if h.collapsed ~= collapsed then
            h.collapsed = collapsed
            h.arrow:SetRotation(collapsed and ROT_COLLAPSED or ROT_EXPANDED)
        end
        if h.text ~= text then
            h.text = text
            h.label:SetText(text)
        end
        if h.countText ~= count then
            h.countText = count
            h.count:SetText("(" .. count .. ")")
        end
        Place(h, parent, y)
        return h
    end

    -- Libellé de bloc : texte seul, non cliquable. h.textW = largeur du texte ;
    -- l'appelant le positionne (SetPoint) et fixe sa largeur (SetLabelWidth).
    function S.AcquireLabel(parent, text)
        local h = Take(parent)
        if h.mode ~= "label" or h.text ~= text then
            h.mode, h.text = "label", text
            h.arrow:Hide()
            h.line:Hide()
            h.count:Hide()
            h.label:ClearAllPoints()
            h.label:SetPoint("LEFT", h, "LEFT", 0, 0)
            h.label:SetFontObject("GameFontNormalSmall")
            h.label:SetWidth(0)
            h.label:SetText(text)
            h.textW = h.label:GetStringWidth()
            h:EnableMouse(false)
        end
        h:SetSize(h.textW + 2, SECTION_H)
        h:ClearAllPoints()
        h:Show()
        return h
    end

    -- Largeur du bloc : un libellé plus long est tronqué.
    function S.SetLabelWidth(h, w)
        h:SetWidth(w)
        h.label:SetWidth(w)
    end

    return S
end
