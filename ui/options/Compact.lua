local addonName, ns = ...

-- Option : sac compact.

ns.UI.RegisterOption({
    id = "compact", order = 1,
    labelKey = "OPT_COMPACT", descKey = "OPT_COMPACT_DESC",
    get = ns.Compact.IsEnabled,
    set = ns.Compact.Set,
})
