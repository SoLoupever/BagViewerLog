local addonName, ns = ...

-- Profil compact : grille 12 colonnes au pas de 38, panneau latéral des modes
-- d'affichage, hauteur plafonnée.

ns.UI.RegisterMetrics("compact", {
    cols = 12, slot = 34, gap = 4,
    pad = 10, scrollW = 24,
    titleH = 34, titleTextY = 12, titleAreaY = 6,
    toolbarH = 26, footerH = 20, chromeGap = 6,
    sectionH = 16, sectionGap = 6, labelPad = 4, groupGap = 10,
    blockTail = 4, headerTail = 4,
    minCols = 3, labelMaxW = 64, fitCols = 9,
    sideW = 148, sideGap = 12, views = true,
    minHeight = 240, maxHeight = 648,
})
