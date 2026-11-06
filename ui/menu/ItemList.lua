local addonName, ns = ...

-- Objets classés à la main dans une catégorie : icône, nom, bouton retirer.
-- ns.UI.NewItemList(parent, cfg)
-- cfg = { getItems(catID, out), onRemove(itemID) }. Tailles : posées par l'appelant.

local C = ns.UI.Colors

local ROW_H, STEP = 26, 28

function ns.UI.NewItemList(parent, cfg)
    local L = {}

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    L.scroll = scroll
    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, w) content:SetWidth(w) end)

    local empty = scroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    empty:SetPoint("TOP", scroll, "TOP", 0, -10)
    empty:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    empty:SetText(ns.L("MENU_ITEMS_EMPTY"))
    empty:Hide()

    local rows, ids = {}, {}
    local ev = CreateFrame("Frame", nil, parent)
    local listening = false

    -- Nom pas encore en cache client : demandé, rempli à la réponse.
    local function FillName(r)
        local id = r.itemID
        local name = C_Item.GetItemNameByID(id)
        if name then
            local q = C_Item.GetItemQualityByID(id)
            local cr, cg, cb = 1, 1, 1
            if q then cr, cg, cb = C_Item.GetItemQualityColor(q) end
            r.name:SetText(name)
            r.name:SetTextColor(cr, cg, cb, 1)
            r.pending = false
        else
            r.name:SetText(ns.L("MENU_ITEM_FMT"):format(id))
            r.name:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
            r.pending = true
            C_Item.RequestLoadItemDataByID(id)
        end
    end

    local function Listen(on)
        if on == listening then return end
        listening = on
        if on then ev:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        else ev:UnregisterEvent("ITEM_DATA_LOAD_RESULT") end
    end

    ev:SetScript("OnEvent", function(_, _, itemID)
        local pending = false
        for i = 1, #ids do
            local r = rows[i]
            if r.pending then
                if r.itemID == itemID then FillName(r) end
                pending = pending or r.pending
            end
        end
        if not pending then Listen(false) end
    end)

    local function CreateRow()
        local r = ns.UI.Flat(content, "inner", "innerBorder", "Button")
        r:SetHeight(ROW_H)

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(20, 20)
        r.icon:SetPoint("LEFT", 4, 0)

        r.remove = ns.UI.Button(r, 20, 20, "X")
        r.remove:SetPoint("RIGHT", -4, 0)
        r.remove:SetScript("OnClick", function(s) cfg.onRemove(s:GetParent().itemID) end)
        r.remove:HookScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:AddLine(ns.L("MENU_REMOVE_ITEM"), 1, 1, 1)
            GameTooltip:Show()
        end)
        r.remove:HookScript("OnLeave", GameTooltip_Hide)

        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.name:SetPoint("RIGHT", r.remove, "LEFT", -6, 0)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)

        r:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(s.itemID)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", GameTooltip_Hide)
        return r
    end

    -- catID nil : rien à lister.
    function L.Set(catID)
        if catID then cfg.getItems(catID, ids) else wipe(ids) end
        local pending = false
        for i = 1, #ids do
            local r = rows[i]
            if not r then
                r = CreateRow()
                rows[i] = r
            end
            r.itemID = ids[i]
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * STEP)
            r:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * STEP)
            r.icon:SetTexture(C_Item.GetItemIconByID(ids[i]))
            FillName(r)
            pending = pending or r.pending
            r:Show()
        end
        for i = #ids + 1, #rows do rows[i]:Hide() end
        content:SetHeight(math.max(1, #ids * STEP))
        empty:SetShown(catID ~= nil and #ids == 0)
        Listen(pending)
    end

    return L
end
