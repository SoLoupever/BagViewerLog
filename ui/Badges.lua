local addonName, ns = ...

-- Registre de pastilles de texte sur les boutons d'objet (niveau d'objet, clé...).
-- def = { id, point, offsetX, offsetY, font,
--         get = function(entry) -> texte|nil, r, g, b }.
-- Une FontString par pastille et par bouton, créée à la demande.

local defs = {}

function ns.UI.RegisterBadge(def)
    defs[#defs + 1] = def
end

function ns.UI.ApplyBadges(btn, entry)
    local fsList = btn.badges
    for i = 1, #defs do
        local d = defs[i]
        local text, r, g, b = d.get(entry)
        local fs = fsList and fsList[d.id]
        if text then
            if not fs then
                fsList = fsList or {}
                btn.badges = fsList
                fs = btn:CreateFontString(nil, "OVERLAY", d.font or "NumberFontNormal")
                fs:SetPoint(d.point, d.offsetX or 0, d.offsetY or 0)
                fsList[d.id] = fs
            end
            fs:SetTextColor(r or 1, g or 1, b or 1)
            fs:SetText(text)
            fs:Show()
        elseif fs then
            fs:Hide()
        end
    end
end

function ns.UI.HideBadges(btn)
    if not btn.badges then return end
    for _, fs in pairs(btn.badges) do fs:Hide() end
end
