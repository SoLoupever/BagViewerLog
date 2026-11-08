local addonName, ns = ...

-- Profil standard.

ns.UI.RegisterMetrics("standard", {
    cols = 15, slot = 37, gap = 4,
    pad = 12, scrollW = 24,
    titleH = 44, titleTextY = 20, titleAreaY = 10,
    toolbarH = 26, footerH = 20, chromeGap = 8,
    sectionH = 18, sectionGap = 10, labelPad = 6, groupGap = 14,
    blockTail = 6, headerTail = 6,
    minCols = 3, labelMaxW = 64, fitCols = 10,
})
