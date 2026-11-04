local addonName, ns = ...

-- Remplace le sac Blizzard sans toucher à ses fonctions : Blizzard ouvre ses
-- cadres, on les masque aussitôt et on affiche le nôtre.
-- Ouvrir : événement "ContainerFrame.OpenBag". Basculer : post-hooks des
-- Toggle*. Fermer : post-hooks des Close*.

local Frame = ns.UI.Frame

-- true quand l'ouverture vient d'avoir lieu pendant l'appel Toggle* en cours.
local openedThisCall = false

local function HideBlizzardFrame(f)
    if not f or not f.Hide then return end
    f:SetAlpha(0)
    -- Différé : on ne masque pas un cadre au milieu de son propre OnShow.
    C_Timer.After(0, function()
        f:Hide()
        f:SetAlpha(1)
    end)
end

EventRegistry:RegisterCallback("ContainerFrame.OpenBag", function(_, blizzFrame)
    HideBlizzardFrame(blizzFrame)
    if not Frame.IsShown() then
        openedThisCall = true
        Frame.Show()
    end
end, ns)

-- Blizzard ne voit jamais de sac ouvert : un Toggle rouvre donc toujours côté
-- Blizzard. Si notre cadre était déjà ouvert, c'est une demande de fermeture.
local function AfterToggle()
    if not openedThisCall then Frame.Hide() end
    openedThisCall = false
end

hooksecurefunc("ToggleAllBags", AfterToggle)
hooksecurefunc("ToggleBackpack", AfterToggle)
hooksecurefunc("ToggleBag", AfterToggle)

hooksecurefunc("CloseAllBags", function() Frame.Hide() end)
hooksecurefunc("CloseBackpack", function() Frame.Hide() end)
