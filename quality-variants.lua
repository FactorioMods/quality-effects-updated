local quality_slot_bonuses = {}
return function()
local qualities = table.deepcopy(data.raw["quality"])
-- The original variants used the qualities available during data.lua. Retain
-- those slot bonuses when late-generated parent machines become available.
for name, quality in pairs(qualities) do
    if quality.level > 0 and quality_slot_bonuses[name] == nil then
        quality_slot_bonuses[name] = quality.level
    end
end
local place_items = {}
for _, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
        local entity = prototype.place_result
        if entity and (not place_items[entity] or name < place_items[entity]) then
            place_items[entity] = name
        end
    end
end

local new_machines = {}

for mname, machine_orig in pairs(data.raw["assembling-machine"]) do
    for qname, qvalue in pairs(qualities) do
        if place_items[mname] and not mname:find("QualityEffects-", 1, true) and machine_orig.module_slots ~= nil and machine_orig.module_slots > 0 and qvalue.level > 0
            and not data.raw["assembling-machine"]["QualityEffects-" .. qname .. "-" .. mname] then
            machine_orig.fast_replaceable_group = machine_orig.fast_replaceable_group or "QualityEffects-" .. mname
            local machine = table.deepcopy(machine_orig)
            machine.placeable_by = {item=place_items[mname], count=1, quality=qname}
            machine.localised_name = {"entity-name." .. mname}
            machine.localised_description = {"entity-description." .. mname}
            machine.hidden = true
            machine.name = "QualityEffects-" .. qname .. "-" .. machine.name
            machine.module_slots = machine.module_slots + quality_slot_bonuses[qname]

            table.insert(new_machines, machine)
        end
    end
end

if #new_machines > 0 then data.extend(new_machines) end

end
