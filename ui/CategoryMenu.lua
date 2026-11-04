local addonName, ns = ...

-- Menu des catégories : liste (catégories + sous-catégories), création,
-- renommage et suppression des catégories du joueur. Les catégories de base
-- sont listées mais non modifiables. Saisie et confirmation : popups Blizzard
-- GENERIC_INPUT_BOX / GENERIC_CONFIRMATION.

local C = ns.UI.Colors

local W, H = 340, 460
local PAD, ROW_H, INDENT = 12, 24, 16
local LIST_W = W - PAD * 2 - 24

local frame, content
local rows = {}
local selected
local btnSub, btnRename, btnDelete

local function Prompt(text, callback)
    StaticPopup_Show("GENERIC_INPUT_BOX", nil, nil, {
        text = text, maxLetters = 20,
        callback = function(value)
            value = strtrim(value or "")
            if value ~= "" then callback(value) end
        end,
    })
end

local function SetEnabled(btn, on)
    if on then btn:Enable() else btn:Disable() end
    btn:SetAlpha(on and 1 or 0.4)
end

local function UpdateButtons()
    local def = selected and ns.GetCategory(selected)
    SetEnabled(btnSub, def ~= nil and def.parent == nil)
    SetEnabled(btnRename, def ~= nil and def.custom == true)
    SetEnabled(btnDelete, def ~= nil and def.custom == true)
end

local function GetRow(i)
    local r = rows[i]
    if not r then
        r = ns.UI.Flat(content, "inner", "innerBorder", "Button")
        r:SetHeight(ROW_H)
        r.label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.label:SetPoint("LEFT", 8, 0)
        rows[i] = r
    end
    return r
end

local function Refresh()
    -- Catégories racines puis leurs sous-catégories (hors catégories système).
    local list = {}
    for _, def in ipairs(ns.GetTopCategories()) do
        if not def.noAssign then
            list[#list + 1] = { def = def, indent = 0 }
            for _, kid in ipairs(ns.GetChildren(def.id)) do
                list[#list + 1] = { def = kid, indent = INDENT }
            end
        end
    end

    if selected and not ns.GetCategory(selected) then selected = nil end

    for i, e in ipairs(list) do
        local r = GetRow(i)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", content, "TOPLEFT", e.indent, -(i - 1) * (ROW_H + 2))
        r:SetWidth(LIST_W - e.indent)
        r.label:SetText(ns.GetCategoryLabel(e.def))
        local tint = e.def.custom and C.btnText or C.text
        r.label:SetTextColor(tint[1], tint[2], tint[3], 1)
        local isSel = e.def.id == selected
        local bd = isSel and C.btnHoverBorder or C.innerBorder
        r:SetBackdropBorderColor(bd[1], bd[2], bd[3], 1)
        r:SetScript("OnClick", function()
            selected = e.def.id
            Refresh()
        end)
        r:Show()
    end
    for i = #list + 1, #rows do rows[i]:Hide() end

    content:SetHeight(math.max(1, #list * (ROW_H + 2)))
    UpdateButtons()
end

local function Build()
    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetSize(W, H)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:Hide()
    _G["BagViewerLogMenu"] = frame
    table.insert(UISpecialFrames, "BagViewerLogMenu")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    title:SetText(ns.L("MENU_TITLE"))

    local close = ns.UI.Button(frame, 26, 26, "X")
    close:SetPoint("TOPRIGHT", -PAD, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", PAD, -48)
    scroll:SetPoint("BOTTOMRIGHT", -(PAD + 24), 96)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LIST_W, 1)
    scroll:SetScrollChild(content)

    local half = (W - PAD * 2 - 8) / 2

    local btnNew = ns.UI.Button(frame, half, 26, ns.L("MENU_NEW"))
    btnNew:SetPoint("BOTTOMLEFT", PAD, 50)
    btnNew:SetScript("OnClick", function()
        Prompt(ns.L("MENU_PROMPT_NEW"), function(name) ns.Custom.Add(name) end)
    end)

    btnSub = ns.UI.Button(frame, half, 26, ns.L("MENU_SUB"))
    btnSub:SetPoint("BOTTOMRIGHT", -PAD, 50)
    btnSub:SetScript("OnClick", function()
        local parent = selected
        Prompt(ns.L("MENU_PROMPT_SUB"), function(name) ns.Custom.Add(name, parent) end)
    end)

    btnRename = ns.UI.Button(frame, half, 26, ns.L("MENU_RENAME"))
    btnRename:SetPoint("BOTTOMLEFT", PAD, PAD)
    btnRename:SetScript("OnClick", function()
        local id = selected
        Prompt(ns.L("MENU_PROMPT_RENAME"), function(name) ns.Custom.Rename(id, name) end)
    end)

    btnDelete = ns.UI.Button(frame, half, 26, ns.L("MENU_DELETE"))
    btnDelete:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    btnDelete:SetScript("OnClick", function()
        local id = selected
        local def = id and ns.GetCategory(id)
        if not def then return end
        StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, {
            text = ns.L("MENU_CONFIRM_DELETE"),
            text_arg1 = ns.GetCategoryLabel(def),
            callback = function() ns.Custom.Remove(id) end,
        })
    end)

    frame:SetScript("OnShow", function(s)
        -- À gauche du sac, sinon au centre.
        local bag = ns.UI.Frame.GetFrame()
        s:ClearAllPoints()
        if bag then s:SetPoint("TOPRIGHT", bag, "TOPLEFT", -8, -60)
        else s:SetPoint("CENTER") end
        Refresh()
    end)

    ns.On("CATEGORIES_CHANGED", function()
        if frame:IsShown() then Refresh() end
    end)
end

ns.On("MENU_TOGGLE", function()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end)
