local addonName, ns = ...

-- Barre d'onglets du coffre de guilde : « Tous » + un bouton par onglet lisible.
-- ns.UI.GuildTabBar.New(parent, onSelect(index|nil)) -> { Update(tabs, filter) }.

local C = ns.UI.Colors
local W, STEP = 84, 88

local function Highlight(btn, on)
    local c = on and C.btnHoverBorder or C.btnBorder
    btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    btn.selected = on
end

local function NewButton(parent, onSelect)
    local b = ns.UI.Button(parent, W, 26, "")
    b.label:SetWidth(W - 8)
    b.label:SetWordWrap(false)
    b:SetScript("OnLeave", function(s)
        Highlight(s, s.selected)
        GameTooltip_Hide()
    end)
    b:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(C.btnHoverBorder[1], C.btnHoverBorder[2], C.btnHoverBorder[3], 1)
        if s.tip then
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:SetText(s.tip)
        end
    end)
    b:SetScript("OnClick", function(s) onSelect(s.index) end)
    return b
end

ns.UI.GuildTabBar = {}

function ns.UI.GuildTabBar.New(parent, onSelect)
    local bar = {}
    local btns = {}   -- [1] = « Tous », [i + 1] = onglet i

    local function Get(i)
        local b = btns[i]
        if not b then
            b = NewButton(parent, onSelect)
            b:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + (i - 1) * STEP, -44)
            btns[i] = b
        end
        return b
    end

    function bar.Update(tabs, filter)
        local n = 1
        local all = Get(1)
        all.index, all.tip = nil, nil
        all.label:SetText(ns.L("GUILD_ALL"))
        Highlight(all, filter == nil)
        all:Show()
        for i = 1, #tabs do
            local t = tabs[i]
            if t.canView then
                n = n + 1
                local b = Get(n)
                b.index, b.tip = i, t.name
                b.label:SetText(t.name)
                Highlight(b, filter == i)
                b:Show()
            end
        end
        for i = n + 1, #btns do btns[i]:Hide() end
    end

    return bar
end
