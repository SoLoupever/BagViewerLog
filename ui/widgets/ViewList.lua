local addonName, ns = ...

-- Liste des modes d'affichage (zone sidebar, profils qui en ont une).

local C = ns.UI.Colors

local ROW_H, STEP, INSET, HEAD_H = 26, 30, 6, 22

ns.UI.RegisterWidget({
    id = "views", area = "sidebar", side = "top", order = 1,
    build = function(parent)
        local box = CreateFrame("Frame", nil, parent)
        local views = ns.View.GetAll()
        box:SetHeight(HEAD_H + #views * STEP)

        local head = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        head:SetPoint("TOPLEFT", INSET + 2, -INSET)
        head:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
        head:SetText(ns.L("VIEW_TITLE"))

        local buttons = {}
        local function Mark()
            local cur = ns.View.GetCurrentID()
            for i = 1, #buttons do
                local b = buttons[i]
                local c = b.viewID == cur and C.btnHoverBorder or C.btnBorder
                b:SetBackdropBorderColor(c[1], c[2], c[3], 1)
                b.selected = b.viewID == cur
            end
        end

        for i, def in ipairs(views) do
            local b = ns.UI.Button(box, 100, ROW_H, ns.L(def.labelKey))
            b:SetPoint("TOPLEFT", box, "TOPLEFT", INSET, -(HEAD_H + (i - 1) * STEP))
            b:SetPoint("TOPRIGHT", box, "TOPRIGHT", -INSET, -(HEAD_H + (i - 1) * STEP))
            b.viewID = def.id
            b:SetScript("OnLeave", function(s)
                local c = s.selected and C.btnHoverBorder or C.btnBorder
                s:SetBackdropColor(C.btnBg[1], C.btnBg[2], C.btnBg[3], C.btnBg[4])
                s:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            end)
            b:SetScript("OnClick", function(s) ns.View.Set(s.viewID) end)
            buttons[i] = b
        end

        ns.On("VIEW_CHANGED", Mark)
        Mark()
        return box
    end,
})
