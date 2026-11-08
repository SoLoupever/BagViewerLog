local addonName, ns = ...

-- Disposition par catégories partagée (sac, banque).
-- Sans sous-catégorie : bloc (libellé + grille) placé à côté des autres blocs.
-- Avec sous-catégories : en-tête repliable (flèche), puis ses sous-catégories en
-- blocs. Les blocs sont répartis en rangées de hauteur minimale (Pack).
-- Une instance par cadre : ns.UI.NewCategoryGrid(cfg).
-- cfg = { content, IB, Sections, cols, prefix (clé des repliés), refresh,
--         usePlus (emplacements "+"), context (clic droit sur une catégorie) }.
-- Clic droit : publie CATEGORY_CONTEXT(def, entrées) et, au survol,
-- CATEGORY_CONTEXT_TIP(infobulle, def). Pas pour une catégorie repliée, noBulk,
-- ni une vue qui refuse "bulk" ; les sous-catégories noBulk sont exclues.
-- Dimensions : profil ns.UI.GetMetrics, changé par G.SetMetrics(m). Sans appel,
-- profil standard avec cfg.cols colonnes.
-- G.Render renvoie la hauteur et la largeur utilisées (le cadre s'y adapte).
-- Emplacements libres : un seul bloc en bas, une icône par type de sac.

local EMPTY = {}
local INF = math.huge
local FREE_DEF = { id = "free", noAssign = true, noBulk = true }
local function NoKids() return EMPTY end

function ns.UI.NewCategoryGrid(cfg)
    local G = {}
    local content, IB, Sections = cfg.content, cfg.IB, cfg.Sections
    local Plus = cfg.usePlus and ns.UI.NewPlusSlots()

    -- Dimensions du profil courant.
    local COLS, SLOT, GAP, CELL, MAX_W
    local SECTION_H, SECTION_GAP, LABEL_H, GROUP_GAP
    local BLOCK_TAIL, HEAD_TAIL, MIN_COLS, LABEL_MAX_W

    -- État du rendu en cours.
    local collapsed, holding, showCustom, pickFree, bulk
    local y, usedW = 0, 0
    local headCtx, nHead = {}, 0  -- ctx des en-têtes : { def, list, kids, groups }
    local gathered = {}           -- entrées rassemblées au clic droit
    local freeSlots = { {}, {} }  -- { slot, num, reagent } réutilisés
    local run, nRun = {}, 0       -- blocs consécutifs sans sous-catégorie
    local sub, nSub = {}, 0       -- blocs des sous-catégories
    local blockPool, nBlock = {}, 0
    local packCache, flowIdx = {}, 0
    local tmp = {}                -- colonnes candidates (FitRow)

    local function Apply(m, cols)
        COLS, SLOT, GAP = cols or m.cols, m.slot, m.gap
        CELL = SLOT + GAP
        MAX_W = COLS * CELL - GAP
        SECTION_H, SECTION_GAP, GROUP_GAP = m.sectionH, m.sectionGap, m.groupGap
        LABEL_H = SECTION_H + m.labelPad
        BLOCK_TAIL, HEAD_TAIL = m.blockTail, m.headerTail
        MIN_COLS, LABEL_MAX_W = m.minCols, m.labelMaxW
        wipe(packCache)   -- la répartition dépend des dimensions
        IB.SetSlotSize(SLOT)
        Sections.SetHeight(SECTION_H)
        if Plus then Plus.SetSize(SLOT) end
    end

    function G.SetMetrics(m)
        Apply(m)
    end

    local function Toggle(key)
        local c = ns.Settings.Table("collapsed")
        c[key] = (not c[key]) or nil
        cfg.refresh()
    end

    -- ── Clic droit ────────────────────────────────────────────────
    -- ctx = bloc (def, list) ou ctx d'en-tête (def, list, kids, groups).
    local function ContextClick(ctx)
        wipe(gathered)
        local list = ctx.list
        for i = 1, #list do gathered[#gathered + 1] = list[i] end
        if ctx.kids then
            for _, kid in ipairs(ctx.kids) do
                if not kid.noBulk then
                    local kl = ctx.groups[kid.id] or EMPTY
                    for i = 1, #kl do gathered[#gathered + 1] = kl[i] end
                end
            end
        end
        ns.Fire("CATEGORY_CONTEXT", ctx.def, gathered)
    end

    local function ContextTip(owner, ctx)
        GameTooltip:SetOwner(owner, "ANCHOR_TOP")
        ns.Fire("CATEGORY_CONTEXT_TIP", GameTooltip, ctx.def)
        if GameTooltip:NumLines() > 0 then GameTooltip:Show() else GameTooltip:Hide() end
    end

    if cfg.context then Sections.SetContext(ContextClick, ContextTip) end

    -- ── Répartition en rangées ────────────────────────────────────
    local function BlockWidth(b, cols)
        return math.max(cols * CELL - GAP, b.lw)
    end

    -- Colonnes de chaque bloc i..j (dans tmp) pour au plus R rangées d'icônes ;
    -- false si la rangée dépasse la largeur.
    local function FitRow(blocks, i, j, R)
        local w = GROUP_GAP * (j - i)
        for k = i, j do
            local b = blocks[k]
            local c = math.max(b.lo, math.ceil(b.count / R))
            if c > b.hi then return false end
            w = w + BlockWidth(b, c)
            if w > MAX_W then return false end
            tmp[k] = c
        end
        return true
    end

    -- Plus petite hauteur possible pour la rangée i..j (colonnes dans tmp).
    local function BestRow(blocks, i, j)
        local maxR = 1
        for k = i, j do
            local b = blocks[k]
            maxR = math.max(maxR, math.ceil(b.count / b.lo))
        end
        for R = 1, maxR do
            if FitRow(blocks, i, j, R) then
                local rows = 0
                for k = i, j do
                    rows = math.max(rows, math.ceil(blocks[k].count / tmp[k]))
                end
                return LABEL_H + (rows > 0 and rows * CELL - GAP + BLOCK_TAIL or 0)
            end
        end
        return INF
    end

    -- Découpe les blocs (dans l'ordre) en rangées de hauteur totale minimale.
    local function Compute(blocks, n)
        local best, from, colsOf, hOf = { [0] = 0 }, {}, {}, {}
        for j = 1, n do
            best[j] = INF
            for i = j, 1, -1 do
                local h = BestRow(blocks, i, j)
                if h == INF then break end
                local cost = best[i - 1] + h + 0.001
                if cost < best[j] then
                    local cols = {}
                    for k = i, j do cols[k] = tmp[k] end
                    best[j], from[j], colsOf[j], hOf[j] = cost, i, cols, h
                end
            end
        end
        local rows, m, j = {}, 0, n
        while j > 0 do
            local i = from[j]
            m = m + 1
            rows[m] = { i = i, j = j, cols = colsOf[j], h = hOf[j] }
            j = i - 1
        end
        for a = 1, math.floor(m / 2) do rows[a], rows[m - a + 1] = rows[m - a + 1], rows[a] end
        return rows, m
    end

    -- Le résultat ne dépend que des effectifs et largeurs : réutilisé s'ils
    -- sont identiques au rendu précédent (un cache par appel de Flow).
    local function Pack(blocks, n)
        flowIdx = flowIdx + 1
        local c = packCache[flowIdx]
        if not c then
            c = { n = -1, cnt = {}, lw = {} }
            packCache[flowIdx] = c
        end
        local same = c.n == n
        if same then
            for k = 1, n do
                local b = blocks[k]
                if c.cnt[k] ~= b.count or c.lw[k] ~= b.lw then
                    same = false
                    break
                end
            end
        end
        if same then return c.rows, c.nRows end

        for k = 1, n do
            local b = blocks[k]
            c.cnt[k], c.lw[k] = b.count, b.lw
        end
        c.n = n
        c.rows, c.nRows = Compute(blocks, n)
        return c.rows, c.nRows
    end

    -- ── Rendu ─────────────────────────────────────────────────────
    local function Count(list, def)
        return #list + ((holding and not def.noAssign) and 1 or 0)
    end

    -- Grille des objets (x0, y0 : coin haut-gauche ; cols colonnes), plus un
    -- "+" si on tient un objet. Renvoie la hauteur utilisée.
    local function Grid(list, def, x0, y0, cols)
        local total = Count(list, def)
        local n = #list
        for i = 1, total do
            local x = x0 + ((i - 1) % cols) * CELL
            local py = -(y0 + math.floor((i - 1) / cols) * CELL)
            local widget
            if i <= n then
                local entry = list[i]
                widget = IB.Acquire(entry.bag, entry.slot)
                IB.Set(widget, entry)
            else
                widget = Plus.Acquire(content, def.id)
            end
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", content, "TOPLEFT", x, py)
        end
        if total == 0 then return 0 end
        local w = math.min(total, cols) * CELL - GAP
        if x0 + w > usedW then usedW = x0 + w end
        return math.ceil(total / cols) * CELL - GAP + BLOCK_TAIL
    end

    local function PlaceItems(b, x0, y0, cols)
        if b.frees then
            for i = 1, b.count do
                local f = b.frees[i]
                local btn = IB.Acquire(f.slot.bag, f.slot.slot)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", content, "TOPLEFT", x0 + (i - 1) * CELL, -y0)
                IB.SetFree(btn, f.slot, f.num, f.reagent)
            end
            return SLOT + BLOCK_TAIL
        end
        return Grid(b.list, b.def, x0, y0, cols)
    end

    local function NewBlock(def, list, text)
        nBlock = nBlock + 1
        local b = blockPool[nBlock]
        if not b then
            b = {}
            blockPool[nBlock] = b
        end
        b.def, b.list, b.text, b.count = def, list, text, Count(list, def)
        b.frees = nil
        return b
    end

    -- Blocs côte à côte, en rangées compactes. Renvoie la hauteur utilisée.
    local function Flow(blocks, n)
        for k = 1, n do
            local b = blocks[k]
            b.label = Sections.AcquireLabel(content, b.text,
                (bulk and not b.def.noBulk) and b or nil)
            b.lw = math.min(b.label.textW, LABEL_MAX_W)
            b.hi = math.min(COLS, math.max(b.count, 1))
            b.lo = math.min(b.hi, MIN_COLS)
        end

        local top = y
        local rows, nRows = Pack(blocks, n)
        for ri = 1, nRows do
            local r = rows[ri]
            local x = 0
            for k = r.i, r.j do
                local b = blocks[k]
                local w = BlockWidth(b, r.cols[k])
                b.label:SetPoint("TOPLEFT", content, "TOPLEFT", x, -top)
                Sections.SetLabelWidth(b.label, w)
                PlaceItems(b, x, top + LABEL_H, r.cols[k])
                x = x + w + GROUP_GAP
            end
            if x - GROUP_GAP > usedW then usedW = x - GROUP_GAP end
            top = top + r.h
        end
        return top - y
    end

    -- ctx du clic droit pour un en-tête (nil : pas de vente groupée).
    local function HeadContext(def, direct, kids, groups)
        if not bulk or def.noBulk then return nil end
        nHead = nHead + 1
        local c = headCtx[nHead]
        if not c then
            c = {}
            headCtx[nHead] = c
        end
        c.def, c.list, c.kids, c.groups = def, direct, kids, groups
        return c
    end

    -- true si la catégorie est repliée (ses objets cachés ne se vendent pas).
    local function Header(id, label, count, ctx)
        local key = cfg.prefix .. id
        local isCollapsed = collapsed[key]
        Sections.Acquire(content, y, key, label, count, isCollapsed, Toggle,
                         (not isCollapsed) and ctx or nil)
        y = y + SECTION_H + HEAD_TAIL
        return isCollapsed
    end

    local function Visible(def, count)
        return count > 0 or (def.custom and showCustom) or (holding and not def.noAssign)
    end

    local function Flush()
        if nRun == 0 then return end
        y = y + Flow(run, nRun) + SECTION_GAP
        nRun = 0
    end

    -- snap = { groups, free, freeReagent }.
    -- opts = { holding, showCustom, pickFree(free), view (ns.View, sinon catégories) }.
    -- Renvoie la hauteur et la largeur utilisées.
    function G.Render(snap, opts)
        IB.Begin()
        Sections.Reset()
        if Plus then Plus.Reset() end

        collapsed = ns.Settings.Table("collapsed")
        holding = cfg.usePlus and opts.holding
        showCustom, pickFree = opts.showCustom, opts.pickFree
        y, usedW, nRun, nBlock, flowIdx, nHead = 0, 0, 0, 0, 0, 0

        -- Vue (ns.View) : catégories racines, enfants et regroupement.
        local view = opts.view
        bulk = cfg.context and (not view or view.bulk ~= false)
        local groups = view and view.groups(snap) or snap.groups
        local childrenOf = view and (view.children or NoKids) or ns.GetChildren
        local noFree = view and view.noFree

        for _, def in ipairs(view and view.tops() or ns.GetTopCategories()) do
            local direct = groups[def.id] or EMPTY
            local kids = childrenOf(def.id)
            local total = #direct
            for _, kid in ipairs(kids) do
                total = total + #(groups[kid.id] or EMPTY)
            end

            if Visible(def, total) then
                if #kids == 0 and not def.header then
                    nRun = nRun + 1
                    run[nRun] = NewBlock(def, direct, ns.GetCategoryLabel(def))
                else
                    Flush()
                    if not Header(def.id, ns.GetCategoryLabel(def),
                                  def.count and def.count(direct) or total,
                                  HeadContext(def, direct, kids, groups)) then
                        y = y + Grid(direct, def, 0, y, COLS)
                        nSub = 0
                        for _, kid in ipairs(kids) do
                            local list = groups[kid.id] or EMPTY
                            if Visible(kid, #list) then
                                nSub = nSub + 1
                                sub[nSub] = NewBlock(kid, list, ns.GetCategoryLabel(kid))
                            end
                        end
                        y = y + Flow(sub, nSub)
                    end
                    y = y + SECTION_GAP
                end
            end
        end

        -- Emplacements libres : sacs puis sac de composants (fleur), tout en bas.
        local nFree = 0
        if not noFree then
            local free, reagent = snap.free, snap.freeReagent
            if #free > 0 then
                nFree = nFree + 1
                local f = freeSlots[nFree]
                f.slot, f.num, f.reagent = pickFree and pickFree(free) or free[1], #free, false
            end
            if reagent and #reagent > 0 then
                nFree = nFree + 1
                local f = freeSlots[nFree]
                f.slot, f.num, f.reagent = reagent[1], #reagent, true
            end
        end
        Flush()
        if nFree > 0 then
            local b = NewBlock(FREE_DEF, EMPTY, ns.L("CAT_FREE"))
            b.count, b.frees = nFree, freeSlots
            nRun = 1
            run[1] = b
        end
        Flush()
        IB.Finish()

        return math.max(y - SECTION_GAP, 1), usedW
    end

    Apply(ns.UI.GetMetrics("standard"), cfg.cols)

    return G
end
