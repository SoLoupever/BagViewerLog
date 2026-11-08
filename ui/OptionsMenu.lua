local addonName, ns = ...

-- Menu Options : une case par option du registre (ui/options/Registry.lua).

local C = ns.UI.Colors

local W, PAD = 320, 12
local HEAD_H, ROW_H = 44, 44
local BOX = 18

local frame
local rows = {}

local function Refresh()
    local list = ns.UI.GetOptions()
    for i = 1, #list do
        rows[i].check:SetShown(list[i].get() == true)
    end
end

local function CreateRow(def, i)
    local r = CreateFrame("Button", nil, frame)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(HEAD_H + (i - 1) * ROW_H))
    r:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -(HEAD_H + (i - 1) * ROW_H))

    local box = ns.UI.Flat(r, "inner", "innerBorder")
    box:SetSize(BOX, BOX)
    box:SetPoint("TOPLEFT", 0, -4)

    r.check = box:CreateTexture(nil, "ARTWORK")
    r.check:SetPoint("TOPLEFT", 3, -3)
    r.check:SetPoint("BOTTOMRIGHT", -3, 3)
    r.check:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)

    local label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", box, "TOPRIGHT", 8, -2)
    label:SetText(ns.L(def.labelKey))

    local desc = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    desc:SetText(ns.L(def.descKey))

    r:SetScript("OnClick", function()
        def.set(not def.get())
        Refresh()
    end)
    r:SetScript("OnEnter", function() box:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
    r:SetScript("OnLeave", function() box:SetBackdropBorderColor(C.innerBorder[1], C.innerBorder[2], C.innerBorder[3], 1) end)
    return r
end

local function Build()
    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:Hide()
    _G["BagViewerLogOptions"] = frame
    table.insert(UISpecialFrames, "BagViewerLogOptions")

    local list = ns.UI.GetOptions()
    frame:SetSize(W, HEAD_H + #list * ROW_H + PAD)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    title:SetText(ns.L("OPTIONS_TITLE"))

    local close = ns.UI.Button(frame, 26, 26, "X")
    close:SetPoint("TOPRIGHT", -PAD, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    for i = 1, #list do rows[i] = CreateRow(list[i], i) end

    frame:SetScript("OnShow", function(s)
        local bag = ns.UI.Frame.GetFrame()
        s:ClearAllPoints()
        if bag then s:SetPoint("TOPRIGHT", bag, "TOPLEFT", -8, -60)
        else s:SetPoint("CENTER") end
        Refresh()
    end)
end

ns.On("OPTIONS_TOGGLE", function()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end)

ns.On("FRAME_HIDDEN", function()
    if frame then frame:Hide() end
end)
