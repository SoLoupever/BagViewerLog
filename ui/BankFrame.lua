local addonName, ns = ...

-- Cadre de banque (personnage / bataillon) : types et onglets viennent de
-- ns.Bank, les emplacements sont de vrais boutons (dépôt / retrait natifs).
-- Tous les onglets du type actif sont fusionnés en une seule vue par catégories ;
-- la hauteur suit le contenu.

local C  = ns.UI.Colors
local IB = ns.UI.NewItemButtons()

local COLS, SLOT, GAP, PAD = 20, 37, 4, 12
local SCROLLBAR_W = 24
local TOP_CHROME, BOTTOM_CHROME = 80, 52

local CONTENT_W = COLS * SLOT + (COLS - 1) * GAP
local FRAME_W   = PAD * 2 + CONTENT_W + SCROLLBAR_W

local frame, content, emptyText, Grid
local typeBtns = {}
local curType

local Refresh

-- ── Synchro Blizzard ──────────────────────────────────────────────
-- Le dépôt par clic droit depuis le sac suit le type actif du BankFrame.
local function SyncBlizzard(def)
    local bf = _G.BankFrame
    if not (bf and bf.SetTab) then return end
    local tabID = (def.bankType == Enum.BankType.Account) and bf.accountBankTabID or bf.characterBankTabID
    if tabID then pcall(bf.SetTab, bf, tabID) end
end

-- ── Boutons ───────────────────────────────────────────────────────
local function Highlight(btn, on)
    local c = on and C.btnHoverBorder or C.btnBorder
    btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    btn.selected = on
end

local function GetTypeButton(i)
    local b = typeBtns[i]
    if not b then
        b = ns.UI.Button(frame, 110, 26, "")
        b:SetScript("OnLeave", function(s) Highlight(s, s.selected) end)
        typeBtns[i] = b
    end
    return b
end

-- ── Grille ────────────────────────────────────────────────────────
local function Layout()
    local def = curType and ns.Bank.GetType(curType)
    local snap = def and ns.Bank.GetSnapshot(curType) or { groups = {}, free = {}, numTabs = 0 }

    local contentH = Grid.Render(snap, { holding = false, showCustom = false })
    content:SetHeight(contentH)
    emptyText:SetShown(snap.numTabs == 0)
    -- La fenêtre suit le contenu, plafonnée à la hauteur de l'écran.
    frame:SetHeight(math.min(contentH + TOP_CHROME + BOTTOM_CHROME, UIParent:GetHeight()))
end

local function SwitchType(id)
    curType = id
    SyncBlizzard(ns.Bank.GetType(id))
    Refresh()
end

Refresh = function()
    local types = ns.Bank.GetTypes()

    if not (curType and ns.Bank.GetType(curType)) then
        local active = _G.BankFrame and _G.BankFrame:GetActiveBankType()
        curType = types[1] and types[1].id
        for _, d in ipairs(types) do
            if d.bankType == active then curType = d.id end
        end
    end

    for i, def in ipairs(types) do
        local b = GetTypeButton(i)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + (i - 1) * 116, -44)
        b.label:SetText(ns.L(def.labelKey))
        b:SetScript("OnClick", function() SwitchType(def.id) end)
        Highlight(b, def.id == curType)
        b:Show()
    end
    for i = #types + 1, #typeBtns do typeBtns[i]:Hide() end

    Layout()
end

-- ── Construction ──────────────────────────────────────────────────
local function Build()
    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
    frame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])
    _G["BagViewerLogBankFrame"] = frame
    frame:SetSize(FRAME_W, TOP_CHROME + BOTTOM_CHROME)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetFrameStrata("DIALOG")   -- au-dessus du chat (HIGH)
    frame:EnableMouse(true)
    frame:Hide()
    table.insert(UISpecialFrames, "BagViewerLogBankFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    title:SetText(ns.L("BANK_TITLE"))

    local close = ns.UI.Button(frame, 26, 26, "X")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    local deposit = ns.UI.Button(frame, 160, 26, ns.L("BANK_DEPOSIT"))
    deposit:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    deposit:SetScript("OnClick", function()
        local def = curType and ns.Bank.GetType(curType)
        if def then C_Bank.AutoDepositItemsIntoBank(def.bankType) end
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PAD, -TOP_CHROME)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(PAD + SCROLLBAR_W), BOTTOM_CHROME)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    IB.SetContainer(content)
    Grid = ns.UI.NewCategoryGrid({
        content = content, IB = IB, Sections = ns.UI.NewSections(),
        cols = COLS, prefix = "bank:", refresh = Refresh,
    })

    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    emptyText:SetText(ns.L("BANK_NO_TABS"))

    frame:SetScript("OnShow", function()
        curType = nil
        ns.Bank.SetActive(true)
        Refresh()
    end)
    frame:SetScript("OnHide", function()
        ns.Bank.SetActive(false)
        IB.ReleaseAll()
        -- ÉCHAP ou X : l'interaction banquier se ferme aussi.
        if _G.BankFrame and _G.BankFrame:IsShown() then HideUIPanel(_G.BankFrame) end
    end)

    ns.On("BANK_CHANGED", function()
        if frame:IsShown() then Refresh() end
    end)
end

-- ── API du cadre ──────────────────────────────────────────────────
ns.UI.Bank = {}

function ns.UI.Bank.Show()
    if not frame then Build() end
    frame:Show()
end

function ns.UI.Bank.Hide()
    if frame then frame:Hide() end
end

function ns.UI.Bank.IsShown()
    return frame ~= nil and frame:IsShown()
end
