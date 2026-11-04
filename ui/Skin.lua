local addonName, ns = ...

-- Constructeurs plats (fond uni + liseré 1px) partagés par les widgets.

local C = ns.UI.Colors

local FLAT = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

-- bgKey / borderKey : clés de ns.UI.Colors.
function ns.UI.Flat(parent, bgKey, borderKey, frameType)
    local f = CreateFrame(frameType or "Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop(FLAT)
    local bg, bd = C[bgKey], C[borderKey]
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    f:SetBackdropBorderColor(bd[1], bd[2], bd[3], bd[4])
    return f
end

function ns.UI.Button(parent, w, h, text)
    local b = ns.UI.Flat(parent, "btnBg", "btnBorder", "Button")
    b:SetSize(w, h)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetText(text or "")
    b.label:SetTextColor(C.btnText[1], C.btnText[2], C.btnText[3], 1)
    b:SetScript("OnEnter", function(s)
        s:SetBackdropColor(C.btnHoverBg[1], C.btnHoverBg[2], C.btnHoverBg[3], C.btnHoverBg[4])
        s:SetBackdropBorderColor(C.btnHoverBorder[1], C.btnHoverBorder[2], C.btnHoverBorder[3], C.btnHoverBorder[4])
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropColor(C.btnBg[1], C.btnBg[2], C.btnBg[3], C.btnBg[4])
        s:SetBackdropBorderColor(C.btnBorder[1], C.btnBorder[2], C.btnBorder[3], C.btnBorder[4])
    end)
    return b
end
