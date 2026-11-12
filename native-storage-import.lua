local original_ids = {"QualityEffects"}
return function()
    local pending = storage._migrated
    if not pending then return false end
    local imported, source
    for _, name in ipairs(original_ids) do
        if pending[name] then
            assert(not imported, "Multiple removed-mod states require a mod-specific merge")
            imported, source = pending[name], name
        end
    end
    if not imported then return false end
    -- Preserve the imported root table, including cycles and registered metatables.
    -- Existing destination state must not be overwritten silently.
    local destination = storage
    for key, value in pairs(destination) do
        if key ~= "_migrated" then
            assert(imported[key] == nil or imported[key] == value,
                "Conflicting existing and removed-mod state requires an explicit merge: " .. tostring(key))
            imported[key] = value
        end
    end
    pending[source] = nil
    if next(pending) then
        assert(imported._migrated == nil, "Nested migration states require an explicit merge")
        imported._migrated = pending
    end
    storage = imported
    return true
end
