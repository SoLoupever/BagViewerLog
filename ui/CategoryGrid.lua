local addonName, ns = ...

-- Disposition par catégories partagée (sac, banque).
-- Sans sous-catégorie : bloc (libellé + grille) placé à côté des autres blocs.
-- Avec sous-catégories : en-tête repliable (flèche), puis ses sous-catégories en
-- blocs. Les blocs sont répartis en rangées de hauteur minimale (Pack).
-- Une instance par cadre : ns.UI.NewCategoryGrid(cfg).
-- cfg = { content, IB, Sections, cols, prefix (clé des repliés), refresh,
--         usePlus (emplacements "+") }.

local SLOT, GAP = 37, 4
local CELL = SLOT + GAP
local SECTION_H, SECTION_GAP = 18, 10
local LABEL_H = SECTION_H + 6
local GROUP_GAP = 14      -- espace entre deux blocs d'une même rangée
local MIN_COLS = 3        -- colonnes minimales d'un bloc réduit
local LABEL_MAX_W = 64    -- au-delà, le libellé est tronqué

local EMPTY = {}
local INF = math.huge
local FREE_DEF = { id = "free", noAssign = true }

function ns.UI.NewCategoryGrid(cfg)
    local G = {}
    local content, IB, Sections = cfg.content, cfg.IB, cfg.Sections
    local COLS = cfg.cols
    local MAX_W = COLS * CELL - GAP

    local function Toggle(key)
        local collapsed = ns.Settings.Table("collapsed")
        collapsed[key] = (not collapsed[key]) or nil
        cfg.refresh()
    end

    -- ── Répartition en rangées ────────────────────────────────────
    local function BlockWidth(b, cols)
        return math.max(cols * CELL - GAP, b.lw)
    end

    -- Colonnes de chaque bloc i..j pour au plus R rangées d'icônes, ou nil si
    -- la rangée dépasse la largeur.
    local function FitRow(blocks, i, j, R)
        local cols, w = {}, GROUP_GAP * (j - i)
        for k = i, j do
            local b = blocks[k]
            local c = math.max(b.lo, math.ceil(b.count / R))
            if c > b.hi then return nil end
            w = w + BlockWidth(b, c)
            if w > MAX_W then return nil end
            cols[k] = c
        end
        return cols
    end

    -- Plus petite hauteur possible pour la rangée i..j : cols, hauteur.
    local function BestRow(blocks, i, j)
        local maxR = 1
        for k = i, j do
            local b = blocks[k]
            maxR = math.max(maxR, math.ceil(b.count / b.lo))
        end
        for R = 1, maxR do
            local cols = FitRow(blocks, i, j, R)
            if cols then
                local rows = 0
                for k = i, j do
                    rows = math.max(rows, math.ceil(blocks[k].count / cols[k]))
                end
                return cols, LABEL_H + (rows > 0 and rows * CELL - GAP + 6 or 0)
            end
        end
        return nil, INF
    end

    -- Découpe les blocs (dans l'ordre) en rangées de hauteur totale minimale.
    local function Pack(blocks)
        local n = #blocks
        local best, from, colsOf, hOf = { [0] = 0 }, {}, {}, {}
        for j = 1, n do
            best[j] = INF
            for i = j, 1, -1 do
                local cols, h = BestRow(blocks, i, j)
                if not cols then break end
                local cost = best[i - 1] + h + 0.001
                if cost < best[j] then
                    best[j], from[j], colsOf[j], hOf[j] = cost, i, cols, h
                end
            end
        end
        local rows, j = {}, n
        while j > 0 do
            local i = from[j]
            table.insert(rows, 1, { i = i, j = j, cols = colsOf[j], h = hOf[j] })
            j = i - 1
        end
        return rows
    end

    -- ── Rendu ─────────────────────────────────────────────────────
    -- snap = { groups, free }. opts = { holding, showCustom, pickFree(free) }.
    -- Renvoie la hauteur utilisée.
    function G.Render(snap, opts)
        IB.ReleaseAll()
        Sections.Reset()
        if cfg.usePlus then ns.UI.PlusSlots.Reset() end

        local collapsed = ns.Settings.Table("collapsed")
        local holding = cfg.usePlus and opts.holding
        local y = 0

        local function Count(list, def)
            return #list + ((holding and not def.noAssign) and 1 or 0)
        end

        -- Grille des objets (x0, y0 : coin haut-gauche ; cols colonnes), plus un
        -- "+" si on tient un objet. Renvoie la hauteur utilisée.
        local function Grid(list, def, x0, y0, cols)
            local total = Count(list, def)
            for i = 1, total do
                local x = x0 + ((i - 1) % cols) * CELL
                local py = -(y0 + math.floor((i - 1) / cols) * CELL)
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
            if total == 0 then return 0 end
            return math.ceil(total / cols) * CELL - GAP + 6
        end

        local function PlaceItems(b, x0, y0, cols)
            if b.free then
                local btn = IB.Acquire(b.free.bag, b.free.slot)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", content, "TOPLEFT", x0, -y0)
                IB.SetFree(btn, b.free, b.numFree)
                return SLOT + 6
            end
            return Grid(b.list, b.def, x0, y0, cols)
        end

        local function NewBlock(def, list, text)
            return { def = def, list = list, text = text, count = Count(list, def) }
        end

        -- Blocs côte à côte, en rangées compactes. Renvoie la hauteur utilisée.
        local function Flow(blocks)
            for _, b in ipairs(blocks) do
                b.label = Sections.AcquireLabel(content, b.text)
                b.lw = math.min(b.label.textW, LABEL_MAX_W)
                b.hi = math.min(COLS, math.max(b.count, 1))
                b.lo = math.min(b.hi, MIN_COLS)
            end

            local top = y
            for _, r in ipairs(Pack(blocks)) do
                local x = 0
                for k = r.i, r.j do
                    local b = blocks[k]
                    local w = BlockWidth(b, r.cols[k])
                    b.label:SetPoint("TOPLEFT", content, "TOPLEFT", x, -top)
                    Sections.SetLabelWidth(b.label, w)
                    PlaceItems(b, x, top + LABEL_H, r.cols[k])
                    x = x + w + GROUP_GAP
                end
                top = top + r.h
            end
            return top - y
        end

        -- true si la catégorie est repliée.
        local function Header(id, label, count)
            local key = cfg.prefix .. id
            local isCollapsed = collapsed[key]
            Sections.Acquire(content, y, key, label, count, isCollapsed, Toggle)
            y = y + SECTION_H + 6
            return isCollapsed
        end

        local function Visible(def, count)
            return count > 0 or (def.custom and opts.showCustom) or (holding and not def.noAssign)
        end

        local run = {}   -- blocs consécutifs sans sous-catégorie
        local function Flush()
            if #run == 0 then return end
            y = y + Flow(run) + SECTION_GAP
            run = {}
        end

        for _, def in ipairs(ns.GetTopCategories()) do
            local direct = snap.groups[def.id] or EMPTY
            local kids = ns.GetChildren(def.id)
            local total = #direct
            for _, kid in ipairs(kids) do
                total = total + #(snap.groups[kid.id] or EMPTY)
            end

            if Visible(def, total) then
                if #kids == 0 then
                    run[#run + 1] = NewBlock(def, direct, ns.GetCategoryLabel(def))
                else
                    Flush()
                    if not Header(def.id, ns.GetCategoryLabel(def), total) then
                        y = y + Grid(direct, def, 0, y, COLS)
                        local blocks = {}
                        for _, kid in ipairs(kids) do
                            local list = snap.groups[kid.id] or EMPTY
                            if Visible(kid, #list) then
                                blocks[#blocks + 1] = NewBlock(kid, list, ns.GetCategoryLabel(kid))
                            end
                        end
                        y = y + Flow(blocks)
                    end
                    y = y + SECTION_GAP
                end
            end
        end

        -- Emplacements libres : bloc d'une seule icône, avec les derniers blocs.
        local free = snap.free
        if #free > 0 then
            local target = opts.pickFree and opts.pickFree(free) or free[1]
            local b = NewBlock(FREE_DEF, EMPTY, ns.L("CAT_FREE"))
            b.count, b.free, b.numFree = 1, target, #free
            run[#run + 1] = b
        end
        Flush()

        return math.max(y - SECTION_GAP, 1)
    end

    return G
end
