local addonName, ns = ...

-- Type de bouton des onglets du coffre de guilde (conteneurs virtuels).
-- Gabarit Blizzard (chargé avec le coffre). Tout passe par (onglet, emplacement) explicites : l'onglet courant de Blizzard
-- n'est pas utilisé. Comportement identique à GuildBankItemButtonMixin.

local function Link(self)
    return GetGuildBankItemLink(self.tab, self.slot)
end

local function OnClick(self, button)
    if HandleModifiedItemClick(Link(self)) then return end
    if IsModifiedClick("SPLITSTACK") then
        if not CursorHasItem() then
            local _, count, locked = GetGuildBankItemInfo(self.tab, self.slot)
            if not locked and count and count > 1 then
                StackSplitFrame:OpenStackSplitFrame(count, self, "BOTTOMLEFT", "TOPLEFT")
            end
        end
        return
    end
    local kind, money = GetCursorInfo()
    if kind == "money" then
        DepositGuildBankMoney(money)
        ClearCursor()
    elseif kind == "guildbankmoney" then
        DropCursorMoney()
        ClearCursor()
    elseif button == "RightButton" then
        AutoStoreGuildBankItem(self.tab, self.slot)
        self:GetScript("OnLeave")(self)
    else
        PickupGuildBankItem(self.tab, self.slot)
    end
end

local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetGuildBankItem(self.tab, self.slot)
end

local function OnLeave()
    GameTooltip_Hide()
    ResetCursor()
end

local function Pickup(self)
    PickupGuildBankItem(self.tab, self.slot)
end

ns.UI.RegisterButtonKind({
    matches = function(bag) return bag > ns.VBAG_BASE end,
    create = function(parent, bag, slot)
        local btn = CreateFrame("ItemButton", nil, parent, "GuildBankItemButtonTemplate")
        btn.tab, btn.slot = bag - ns.VBAG_BASE, slot
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:RegisterForDrag("LeftButton")
        btn.SplitStack = function(self, split)
            SplitGuildBankItem(self.tab, self.slot, split)
        end
        btn.UpdateTooltip = OnEnter
        btn:SetScript("OnClick", OnClick)
        btn:SetScript("OnEnter", OnEnter)
        btn:SetScript("OnLeave", OnLeave)
        btn:SetScript("OnDragStart", Pickup)
        btn:SetScript("OnReceiveDrag", Pickup)
        btn:SetScript("OnHide", function(self)
            if self.hasStackSplit == 1 then StackSplitFrame:Hide() end
        end)
        return btn
    end,
})
