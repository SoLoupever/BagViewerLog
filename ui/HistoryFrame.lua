local addonName, ns = ...

-- Fenêtre « Historique » : sacs, banque et bataillon lus dans les données de
-- ViewerLog (lecture seule). Vues et snapshots viennent de ns.History ; elle
-- s'ouvre par HISTORY_OPEN(vue) / HISTORY_TOGGLE(vue), sans connaître les boutons.

local C  = ns.UI.Colors
local IB = ns.UI.NewItemButtons()

local COLS, SLOT, GAP, PAD = 20, 37, 4, 12
local SCROLLBAR_W = 24
local TOP_CHROME, BOTTOM_CHROME = 80, 24

local CONTENT_W = COLS * SLOT + (COLS - 1) * GAP
local FRAME_W   = PAD * 2 + CONTENT_W + SCROLLBAR_W

local frame, content, emptyText, title, charBtn, Grid
local viewBtns = {}
local curView = "bags"

local function Highlight(btn, on)
    local c = on and C.btnHoverBorder or C.btnBorder
    btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    btn.selected = on
end

local function CharLabel()
    local name = ns.History.GetChar()
    local data = ns.History.GetCharData()
    local color = data and data.class and RAID_CLASS_COLORS[data.class]
    return color and color:WrapTextInColorCode(name) or name
end

local function Layout()
    local def = ns.History.GetView(curView)
    if not def then return end
    local snap = ns.History.Get(curView)

    for i = 1, #viewBtns do Highlight(viewBtns[i], viewBtns[i].viewID == curView) end

    if def.shared then
        title:SetText(ns.L("HISTORY_TITLE"))
        charBtn:Hide()
    else
        local label = CharLabel()
        title:SetText(ns.L("HISTORY_TITLE_FMT"):format(label))
        charBtn.label:SetText(label)
        charBtn:Show()
    end

    local contentH = Grid.Render(snap, { holding = false, showCustom = false })
    content:SetHeight(contentH)
    emptyText:SetShown(snap.count == 0)
    frame:SetHeight(math.min(contentH + TOP_CHROME + BOTTOM_CHROME, UIParent:GetHeight()))
end

local function Build()
    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
    frame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])
    _G["BagViewerLogHistoryFrame"] = frame
    frame:SetSize(FRAME_W, TOP_CHROME + BOTTOM_CHROME)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:Hide()
    table.insert(UISpecialFrames, "BagViewerLogHistoryFrame")

    title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

    local close = ns.UI.Button(frame, 26, 26, "X")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    for i, def in ipairs(ns.History.GetViews()) do
        local b = ns.UI.Button(frame, 110, 26, ns.L(def.labelKey))
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + (i - 1) * 116, -44)
        b.viewID = def.id
        b:SetScript("OnLeave", function(s) Highlight(s, s.selected) end)
        b:SetScript("OnClick", function(s)
            curView = s.viewID
            Layout()
        end)
        viewBtns[i] = b
    end

    charBtn = ns.UI.Button(frame, 200, 26, "")
    charBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -44)
    charBtn.label:SetWidth(192)
    charBtn.label:SetWordWrap(false)
    charBtn:SetScript("OnClick", function(s) ns.Fire("HISTORY_PICK_CHAR", s) end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PAD, -TOP_CHROME)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(PAD + SCROLLBAR_W), BOTTOM_CHROME)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    IB.SetContainer(content)
    Grid = ns.UI.NewCategoryGrid({
        content = content, IB = IB, Sections = ns.UI.NewSections(),
        cols = COLS, prefix = "history:", refresh = Layout,
    })

    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    emptyText:SetText(ns.L("HISTORY_EMPTY"))

    frame:SetScript("OnShow", function()
        ns.History.SetActive(true)
        Layout()
    end)
    frame:SetScript("OnHide", function()
        ns.History.SetActive(false)
        IB.ReleaseAll()
    end)
end

local function Open(view)
    if not frame then Build() end
    if view and ns.History.GetView(view) then curView = view end
    if frame:IsShown() then Layout() else frame:Show() end
end

ns.On("HISTORY_OPEN", Open)

ns.On("HISTORY_TOGGLE", function(view)
    if frame and frame:IsShown() and curView == view then
        frame:Hide()
    else
        Open(view)
    end
end)

-- Personnage, classement : un seul rendu par événement, fenêtre ouverte seulement.
for _, ev in ipairs({ "HISTORY_CHANGED", "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
    ns.On(ev, function()
        if frame and frame:IsShown() then Layout() end
    end)
end
