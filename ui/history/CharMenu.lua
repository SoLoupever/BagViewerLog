local addonName, ns = ...

-- Menu de choix du personnage (menu Blizzard). HISTORY_PICK_CHAR(ancre, vue) :
-- le choix devient le personnage consulté ; si une vue est donnée, la fenêtre
-- d'historique s'ouvre dessus.

local ROW_H, MAX_ROWS = 20, 14

ns.On("HISTORY_PICK_CHAR", function(anchor, openView)
    MenuUtil.CreateContextMenu(anchor, function(_, root)
        root:SetScrollMode(ROW_H * MAX_ROWS)
        local curName, curRealm = ns.History.GetChar()
        local lastRealm
        for _, c in ipairs(ns.History.GetChars()) do
            if c.realm ~= lastRealm then
                lastRealm = c.realm
                root:CreateTitle(c.realm)
            end
            local color = RAID_CLASS_COLORS[c.class]
            root:CreateRadio(color and color:WrapTextInColorCode(c.name) or c.name,
                function(d) return d.name == curName and d.realm == curRealm end,
                function(d)
                    ns.History.SetChar(d.name, d.realm)
                    if openView then ns.Fire("HISTORY_OPEN", openView) end
                end, c)
        end
    end)
end)
