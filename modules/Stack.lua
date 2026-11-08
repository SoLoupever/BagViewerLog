local addonName, ns = ...

-- Armes / armures identiques (même lien) : un seul bouton, le nombre de
-- copies est affiché dans le compteur de l'objet.

local CLASSES = {
    [Enum.ItemClass.Weapon] = true,
    [Enum.ItemClass.Armor]  = true,
}

local MAX_CACHE = 512
local keyOf, size = {}, 0   -- lien -> clé d'objet

local function Key(link)
    local k = keyOf[link]
    if not k then
        k = link:match("item:[^|]+") or link
        if size >= MAX_CACHE then
            wipe(keyOf)
            size = 0
        end
        keyOf[link] = k
        size = size + 1
    end
    return k
end

local function Merge(list)
    local seen, w = {}, 0
    local n = #list
    for r = 1, n do
        local item = list[r]
        local first
        if item.link and CLASSES[item.classID] then
            local k = Key(item.link)
            first = seen[k]
            if first then
                first.count = (first.count or 1) + (item.count or 1)
            else
                seen[k] = item
            end
        end
        if not first then
            w = w + 1
            list[w] = item
        end
    end
    for i = n, w + 1, -1 do list[i] = nil end
end

ns.On("INVENTORY_GROUPED", function(groups)
    if not ns.View.Allows("stack") then return end
    for _, list in pairs(groups) do Merge(list) end
end)
