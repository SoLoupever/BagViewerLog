local addonName, ns = ...

-- Recherche par nom. Ne touche pas à l'UI : notifie via SEARCH_CHANGED.

local query = ""

ns.Search = {}

function ns.Search.Set(text)
    text = (text or ""):lower()
    if text == query then return end
    query = text
    ns.Fire("SEARCH_CHANGED", query)
end

function ns.Search.Clear()
    ns.Search.Set("")
end

-- Emplacement vide ou recherche vide : toujours visible.
function ns.Search.Matches(entry)
    if query == "" or not entry.name then return true end
    return entry.name:lower():find(query, 1, true) ~= nil
end
