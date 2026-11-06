local addonName, ns = ...

-- Liste réordonnable des catégories : flèches et glisser-déposer.
-- Une ligne ne se déplace que parmi ses frères (même parent).
-- ns.UI.NewCategoryList(parent, cfg)
-- cfg = { width, height, onSelect(id), onMove(id, dir), onDrop(id, targetID, after),
--         getCount(id) }.

local C = ns.UI.Colors

local ROW_H, STEP, INDENT = 26, 28, 16
local EDGE, SCROLL_SPEED = 14, 8   -- défilement auto près des bords
local ARROW = "Interface\\Buttons\\UI-ScrollBar-Scroll%sButton-%s"

local function ArrowButton(row, up)
    local name = up and "Up" or "Down"
    local b = CreateFrame("Button", nil, row)
    b:SetSize(20, 20)
    b:SetNormalTexture(ARROW:format(name, "Up"))
    b:SetPushedTexture(ARROW:format(name, "Down"))
    b:SetDisabledTexture(ARROW:format(name, "Disabled"))
    b:SetHighlightTexture(ARROW:format(name, "Highlight"), "ADD")
    b.dir = up and -1 or 1
    b.tipKey = up and "MENU_MOVE_UP" or "MENU_MOVE_DOWN"
    return b
end

function ns.UI.NewCategoryList(parent, cfg)
    local L = {}

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetSize(cfg.width, cfg.height)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(cfg.width, 1)
    scroll:SetScrollChild(content)
    L.scroll = scroll

    local rows, nRows = {}, 0
    local selected
    local drag, ghost

    local indicator = content:CreateTexture(nil, "OVERLAY")
    indicator:SetHeight(2)
    indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    indicator:Hide()

    -- ── Glisser-déposer ───────────────────────────────────────────
    -- Première et dernière ligne du groupe d'une racine.
    local function GroupRange(rootID)
        local first
        for i = 1, nRows do
            if rows[i].id == rootID then first = i break end
        end
        local last = first
        while rows[last + 1] and rows[last + 1].parentID == rootID do last = last + 1 end
        return first, last
    end

    local function UpdateTarget(y)
        local idx = math.min(math.max(math.floor(y / STEP) + 1, 1), nRows)
        local row = rows[idx]
        local frac = (y - (idx - 1) * STEP) / STEP
        local tid, after, line

        if drag.parent then
            if row.parentID == drag.parent and row.id ~= drag.id then
                tid, after = row.id, frac > 0.5
                line = (after and idx or idx - 1) * STEP
            end
        else
            local rootID = row.parentID or row.id
            if rootID ~= drag.id then
                local first, last = GroupRange(rootID)
                tid = rootID
                after = row.parentID ~= nil or frac > 0.5
                line = (after and last or first - 1) * STEP
            end
        end

        drag.target, drag.after = tid, after
        if tid then
            indicator:ClearAllPoints()
            indicator:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -line + 1)
            indicator:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -line + 1)
            indicator:Show()
        else
            indicator:Hide()
        end
    end

    local function OnDragUpdate()
        local cx, cy = GetCursorPosition()
        local top = content:GetTop()
        if not top then return end
        local es = content:GetEffectiveScale()
        local cursorY = cy / es

        local ps = UIParent:GetEffectiveScale()
        ghost:ClearAllPoints()
        ghost:SetPoint("LEFT", UIParent, "BOTTOMLEFT", cx / ps + 12, cy / ps)

        local sTop, sBottom = scroll:GetTop(), scroll:GetBottom()
        local pos = scroll:GetVerticalScroll()
        if sTop and cursorY > sTop - EDGE then
            scroll:SetVerticalScroll(math.max(0, pos - SCROLL_SPEED))
        elseif sBottom and cursorY < sBottom + EDGE then
            scroll:SetVerticalScroll(math.min(scroll:GetVerticalScrollRange(), pos + SCROLL_SPEED))
        end

        UpdateTarget(top - cursorY)
    end

    local function StopDrag(drop)
        if not drag then return end
        content:SetScript("OnUpdate", nil)
        ghost:Hide()
        indicator:Hide()
        drag.row:SetAlpha(1)
        local d = drag
        drag = nil
        if drop and d.target then cfg.onDrop(d.id, d.target, d.after) end
    end

    local function StartDrag(row)
        if not ghost then
            ghost = ns.UI.Flat(UIParent, "inner", "border")
            ghost:SetFrameStrata("TOOLTIP")
            ghost:SetSize(170, ROW_H - 4)
            ghost.label = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ghost.label:SetPoint("LEFT", 8, 0)
        end
        drag = { row = row, id = row.id, parent = row.parentID }
        ghost.label:SetText(row.label:GetText())
        ghost:Show()
        row:SetAlpha(0.4)
        content:SetScript("OnUpdate", OnDragUpdate)
    end

    scroll:SetScript("OnHide", function() StopDrag(false) end)

    -- ── Lignes ────────────────────────────────────────────────────
    local function CreateRow()
        local r = ns.UI.Flat(content, "inner", "innerBorder", "Button")
        r:SetHeight(ROW_H)
        r:RegisterForClicks("LeftButtonUp")
        r:RegisterForDrag("LeftButton")

        r.label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.label:SetPoint("LEFT", 8, 0)
        r.count = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.count:SetPoint("LEFT", r.label, "RIGHT", 6, 0)
        r.count:SetTextColor(C.count[1], C.count[2], C.count[3], 1)

        r.down = ArrowButton(r, false)
        r.down:SetPoint("RIGHT", -6, 0)
        r.up = ArrowButton(r, true)
        r.up:SetPoint("RIGHT", r.down, "LEFT", -4, 0)
        for _, b in ipairs({ r.up, r.down }) do
            b:SetScript("OnClick", function(s) cfg.onMove(s:GetParent().id, s.dir) end)
            b:SetScript("OnEnter", function(s)
                GameTooltip:SetOwner(s, "ANCHOR_TOP")
                GameTooltip:AddLine(ns.L(s.tipKey), 1, 1, 1)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", GameTooltip_Hide)
        end

        r:SetScript("OnClick", function(s) cfg.onSelect(s.id) end)
        r:SetScript("OnDragStart", StartDrag)
        r:SetScript("OnDragStop", function() StopDrag(true) end)
        return r
    end

    local function SetRow(def, indent, parentID, canUp, canDown)
        nRows = nRows + 1
        local r = rows[nRows]
        if not r then
            r = CreateRow()
            rows[nRows] = r
        end
        r.id, r.parentID = def.id, parentID
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", content, "TOPLEFT", indent, -(nRows - 1) * STEP)
        r:SetWidth(cfg.width - indent)
        r.label:SetText(ns.GetCategoryLabel(def))
        local tint = def.custom and C.btnText or C.text
        r.label:SetTextColor(tint[1], tint[2], tint[3], 1)
        r.count:SetText("(" .. cfg.getCount(def.id) .. ")")
        local bd = def.id == selected and C.btnHoverBorder or C.innerBorder
        r:SetBackdropBorderColor(bd[1], bd[2], bd[3], 1)
        r.up:SetEnabled(canUp)
        r.down:SetEnabled(canDown)
        r:Show()
    end

    -- Catégories assignables d'un groupe, avec leurs enfants.
    local function AddGroup(defs, indent, parentID)
        local total = 0
        for i = 1, #defs do
            if not defs[i].noAssign then total = total + 1 end
        end
        local idx = 0
        for i = 1, #defs do
            local def = defs[i]
            if not def.noAssign then
                idx = idx + 1
                SetRow(def, indent, parentID, idx > 1, idx < total)
                if not parentID then AddGroup(ns.GetChildren(def.id), INDENT, def.id) end
            end
        end
    end

    function L.Refresh(sel)
        selected = sel
        nRows = 0
        AddGroup(ns.GetTopCategories(), 0, nil)
        for i = nRows + 1, #rows do rows[i]:Hide() end
        content:SetHeight(math.max(1, nRows * STEP))
    end

    return L
end
