local adopt_native_storage = require("native-storage-import")
local function stringStarts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

local machines = {}
for name, machine in pairs(prototypes.get_entity_filtered{{filter="type", type="assembling-machine"}}) do
    if machine.module_inventory_size > 0 and not stringStarts(name, "QualityEffects-") then
        machines[name] = true
    end
end

local function check_entity(entity_name)
    if machines[entity_name] ~= nil then return true end
    return false
end

local on_built = function (data)
    local entity = data.entity
    if entity.quality.level == 0 then return end
    if not check_entity(entity.name) then return end
    local target_name = "QualityEffects-" .. entity.quality.name .. "-" .. entity.name
    if not prototypes.entity[target_name] then return end

    local surface = entity.surface
    local info = {
        name = target_name,
        position = entity.position,
        direction = entity.direction,
        quality = entity.quality,
        force = entity.force,
        fast_replace = true,
        player = entity.last_user,
    }
    local health, energy = entity.health, entity.energy
    local recipe_locked = entity.recipe_locked
    local disabled, minable = entity.disabled_by_script, entity.minable_flag
    local destructible, operable, rotatable = entity.destructible, entity.operable, entity.rotatable
    -- Native fast replacement transfers buffers only from a minable source.
    entity.minable_flag = true
    if not surface.can_fast_replace(info) then
        entity.minable_flag = minable
        log("Quality Effects could not safely replace " .. entity.name)
        return
    end
    local trash = entity.get_inventory(defines.inventory.crafter_trash)
    local saved_trash
    if trash and not trash.is_empty() then
        local capacity = prototypes.entity[target_name].get_inventory_size(defines.inventory.crafter_trash, entity.quality)
        if not capacity or capacity < #trash then
            entity.minable_flag = minable
            log("Quality Effects could not preserve crafter trash for " .. entity.name)
            return
        end
        -- Native fast replacement drops this inventory. Move actual stacks so
        -- tags, partial ammo, spoil ticks and other opaque item state survive.
        saved_trash = game.create_inventory(#trash)
        for index = 1, #trash do
            if trash[index].valid_for_read then
                assert(saved_trash[index].swap_stack(trash[index]), "Quality Effects could not escrow crafter trash")
            end
        end
    end
    local function restore_trash(target)
        if not saved_trash then return end
        local inventory = target.get_inventory(defines.inventory.crafter_trash)
        assert(inventory and #inventory >= #saved_trash, "Quality Effects crafter trash inventory changed during replacement")
        for index = 1, #saved_trash do
            if saved_trash[index].valid_for_read then
                local slot = not inventory[index].valid_for_read and inventory[index] or inventory.find_empty_stack()
                assert(slot and slot.swap_stack(saved_trash[index]), "Quality Effects could not restore crafter trash")
            end
        end
        assert(saved_trash.is_empty(), "Quality Effects still owns pending crafter trash")
        saved_trash.destroy()
    end
    info.spill = false
    local replacement = surface.create_entity(info)
    if replacement then
        replacement.health, replacement.energy = health, energy
        replacement.recipe_locked = recipe_locked
        replacement.disabled_by_script, replacement.minable_flag = disabled, minable
        replacement.destructible, replacement.operable, replacement.rotatable = destructible, operable, rotatable
        restore_trash(replacement)
    elseif entity.valid then
        entity.minable_flag = minable
        restore_trash(entity)
    elseif saved_trash then
        error("Quality Effects native replacement failed after removing its source")
    end
end

script.on_event(defines.events.on_built_entity, on_built, {{filter = "crafting-machine"}})
script.on_event(defines.events.on_robot_built_entity, on_built, {{filter = "crafting-machine"}})
script.on_event(defines.events.on_space_platform_built_entity, on_built, {{filter = "crafting-machine"}})
local function migrate_machines()
  adopt_native_storage()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{type="assembling-machine"}) do
      on_built{entity=entity}
    end
  end
end
script.on_init(migrate_machines)
script.on_configuration_changed(migrate_machines)
