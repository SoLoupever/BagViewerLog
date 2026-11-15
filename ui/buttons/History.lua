local addonName, ns = ...

-- Type de bouton des conteneurs de l'historique ViewerLog : lecture seule,
-- infobulle et clic modifié (lien, aperçu) uniquement.

local function OnEnter(self)
    local e = self.entry
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if e.link then GameTooltip:SetHyperlink(e.link) else GameTooltip:SetItemByID(e.id) end
    GameTooltip:Show()
end

local function OnClick(self)
    local e = self.entry
    if e and e.link then HandleModifiedItemClick(e.link) end
end

ns.UI.RegisterButtonKind({
    matches = function(bag) return bag >= ns.HBAG_BASE end,
    create = function(parent)
        local btn = CreateFrame("ItemButton", nil, parent)
        btn:RegisterForClicks("LeftButtonUp")
        btn:SetScript("OnClick", OnClick)
        btn:SetScript("OnEnter", OnEnter)
        btn:SetScript("OnLeave", GameTooltip_Hide)
        return btn
    end,
})
