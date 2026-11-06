local addonName, ns = ...

-- Recherche par nom. Ne touche pas à l'UI : notifie via SEARCH_CHANGED.

local query = ""
local lowered = {}   -- lien -> nom en minuscules, ou false ; vidé hors recherche

ns.Search = {}

function ns.Search.Set(text)
    text = (text or ""):lower()
    if text == query then return end
    query = text
    if text == "" then wipe(lowered) end
    ns.Fire("SEARCH_CHANGED", query)
end

function ns.Search.Clear()
    ns.Search.Set("")
end

-- Emplacement vide ou recherche vide : toujours visible.
function ns.Search.Matches(entry)
    local link = entry.link
    if query == "" or not link then return true end
    local name = lowered[link]
    if name == nil then
        local n = link:match("%[(.-)%]")
        name = n and n:lower() or false
        lowered[link] = name
    end
    if not name then return true end
    return name:find(query, 1, true) ~= nil
end
