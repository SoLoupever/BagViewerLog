local addonName, ns = ...

-- Disposition par catégories partagée (sac, banque) : en-têtes, grilles,
-- emplacements "+" et icône unique des emplacements libres.
-- Une instance par cadre : ns.UI.NewCategoryGrid(cfg).
-- cfg = { content, IB, Sections, cols, prefix (clé des repliés), refresh }.

local SLOT, GAP = 37, 4
local SECTION_H, SECTION_GAP = 18, 10
local SUB_INDENT = 14

local EMPTY = {}

function ns.UI.NewCategoryGrid(cfg)
    local G = {}
    local content, IB, Sections = cfg.content, cfg.IB, cfg.Sections
    local COLS = cfg.cols

    local function Toggle(key)
        local collapsed = ns.Settings.Table("collapsed")
        collapsed[key] = (not collapsed[key]) or nil
        cfg.refresh()
    end

    -- snap = { groups, free }. opts = { holding, showCustom, pickFree(free) }.
    -- Renvoie la hauteur utilisée.
    function G.Render(snap, opts)
        IB.ReleaseAll()
        Sections.Reset()

        local collapsed = ns.Settings.Table("collapsed")
        local holding = opts.holding
        local y = 0

        -- Grille des objets de la catégorie, plus un "+" si on tient un objet.
        local function Grid(list, def, indent)
            local cols = indent > 0 and COLS - 1 or COLS
            local total = #list + ((holding and not def.noAssign) and 1 or 0)
            for i = 1, total do
                local x = indent + ((i - 1) % cols) * (SLOT + GAP)
                local py = -(y + math.floor((i - 1) / cols) * (SLOT + GAP))
                local widget
                if i <= #list then
                    local entry = list[i]
                    widget = IB.Acquire(entry.bag, entry.slot)
                    IB.Set(widget, entry)
                else
                    widget = ns.UI.PlusSlots.Acquire(content, def.id)
                end
                widget:ClearAllPoints()
                widget:SetPoint("TOPLEFT", content, "TOPLEFT", x, py)
            end
            if total > 0 then
                y = y + math.ceil(total / cols) * (SLOT + GAP) - GAP + 6
            end
        end

        -- true si la catégorie est repliée.
        local function Header(id, label, count, indent)
            local key = cfg.prefix .. id
            local isCollapsed = collapsed[key]
            Sections.Acquire(content, y, key, label, count, isCollapsed, Toggle, indent)
            y = y + SECTION_H + 6
            return isCollapsed
        end

        local function Visible(def, count)
            return count > 0 or (def.custom and opts.showCustom) or (holding and not def.noAssign)
        end

        for _, def in ipairs(ns.GetTopCategories()) do
            local direct = snap.groups[def.id] or EMPTY
            local kids = ns.GetChildren(def.id)
            local total = #direct
            for _, kid in ipairs(kids) do
                total = total + #(snap.groups[kid.id] or EMPTY)
            end

            if Visible(def, total) then
                if not Header(def.id, ns.GetCategoryLabel(def), total, 0) then
                    Grid(direct, def, 0)
                    for _, kid in ipairs(kids) do
                        local list = snap.groups[kid.id] or EMPTY
                        if Visible(kid, #list)
                           and not Header(kid.id, ns.GetCategoryLabel(kid), #list, SUB_INDENT) then
                            Grid(list, kid, SUB_INDENT)
                        end
                    end
                end
                y = y + SECTION_GAP
            end
        end

        -- Emplacements libres : une seule icône.
        local free = snap.free
        if #free > 0 then
            local target = opts.pickFree and opts.pickFree(free) or free[1]
            if not Header("free", ns.L("CAT_FREE"), #free, 0) then
                local btn = IB.Acquire(target.bag, target.slot)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
                IB.SetFree(btn, target, #free)
                y = y + SLOT + 6
            end
            y = y + SECTION_GAP
        end

        return math.max(y - SECTION_GAP, 1)
    end

    return G
end
