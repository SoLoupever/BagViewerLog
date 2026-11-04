local addonName, ns = ...

-- Registre de widgets du cadre. Chaque widget s'enregistre dans une zone ;
-- Frame.lua les place sans les connaître.
-- def = { id, area = "title"|"toolbar"|"footer", side = "left"|"right",
--         order, flex (remplit l'espace libre, dernier de "left"),
--         build = function(parent) -> frame }.

local widgets = {}

function ns.UI.RegisterWidget(def)
    widgets[#widgets + 1] = def
end

function ns.UI.GetWidgets(area, side)
    local list = {}
    for i = 1, #widgets do
        local d = widgets[i]
        if d.area == area and d.side == side then list[#list + 1] = d end
    end
    table.sort(list, function(a, b) return a.order < b.order end)
    return list
end
