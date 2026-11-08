local addonName, ns = ...

-- Profils de dimensions du cadre (emplacements, marges, hauteurs).
-- Un profil s'enregistre dans ui/metrics/ ; les valeurs dérivées sont calculées ici.

local profiles = {}

function ns.UI.RegisterMetrics(id, m)
    m.sideW        = m.sideW or 0
    m.contentW     = m.cols * m.slot + (m.cols - 1) * m.gap
    -- Largeur minimale de la grille quand le cadre s'adapte au contenu.
    m.fitCols      = m.fitCols or m.cols
    m.minContentW  = m.fitCols * m.slot + (m.fitCols - 1) * m.gap
    -- Début de la grille : après le panneau latéral s'il y en a un.
    m.bodyX        = m.pad + (m.sideW > 0 and m.sideW + m.sideGap or 0)
    m.frameW       = m.bodyX + m.contentW + m.scrollW + m.pad
    m.topChrome    = m.titleH + m.toolbarH + m.chromeGap
    m.bottomChrome = m.pad + m.footerH + m.chromeGap
    profiles[id] = m
end

function ns.UI.GetMetrics(id)
    return profiles[id] or profiles.standard
end
