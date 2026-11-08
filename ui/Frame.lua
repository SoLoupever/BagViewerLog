local addonName, ns = ...

-- Cadre principal : coque, zones de widgets et disposition des catégories.
-- Les widgets viennent du registre (ui/Registry.lua), les données de
-- ns.Inventory ; ce fichier ne connaît aucun widget en particulier.

local C  = ns.UI.Colors
local IB = ns.UI.ItemButtons

-- Dimensions : profil "standard" ou "compact" (ui/metrics/), voir Apply.
local M
local frame, content, Grid, Layout
local curW   -- largeur de grille appliquée
local title, titleArea, toolbar, footer, scroll, sidebar

local function CurrentMetrics()
    return ns.UI.GetMetrics(ns.Compact.IsEnabled() and "compact" or "standard")
end

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

-- Zone verticale (panneau latéral) : widgets "top", de haut en bas.
local function PlaceColumn(area, host)
    local prev
    for _, d in ipairs(ns.UI.GetWidgets(area, "top")) do
        local w = d.build(host)
        local rel, point = prev or host, prev and "BOTTOMLEFT" or "TOPLEFT"
        local relR = prev and "BOTTOMRIGHT" or "TOPRIGHT"
        w:SetPoint("TOPLEFT",  rel, point, 0, prev and -6 or 0)
        w:SetPoint("TOPRIGHT", rel, relR,  0, prev and -6 or 0)
        prev = w
    end
end

-- ── Disposition ───────────────────────────────────────────────────
function Layout()
    local contentH, usedW = Grid.Render(ns.Inventory.Get(), {
        holding    = ns.Cursor.GetItemID() ~= nil,
        showCustom = true,
        view       = ns.View.GetCurrent(),
    })
    content:SetHeight(contentH)
    -- La largeur suit la rangée la plus large (minimum du profil).
    local w = math.min(math.max(usedW, M.minContentW), M.contentW)
    if w ~= curW then
        curW = w
        content:SetWidth(w)
        frame:SetWidth(M.bodyX + w + M.scrollW + M.pad)
    end
    -- La fenêtre suit le contenu, plafonnée (profil, écran).
    frame:SetHeight(math.min(math.max(contentH + M.topChrome + M.bottomChrome, M.minHeight or 0),
                             M.maxHeight or math.huge, UIParent:GetHeight()))
end

-- Pose les zones selon le profil courant (construction, changement de mode).
local function Apply()
    M = CurrentMetrics()
    curW = nil   -- recalculée au prochain Layout
    frame:SetWidth(M.frameW)

    title:ClearAllPoints()
    title:SetPoint("TOP", frame, "TOP", 0, -M.titleTextY)

    titleArea:ClearAllPoints()
    titleArea:SetPoint("TOPLEFT",  frame, "TOPLEFT",  M.pad, -M.titleAreaY)
    titleArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -M.pad, -M.titleAreaY)

    toolbar:ClearAllPoints()
    toolbar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  M.pad, -M.titleH)
    toolbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -M.pad, -M.titleH)
    toolbar:SetHeight(M.toolbarH)

    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  M.pad, M.pad)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -M.pad, M.pad)
    footer:SetHeight(M.footerH)

    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     M.bodyX, -M.topChrome)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(M.pad + M.scrollW), M.bottomChrome)
    content:SetWidth(M.contentW)

    sidebar:SetShown(M.sideW > 0)
    if M.sideW > 0 then
        sidebar:ClearAllPoints()
        sidebar:SetPoint("TOPLEFT",    frame, "TOPLEFT",    M.pad, -M.topChrome)
        sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", M.pad, M.bottomChrome)
        sidebar:SetWidth(M.sideW)
    end

    ns.View.SetEnabled(M.views)

    Grid.SetMetrics(M)
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
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:Hide()
    table.insert(UISpecialFrames, "BagViewerLogFrame")

    -- Collé en bas à droite ; la hauteur est fixée par Layout.
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

    title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    local class = select(2, UnitClass("player"))
    local color = class and RAID_CLASS_COLORS[class]
    local name  = UnitName("player")
    title:SetText(string.format(ns.L("TITLE_FMT"),
        color and color:WrapTextInColorCode(name) or name))

    titleArea = CreateFrame("Frame", nil, frame)
    titleArea:SetHeight(26)
    PlaceArea("title", titleArea)

    toolbar = CreateFrame("Frame", nil, frame)
    PlaceArea("toolbar", toolbar)

    footer = CreateFrame("Frame", nil, frame)
    PlaceArea("footer", footer)

    sidebar = ns.UI.Flat(frame, "inner", "innerBorder")
    PlaceColumn("sidebar", sidebar)

    scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    IB.SetContainer(content)
    Grid = ns.UI.NewCategoryGrid({
        content = content, IB = IB, Sections = ns.UI.NewSections(),
        cols = 15, prefix = "", refresh = Layout, usePlus = true, context = true,
    })
    Apply()
    frame:SetHeight(M.topChrome + M.bottomChrome)

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
    ns.On("COMPACT_CHANGED", function()
        Apply()
        if frame:IsShown() then Layout() end
    end)
    -- Le rendu suit : VIEW_CHANGED reconstruit l'inventaire (INVENTORY_CHANGED).
    ns.On("VIEW_CHANGED", function()
        scroll:SetVerticalScroll(0)
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
