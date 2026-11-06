local addonName, ns = ...

-- Emplacement "+" : déposer l'objet tenu au curseur classe cet objet dans la
-- catégorie du "+" (l'objet retourne dans son sac, rien n'est déplacé).
-- Une instance par cadre (sac, banque) : ns.UI.NewPlusSlots().

local C = ns.UI.Colors

local function Drop(self)
    local itemID = ns.Cursor.GetItemID()
    if not itemID then return end
    ns.Assign.Set(itemID, self.catID)
    ClearCursor()
end

local function Create(parent)
    local b = ns.UI.Flat(parent, "inner", "innerBorder", "Button")
    b:SetSize(37, 37)
    b:RegisterForClicks("LeftButtonUp")

    local plus = b:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    plus:SetPoint("CENTER", 0, 1)
    plus:SetText("+")
    plus:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

    b:SetScript("OnClick", Drop)
    b:SetScript("OnReceiveDrag", Drop)
    b:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        GameTooltip:SetOwner(s, "ANCHOR_TOP")
        GameTooltip:AddLine(ns.L("PLUS_TIP"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(C.innerBorder[1], C.innerBorder[2], C.innerBorder[3], 1)
        GameTooltip_Hide()
    end)
    return b
end

function ns.UI.NewPlusSlots()
    local P = {}
    local pool, used = {}, 0

    function P.Reset()
        for i = 1, used do pool[i]:Hide() end
        used = 0
    end

    function P.Acquire(parent, catID)
        used = used + 1
        local b = pool[used]
        if not b then
            b = Create(parent)
            pool[used] = b
        end
        b.catID = catID
        b:Show()
        return b
    end

    return P
end
