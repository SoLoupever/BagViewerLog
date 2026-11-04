local addonName, ns = ...

-- Cadre principal : coque, zones de widgets et disposition des catégories.
-- Les widgets viennent du registre (ui/Registry.lua), les données de
-- ns.Inventory ; ce fichier ne connaît aucun widget en particulier.

local C  = ns.UI.Colors
local IB = ns.UI.ItemButtons

local COLS, SLOT, GAP, PAD = 13, 37, 4, 12
local SCROLLBAR_W = 24
local TITLE_H, TOOLBAR_H, FOOTER_H = 44, 26, 20

local CONTENT_W = COLS * SLOT + (COLS - 1) * GAP
local FRAME_W   = PAD * 2 + CONTENT_W + SCROLLBAR_W
local TOP_CHROME    = TITLE_H + TOOLBAR_H + 8
local BOTTOM_CHROME = PAD + FOOTER_H + 8

local frame, content, Grid, Layout

-- ── Zones de widgets ──────────────────────────────────────────────
-- "right" : de la droite vers la gauche. "left" : de la gauche vers la droite ;
-- le widget flex remplit jusqu'au premier widget de droite.
local function PlaceArea(area, host)
    local prev
    for _, d in ipairs(ns.UI.GetWidgets(area, "right")) do
        local w = d.build(host)
        if prev then w:SetPoint("RIGHT", prev, "LEFT", -6, 0)
        else w:SetPoint("RIGHT", host, "RIGHT", 0, 0) end
        prev = w
    end
    local firstRight = prev

    prev = nil
    for _, d in ipairs(ns.UI.GetWidgets(area, "left")) do
        local w = d.build(host)
        if prev then w:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        else w:SetPoint("LEFT", host, "LEFT", 0, 0) end
        if d.flex then
            if firstRight then w:SetPoint("RIGHT", firstRight, "LEFT", -6, 0)
            else w:SetPoint("RIGHT", host, "RIGHT", 0, 0) end
        end
        prev = w
    end
end

-- ── Disposition ───────────────────────────────────────────────────
-- Premier emplacement libre hors sac de composants.
local function PickFree(free)
    for i = 1, #free do
        if free[i].bag < 5 then return free[i] end
    end
    return free[1]
end

function Layout()
    local contentH = Grid.Render(ns.Inventory.Get(), {
        holding    = ns.Cursor.GetItemID() ~= nil,
        showCustom = true,
        pickFree   = PickFree,
    })
    content:SetHeight(contentH)
    -- La fenêtre suit le contenu, plafonnée à la hauteur de l'écran.
    frame:SetHeight(math.min(contentH + TOP_CHROME + BOTTOM_CHROME, UIParent:GetHeight()))
end

-- ── Construction (à la première ouverture) ────────────────────────
local function Build()
    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
    frame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])
    _G["BagViewerLogFrame"] = frame
    frame:SetWidth(FRAME_W)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:Hide()
    table.insert(UISpecialFrames, "BagViewerLogFrame")

    -- Collé en bas à droite ; la hauteur est fixée par Layout.
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    frame:SetHeight(TOP_CHROME + BOTTOM_CHROME)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    local class = select(2, UnitClass("player"))
    local color = class and RAID_CLASS_COLORS[class]
    local name  = UnitName("player")
    title:SetText(string.format(ns.L("TITLE_FMT"),
        color and color:WrapTextInColorCode(name) or name))

    local titleArea = CreateFrame("Frame", nil, frame)
    titleArea:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, -10)
    titleArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -10)
    titleArea:SetHeight(26)
    PlaceArea("title", titleArea)

    local toolbar = CreateFrame("Frame", nil, frame)
    toolbar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, -TITLE_H)
    toolbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -TITLE_H)
    toolbar:SetHeight(TOOLBAR_H)
    PlaceArea("toolbar", toolbar)

    local footer = CreateFrame("Frame", nil, frame)
    footer:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  PAD, PAD)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    footer:SetHeight(FOOTER_H)
    PlaceArea("footer", footer)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PAD, -TOP_CHROME)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(PAD + SCROLLBAR_W), BOTTOM_CHROME)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    IB.SetContainer(content)
    Grid = ns.UI.NewCategoryGrid({
        content = content, IB = IB, Sections = ns.UI.NewSections(),
        cols = COLS, prefix = "", refresh = Layout,
    })

    frame:SetScript("OnShow", function()
        ns.Inventory.SetActive(true)
    end)
    frame:SetScript("OnHide", function()
        ns.Inventory.SetActive(false)
        IB.ReleaseAll()
        ns.Fire("FRAME_HIDDEN")
    end)

    ns.On("INVENTORY_CHANGED", function()
        if frame:IsShown() then Layout() end
    end)
    ns.On("CLOSE_REQUESTED", function() frame:Hide() end)
    ns.On("CURSOR_ITEM_CHANGED", function()
        if frame:IsShown() then Layout() end
    end)
end

-- ── API du cadre ──────────────────────────────────────────────────
ns.UI.Frame = {}

function ns.UI.Frame.Show()
    if not frame then Build() end
    frame:Show()
end

function ns.UI.Frame.Hide()
    if frame then frame:Hide() end
end

function ns.UI.Frame.GetFrame()
    return frame
end

function ns.UI.Frame.IsShown()
    return frame ~= nil and frame:IsShown()
end

function ns.UI.Frame.Toggle()
    if ns.UI.Frame.IsShown() then ns.UI.Frame.Hide() else ns.UI.Frame.Show() end
end
