local addonName, ns = ...

-- Namespace, accès à l'API ViewerLog, traduction et bus d'événements interne.

ns.vl      = _G.ViewerLogAPI
ns.locales = {}
ns.UI      = {}

-- ── Traduction ────────────────────────────────────────────────────
-- Même source de langue que ViewerLog, repli enUS.
function ns.L(key)
    local lang = (_G.AltViewerLogDB and _G.AltViewerLogDB.settings
                  and _G.AltViewerLogDB.settings.lang)
                 or GetLocale()
    local t = ns.locales[lang] or ns.locales["enUS"]
    return t[key] or ns.locales["enUS"][key] or ("[BVL:" .. key .. "]")
end

-- ── Bus d'événements ──────────────────────────────────────────────
-- Les modules se parlent uniquement par ici : ns.On / ns.Fire.
local handlers = {}

function ns.On(event, fn)
    local list = handlers[event]
    if not list then
        list = {}
        handlers[event] = list
    end
    list[#list + 1] = fn
end

function ns.Fire(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then geterrorhandler()(err) end
    end
end
