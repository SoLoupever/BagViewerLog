local addonName, ns = ...

-- Barre des sacs équipés (sac à dos, 4 sacs, sac de composants), en lecture
-- seule, collée à gauche du sac. Les événements ne sont écoutés que visible.

local C = ns.UI.Colors

local SIZE, GAP, PAD = 40, 6, 8
local FIRST_BAG, LAST_BAG = 0, 5
local BACKPACK = "Interface\\Buttons\\Button-Backpack-Up"
local EMPTY    = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag"
local REAGENT_BAG = Enum.BagIndex.ReagentBag

local bar
local slots = {}

local function UpdateSlot(s)
    local bag = s.bag
    local invID = bag > FIRST_BAG and C_Container.ContainerIDToInventoryID(bag) or nil
    s.invID = invID
    s.link = invID and GetInventoryItemLink("player", invID) or nil

    local tex = bag == FIRST_BAG and BACKPACK or (invID and GetInventoryItemTexture("player", invID))
    s.icon:SetTexture(tex or EMPTY)
    s.icon:SetAlpha(tex and 1 or 0.4)
    s.count:SetText(tex and C_Container.GetContainerNumSlots(bag) or "")

    local r, g, b = C.innerBorder[1], C.innerBorder[2], C.innerBorder[3]
    if s.link then
        local q = C_Item.GetItemQualityByID(s.link)
        if q then r, g, b = C_Item.GetItemQualityColor(q) end
    end
    s:SetBackdropBorderColor(r, g, b, 1)
end

local function ShowTip(s)
    GameTooltip:SetOwner(s, "ANCHOR_TOP")
    if s.link then
        GameTooltip:SetInventoryItem("player", s.invID)
    elseif s.bag == FIRST_BAG then
        GameTooltip:AddLine(ns.L("BAGS_BACKPACK"), 1, 1, 1)
        GameTooltip:AddLine(ns.L("BAGS_SLOTS_FMT"):format(C_Container.GetContainerNumSlots(s.bag)), 1, 0.82, 0)
    else
        GameTooltip:AddLine(ns.L(s.bag == REAGENT_BAG and "BAGS_REAGENT" or "BAGS_EMPTY_SLOT"), 1, 1, 1)
    end
    GameTooltip:Show()
end

local function Refresh()
    for i = 1, #slots do UpdateSlot(slots[i]) end
end

local function Build()
    local n = LAST_BAG - FIRST_BAG + 1
    bar = ns.UI.Flat(UIParent, "bg", "border")
    bar:SetFrameStrata("HIGH")
    bar:SetSize(PAD * 2 + n * SIZE + (n - 1) * GAP, PAD * 2 + SIZE)
    bar:Hide()

    for bag = FIRST_BAG, LAST_BAG do
        local s = ns.UI.Flat(bar, "inner", "innerBorder", "Button")
        s:SetSize(SIZE, SIZE)
        s:SetPoint("LEFT", bar, "LEFT", PAD + bag * (SIZE + GAP), 0)
        s.bag = bag

        s.icon = s:CreateTexture(nil, "ARTWORK")
        s.icon:SetPoint("TOPLEFT", 3, -3)
        s.icon:SetPoint("BOTTOMRIGHT", -3, 3)
        s.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        s.count = s:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        s.count:SetPoint("BOTTOMRIGHT", -3, 3)

        s:SetScript("OnEnter", ShowTip)
        s:SetScript("OnLeave", GameTooltip_Hide)
        slots[#slots + 1] = s
    end

    bar:SetScript("OnShow", function(f)
        f:RegisterEvent("BAG_CONTAINER_UPDATE")
        f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        Refresh()
    end)
    bar:SetScript("OnHide", function(f)
        f:UnregisterAllEvents()
    end)
    bar:SetScript("OnEvent", Refresh)
end

ns.On("BAGS_TOGGLE", function()
    if not bar then Build() end
    if bar:IsShown() then
        bar:Hide()
        return
    end
    local bag = ns.UI.Frame.GetFrame()
    if not bag then return end
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOMRIGHT", bag, "BOTTOMLEFT", -8, 0)
    bar:Show()
end)

ns.On("FRAME_HIDDEN", function()
    if bar then bar:Hide() end
end)
