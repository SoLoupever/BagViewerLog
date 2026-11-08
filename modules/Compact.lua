local addonName, ns = ...

-- Mode compact : simple réglage. L'UI réagit à COMPACT_CHANGED.

ns.Compact = {}

function ns.Compact.IsEnabled()
    return ns.Settings.Get("compact") == true
end

function ns.Compact.Set(on)
    on = on and true or false
    if on == ns.Compact.IsEnabled() then return end
    ns.Settings.Set("compact", on or nil)
    ns.Fire("COMPACT_CHANGED", on)
end
