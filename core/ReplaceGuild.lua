local addonName, ns = ...

-- Remplace l'affichage du coffre de guilde Blizzard (chargé à la demande). Comme
-- pour la banque, GuildBankFrame reste "affiché" (son OnHide ferme l'interaction) :
-- on le rend invisible et minuscule. Le bouton « cadre Blizzard » le rend visible
-- (journal, infos, achat d'onglet) ; le bouton « retour » revient à notre vue.

local native = false   -- cadre Blizzard demandé
local hooked = false

local function Conceal(gb)
    gb:SetAlpha(0)
    gb:SetScale(0.001)
end

local function Reveal(gb)
    gb:SetAlpha(1)
    gb:SetScale(1)
end

local function Hook(gb)
    hooked = true

    gb:HookScript("OnShow", function(self)
        if native then return end
        Conceal(self)
        ns.UI.Guild.Show()
    end)

    gb:HookScript("OnHide", function(self)
        native = false
        Reveal(self)
        ns.UI.Guild.Hide()
    end)

    ns.UI.GuildReturn.Attach(gb, function()
        native = false
        Conceal(gb)
        ns.UI.Guild.Show()
    end)

    ns.On("GUILD_BLIZZARD_REQUESTED", function()
        native = true
        Reveal(gb)
        ns.UI.Guild.Hide(true)
    end)
end

local function TryHook()
    local gb = _G.GuildBankFrame
    if hooked or not gb then return end
    Hook(gb)
end

TryHook()
if not hooked then
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self)
        TryHook()
        if hooked then self:UnregisterAllEvents() end
    end)
end
