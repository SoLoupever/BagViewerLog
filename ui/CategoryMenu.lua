local addonName, ns = ...

-- Menu des catégories : liste réordonnable (flèches, glisser-déposer), création,
-- renommage, suppression, et objets classés à la main dans la catégorie choisie.
-- Les catégories de base sont listées mais non modifiables. Saisie et
-- confirmation : popups Blizzard GENERIC_INPUT_BOX / GENERIC_CONFIRMATION.

local C = ns.UI.Colors

local W, H = 440, 600
local PAD, STEP = 12, 28
local LIST_W = W - PAD * 2 - 24
local LIST_H = 8 * STEP
local EMPTY = {}

local frame, list, items
local selected
local btnSub, btnRename, btnDelete, btnAddItem
local panelTitle, status, idBox

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

-- Objets du sac dans la catégorie, sous-catégories comprises.
local function Count(id)
    local groups = ns.Inventory.Get().groups
    local n = #(groups[id] or EMPTY)
    for _, kid in ipairs(ns.GetChildren(id)) do n = n + #(groups[kid.id] or EMPTY) end
    return n
end

local function Refresh()
    if selected and not ns.GetCategory(selected) then selected = nil end
    local def = selected and ns.GetCategory(selected)

    list.Refresh(selected)
    items.Set(selected)

    SetEnabled(btnSub, def ~= nil and def.parent == nil)
    SetEnabled(btnRename, def ~= nil and def.custom == true)
    SetEnabled(btnDelete, def ~= nil and def.custom == true)
    SetEnabled(btnAddItem, def ~= nil)
    panelTitle:SetText(def and ns.L("MENU_ITEMS_FMT"):format(ns.GetCategoryLabel(def))
                       or ns.L("MENU_SELECT_HINT"))
end

local function AddItem()
    if not selected then return end
    local id = tonumber(idBox:GetText())
    if not id or not C_Item.GetItemInfoInstant(id) then
        status:SetText(ns.L("MENU_ITEM_INVALID"))
        status:Show()
        return
    end
    status:Hide()
    idBox:SetText("")
    idBox:ClearFocus()
    ns.Assign.Set(id, selected)
end

local function Label(text, point, x, y)
    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint(point, x, y)
    fs:SetText(text)
    return fs
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

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", PAD, -44)
    hint:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    hint:SetText(ns.L("MENU_HINT_ORDER"))

    -- ── Liste ─────────────────────────────────────────────────────
    list = ns.UI.NewCategoryList(frame, {
        width = LIST_W, height = LIST_H,
        getCount = Count,
        onSelect = function(id)
            selected = id
            Refresh()
        end,
        onMove = ns.Order.Move,
        onDrop = ns.Order.MoveTo,
    })
    list.scroll:SetPoint("TOPLEFT", PAD, -64)

    -- ── Création ──────────────────────────────────────────────────
    Label(ns.L("MENU_NEW_LABEL"), "TOPLEFT", PAD, -298)

    local newBox = ns.UI.EditBox(frame, 26, 20)
    newBox:SetPoint("TOPLEFT", PAD, -318)
    newBox:SetPoint("TOPRIGHT", -(PAD + 108), -318)

    local function AddCategory()
        local name = strtrim(newBox:GetText() or "")
        if name == "" then return end
        newBox:SetText("")
        newBox:ClearFocus()
        ns.Custom.Add(name)
    end
    newBox:SetScript("OnEnterPressed", AddCategory)

    local btnNew = ns.UI.Button(frame, 100, 26, ns.L("MENU_ADD"))
    btnNew:SetPoint("TOPRIGHT", -PAD, -318)
    btnNew:SetScript("OnClick", AddCategory)

    -- ── Actions sur la catégorie choisie ──────────────────────────
    local third = (W - PAD * 2 - 12) / 3

    btnSub = ns.UI.Button(frame, third, 26, ns.L("MENU_SUB"))
    btnSub:SetPoint("TOPLEFT", PAD, -354)
    btnSub:SetScript("OnClick", function()
        local parent = selected
        Prompt(ns.L("MENU_PROMPT_SUB"), function(name) ns.Custom.Add(name, parent) end)
    end)

    btnRename = ns.UI.Button(frame, third, 26, ns.L("MENU_RENAME"))
    btnRename:SetPoint("TOPLEFT", PAD + third + 6, -354)
    btnRename:SetScript("OnClick", function()
        local id = selected
        Prompt(ns.L("MENU_PROMPT_RENAME"), function(name) ns.Custom.Rename(id, name) end)
    end)

    btnDelete = ns.UI.Button(frame, third, 26, ns.L("MENU_DELETE"))
    btnDelete:SetPoint("TOPRIGHT", -PAD, -354)
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

    -- ── Objets classés à la main ──────────────────────────────────
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", PAD, -392)
    sep:SetPoint("TOPRIGHT", -PAD, -392)
    sep:SetColorTexture(C.accentDim[1], C.accentDim[2], C.accentDim[3], 0.8)

    panelTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panelTitle:SetPoint("TOPLEFT", PAD, -402)
    panelTitle:SetPoint("TOPRIGHT", -PAD, -402)
    panelTitle:SetJustifyH("LEFT")
    panelTitle:SetWordWrap(false)
    panelTitle:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)

    items = ns.UI.NewItemList(frame, {
        getItems = ns.Assign.GetItems,
        onRemove = ns.Assign.Clear,
    })
    items.scroll:SetPoint("TOPLEFT", PAD, -424)
    items.scroll:SetPoint("BOTTOMRIGHT", -(PAD + 24), PAD + 54)

    status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", PAD, PAD + 34)
    status:SetTextColor(1, 0.3, 0.3, 1)
    status:Hide()

    Label(ns.L("MENU_ITEM_ID"), "BOTTOMLEFT", PAD, PAD + 6)

    idBox = ns.UI.EditBox(frame, 26, 9)
    idBox:SetNumeric(true)
    idBox:SetPoint("BOTTOMLEFT", PAD + 90, PAD)
    idBox:SetPoint("BOTTOMRIGHT", -(PAD + 156), PAD)
    idBox:SetScript("OnEnterPressed", AddItem)
    idBox:SetScript("OnTextChanged", function() status:Hide() end)

    btnAddItem = ns.UI.Button(frame, 148, 26, ns.L("MENU_ADD_ITEM"))
    btnAddItem:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    btnAddItem:SetScript("OnClick", AddItem)

    frame:SetScript("OnShow", function(s)
        -- À gauche du sac, sinon au centre.
        local bag = ns.UI.Frame.GetFrame()
        s:ClearAllPoints()
        if bag then s:SetPoint("TOPRIGHT", bag, "TOPLEFT", -8, -60)
        else s:SetPoint("CENTER") end
        Refresh()
    end)

    for _, ev in ipairs({ "CATEGORIES_CHANGED", "ASSIGN_CHANGED", "INVENTORY_CHANGED" }) do
        ns.On(ev, function()
            if frame:IsShown() then Refresh() end
        end)
    end
end

ns.On("MENU_TOGGLE", function()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end)
