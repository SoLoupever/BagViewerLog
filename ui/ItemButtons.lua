local addonName, ns = ...

-- Pools de boutons d'objet : template Blizzard ContainerFrameItemButtonTemplate
-- (clic, glisser, infobulle, utilisation). Un bouton = un (conteneur, emplacement),
-- créé une fois puis réutilisé. Le parent porte le bagID.
-- Une instance par cadre (sac, banque) : ns.UI.NewItemButtons().

local SetItemButtonQuality, SetItemButtonCount = SetItemButtonQuality, SetItemButtonCount

function ns.UI.NewItemButtons()
    local IB = {}

    local container
    local bagParents = {}   -- bagID -> frame (ID = bagID)
    local buttons    = {}   -- bagID -> { [slot] = button }
    local active     = {}

    function IB.SetContainer(frame)
        container = frame
    end

    local function GetBagParent(bag)
        local p = bagParents[bag]
        if not p then
            p = CreateFrame("Frame", nil, container)
            p:SetAllPoints(container)
            p:SetID(bag)
            bagParents[bag] = p
        end
        return p
    end

    function IB.Acquire(bag, slot)
        local perBag = buttons[bag]
        if not perBag then
            perBag = {}
            buttons[bag] = perBag
        end
        local btn = perBag[slot]
        if not btn then
            btn = CreateFrame("ItemButton", nil, GetBagParent(bag), "ContainerFrameItemButtonTemplate")
            btn:SetBagID(bag)
            btn:SetID(slot)
            -- Visible par défaut dans le template ; Blizzard la masque lui-même.
            btn.BattlepayItemTexture:Hide()
            btn.NewItemTexture:Hide()
            perBag[slot] = btn
        end
        btn:Show()
        active[#active + 1] = btn
        return btn
    end

    function IB.ReleaseAll()
        for i = #active, 1, -1 do
            active[i]:Hide()
            active[i].entry = nil
            active[i] = nil
        end
    end

    -- entry = objet du snapshot (icon, count, link, quality, name) ou emplacement vide.
    function IB.Set(btn, entry)
        btn.entry = entry
        if btn.freeCount then btn.freeCount:Hide() end
        ClearItemButtonOverlay(btn)
        btn:SetHasItem(entry.icon)
        btn:SetItemButtonTexture(entry.icon)
        SetItemButtonQuality(btn, entry.quality, entry.link)
        SetItemButtonCount(btn, entry.count)
        btn:UpdateCooldown(entry.icon)
        btn:SetMatchesSearch(ns.Search.Matches(entry))
        ns.UI.ApplyBadges(btn, entry)
    end

    -- Bouton d'un emplacement libre : sert de cible de dépôt, le nombre de libres
    -- est écrit dans l'icône.
    function IB.SetFree(btn, entry, numFree)
        btn.entry = entry
        ClearItemButtonOverlay(btn)
        btn:SetHasItem(nil)
        btn:SetItemButtonTexture(nil)
        SetItemButtonCount(btn, 0)
        btn:SetMatchesSearch(true)
        ns.UI.HideBadges(btn)
        if not btn.freeCount then
            btn.freeCount = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            btn.freeCount:SetPoint("CENTER", 0, 0)
        end
        btn.freeCount:SetText(numFree)
        btn.freeCount:Show()
    end

    ns.On("SEARCH_CHANGED", function()
        for i = 1, #active do
            local btn = active[i]
            if btn.entry then btn:SetMatchesSearch(ns.Search.Matches(btn.entry)) end
        end
    end)

    local cdFrame = CreateFrame("Frame")
    cdFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    cdFrame:SetScript("OnEvent", function()
        for i = 1, #active do
            local btn = active[i]
            if btn.entry then btn:UpdateCooldown(btn.entry.icon) end
        end
    end)

    return IB
end

ns.UI.ItemButtons = ns.UI.NewItemButtons()
