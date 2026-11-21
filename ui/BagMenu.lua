local addonName, ns = ...

-- Menu clic droit d'un sac : cadre plat maison, sans menu Blizzard (taint).
-- BAGS_MENU(ancre, bagID). Reste ouvert jusqu'à un clic à côté ou Échap.

local C = ns.UI.Colors

local W, ROW_H, PAD = 200, 22, 6
local frame, catcher
local rows = {}
local entries = {}
local curBag

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, frame)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", PAD, -PAD - (i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", -PAD, -PAD - (i - 1) * ROW_H)

    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints()
    r.hl:SetColorTexture(1, 1, 1, 0.08)

    r.check = r:CreateTexture(nil, "ARTWORK")
    r.check:SetSize(16, 16)
    r.check:SetPoint("LEFT", 2, 0)
    r.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")

    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetPoint("LEFT", 24, 0)
    r.text:SetPoint("RIGHT", -2, 0)
    r.text:SetJustifyH("LEFT")

    r:SetScript("OnClick", function(s)
        local e = entries[s.index]
        if not e or not e.set then return end
        e.set(not e.get())
        s.check:SetShown(e.get() and true or false)
    end)
    rows[i] = r
    return r
end

local function Build()
    catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN")
    catcher:RegisterForClicks("AnyUp")
    catcher:Hide()

    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetWidth(W)
    frame:Hide()

    catcher:SetScript("OnClick", function() frame:Hide() end)
    frame:SetScript("OnShow", function() catcher:Show() end)
    frame:SetScript("OnHide", function() catcher:Hide() end)
end

-- Entrées : titre ou case à cocher (get / set).
local function Fill(bag)
    local F = ns.BagFlags
    wipe(entries)
    if F.CanFilter(bag) then
        entries[#entries + 1] = { text = ns.L("BAGFLAG_ASSIGN") }
        for _, def in ipairs(F.GetFilters()) do
            entries[#entries + 1] = {
                text = ns.L(def.key),
                get = function() return F.Get(bag, def.flag) end,
                set = function(on) F.Set(bag, def.flag, on) end,
            }
        end
    end
    entries[#entries + 1] = { text = ns.L("BAGFLAG_IGNORE") }
    entries[#entries + 1] = {
        text = ns.L("BAGFLAG_NO_SORT"),
        get = function() return F.GetIgnoreSort(bag) end,
        set = function(on) F.SetIgnoreSort(bag, on) end,
    }
    entries[#entries + 1] = {
        text = ns.L("BAGFLAG_NO_JUNK"),
        get = function() return F.GetIgnoreJunk(bag) end,
        set = function(on) F.SetIgnoreJunk(bag, on) end,
    }
end

ns.On("BAGS_MENU", function(anchor, bag)
    if not frame then
        Build()
        tinsert(UISpecialFrames, "BagViewerLogBagMenu")
        _G.BagViewerLogBagMenu = frame
    end
    if frame:IsShown() and curBag == bag then
        frame:Hide()
        return
    end
    curBag = bag
    Fill(bag)

    for i = 1, math.max(#entries, #rows) do
        local e, r = entries[i], Row(i)
        r.index = i
        if e then
            r.text:SetText(e.text)
            if e.set then
                r.text:SetTextColor(C.text[1], C.text[2], C.text[3])
                r.check:SetShown(e.get() and true or false)
                r:Enable()
            else
                r.text:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
                r.check:Hide()
                r:Disable()
            end
            r:Show()
        else
            r:Hide()
        end
    end

    frame:SetHeight(PAD * 2 + #entries * ROW_H)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
    frame:Show()
end)
