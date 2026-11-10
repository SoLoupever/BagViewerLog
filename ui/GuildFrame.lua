local addonName, ns = ...

-- Cadre du coffre de guilde : onglets et objets viennent de ns.Guild, les
-- emplacements sont de vrais boutons (dépôt / retrait natifs). Vue fusionnée
-- par catégories, ou filtrée sur un onglet (barre d'onglets).
-- Journal, infos et achat d'onglet : cadre Blizzard (événement
-- GUILD_BLIZZARD_REQUESTED, géré par core/ReplaceGuild.lua).

local C  = ns.UI.Colors
local IB = ns.UI.NewItemButtons()

local COLS, SLOT, GAP, PAD = 20, 37, 4, 12
local SCROLLBAR_W = 24
local TOP_CHROME, BOTTOM_CHROME = 80, 52

local CONTENT_W = COLS * SLOT + (COLS - 1) * GAP
local FRAME_W   = PAD * 2 + CONTENT_W + SCROLLBAR_W

local frame, content, emptyText, title, Grid, tabBar, footer
local keepInteraction = false

local function Title()
    local name = GetGuildInfo("player")
    title:SetText(name and ns.L("GUILD_TITLE_FMT"):format(name) or ns.L("GUILD_TITLE"))
end

local function Layout()
    local snap = ns.Guild.Get()
    local tabs = ns.Guild.GetTabs()
    local viewable = false
    for i = 1, #tabs do
        if tabs[i].canView then viewable = true break end
    end

    tabBar.Update(tabs, ns.Guild.GetFilter())
    footer.Update()

    local contentH = Grid.Render(snap, { holding = ns.Cursor.GetItemID() ~= nil, showCustom = false })
    content:SetHeight(contentH)
    emptyText:SetShown(not viewable)
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
    _G["BagViewerLogGuildFrame"] = frame
    frame:SetSize(FRAME_W, TOP_CHROME + BOTTOM_CHROME)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:Hide()
    table.insert(UISpecialFrames, "BagViewerLogGuildFrame")

    title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

    local close = ns.UI.Button(frame, 26, 26, "X")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    tabBar = ns.UI.GuildTabBar.New(frame, function(index) ns.Guild.SetFilter(index) end)
    footer = ns.UI.GuildFooter.New(frame, function() ns.Fire("GUILD_BLIZZARD_REQUESTED") end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PAD, -TOP_CHROME)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(PAD + SCROLLBAR_W), BOTTOM_CHROME)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    IB.SetContainer(content)
    Grid = ns.UI.NewCategoryGrid({
        content = content, IB = IB, Sections = ns.UI.NewSections(),
        cols = COLS, prefix = "guild:", refresh = Layout, usePlus = true,
    })

    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    emptyText:SetText(ns.L("GUILD_NO_TABS"))

    frame:SetScript("OnShow", function()
        ns.Guild.SetActive(true)
        Title()
        Layout()
    end)
    frame:SetScript("OnHide", function()
        ns.Guild.SetActive(false)
        IB.ReleaseAll()
        -- ÉCHAP ou X : l'interaction avec le coffre se ferme aussi.
        local gb = _G.GuildBankFrame
        if not keepInteraction and gb and gb:IsShown() then HideUIPanel(gb) end
        keepInteraction = false
    end)

    -- Un seul rendu par image, même si plusieurs événements arrivent ensemble.
    local queued = false
    local function QueueLayout()
        if queued then return end
        queued = true
        C_Timer.After(0, function()
            queued = false
            if frame:IsShown() then Layout() end
        end)
    end
    for _, ev in ipairs({ "GUILD_CHANGED", "GUILD_MONEY_CHANGED", "CURSOR_ITEM_CHANGED",
                          "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
        ns.On(ev, QueueLayout)
    end
end

-- ── API du cadre ──────────────────────────────────────────────────
ns.UI.Guild = {}

function ns.UI.Guild.Show()
    if not frame then Build() end
    frame:Show()
end

-- keep : masque la vue sans fermer l'interaction (passage au cadre Blizzard).
function ns.UI.Guild.Hide(keep)
    if not frame then return end
    keepInteraction = keep and frame:IsShown() or false
    frame:Hide()
end

function ns.UI.Guild.IsShown()
    return frame ~= nil and frame:IsShown()
end
