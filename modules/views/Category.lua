local addonName, ns = ...

-- Vue par catégories (comportement d'origine).

ns.View.Register({
    id = "category", labelKey = "VIEW_CATEGORY", order = 1,
    tops     = ns.GetTopCategories,
    children = ns.GetChildren,
    groups   = function(snap) return snap.groups end,
})
