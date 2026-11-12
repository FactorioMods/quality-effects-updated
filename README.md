# Quality Effects: Updated

Requires Factorio 2.1.24 or later.

Quality adds module slots to assembling machines. This fork preserves existing recipe, items, module qualities, fluids and crafting progress when converting machines, including protected machines.

Replace Quality Effects with this fork. Assemblers above normal quality retain their original item names and receive extra module slots. Existing Quality Effects variants keep their entities and module capacity. Converting a parent assembler uses native fast replacement, which replaces its entity reference; stored energy, health and script flags are restored after replacement.

Replace QualityEffects with this mod, keeping its settings. Both versions cannot be enabled together because they define the same prototypes. Factorio native ownership migration transfers the original saved state before initialization. Conflicting existing destination values stop migration instead of overwriting data.

Original author: Andrey. The original license is retained. Authentic upstream Git history is retained.

Quality variants also cover machines generated during data updates, including Quality Assurance AMS machines. Existing quality prototype names are retained.
Existing qualities retain their original module-slot bonuses even when another mod changes quality levels later. This preserves the module capacity of existing Quality Assurance machines.
Crafter trash is transferred as native item stacks during conversion, retaining tags, quality, partial ammunition and spoilage. Conversion is deferred if a modified target cannot hold the original trash inventory.
