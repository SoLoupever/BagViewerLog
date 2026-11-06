local addonName, ns = ...

-- Arme / armure d'une extension antérieure à celle du niveau du perso = camelote.
-- Niveau 80 -> objets TWW conservés, niveau 70 -> Dragonflight, etc.
-- Hors règle : invendables (hasNoValue), artefacts, héritages, objets d'ensemble
-- d'équipement (priorité).

local GetItemInfo = C_Item.GetItemInfo
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local EXPANSION_INDEX = 15   -- expansionID dans les retours de GetItemInfo

local CLASSES = {
    [Enum.ItemClass.Weapon] = true,
    [Enum.ItemClass.Armor]  = true,
}

local minExpansion          -- nil = à recalculer
local known   = {}          -- itemID -> expansionID
local pending = {}          -- itemID -> true (données demandées au client)
local answered = {}         -- itemID -> true (le client a déjà répondu)
local NO_INFO = math.huge   -- données introuvables : jamais camelote
local refreshQueued = false
local noValue = {}          -- itemID -> true si le marchand ne le rachète pas

local frame = CreateFrame("Frame")
local listening = false

-- GET_ITEM_INFO_RECEIVED est très bavard : écouté seulement si on attend une réponse.
local function Listen(on)
    if on == listening then return end
    listening = on
    if on then frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    else frame:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end
end

local function MinExpansion()
    if not minExpansion then
        minExpansion = GetExpansionForLevel(UnitLevel("player"))
    end
    return minExpansion
end

local function Expansion(id)
    local k = known[id]
    if not k then
        k = select(EXPANSION_INDEX, GetItemInfo(id))
        if k then
            known[id] = k
        elseif answered[id] then
            k = NO_INFO
            known[id] = k
        else
            pending[id] = true
            Listen(true)
        end
    end
    return k
end

-- Invendable côté marchand (hasNoValue), lu une fois par objet.
local function Unsellable(item)
    local v = noValue[item.id]
    if v == nil then
        local info = GetContainerItemInfo(item.bag, item.slot)
        if not info then return false end
        v = info.hasNoValue or false
        noValue[item.id] = v
    end
    return v
end

ns.RegisterRule({
    category = "junk", priority = 58,
    match = function(item)
        local q = item.quality
        if not CLASSES[item.classID] or q == Enum.ItemQuality.Heirloom or q == Enum.ItemQuality.Artifact then
            return false
        end
        local min = MinExpansion()
        if not min then return false end
        local e = Expansion(item.id)
        return e ~= nil and e < min and not Unsellable(item)
    end,
})

frame:RegisterEvent("PLAYER_LEVEL_UP")

-- Un seul rafraîchissement pour toutes les réponses d'une même rafale.
local function QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0.3, function()
        refreshQueued = false
        ns.Fire("CATEGORIES_CHANGED")
    end)
end

frame:SetScript("OnEvent", function(_, event, arg)
    if event == "PLAYER_LEVEL_UP" then
        minExpansion = GetExpansionForLevel(arg)
        ns.Fire("CATEGORIES_CHANGED")
    elseif pending[arg] then
        pending[arg] = nil
        answered[arg] = true
        if next(pending) == nil then Listen(false) end
        QueueRefresh()
    end
end)
