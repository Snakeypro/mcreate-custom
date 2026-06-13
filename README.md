# MCreate Custom

This plugin now supports a **Create Mod Block architecture contract** that is no longer hard-bound to `CKB` / `CKBG` name prefixes.

## Create Mod Block contract

Create behavior can be enabled with a custom block property:

- `CUSTOM:MCREATE_MOD_BLOCK` = `true`

Generator/consumer role can be set with:

- `CUSTOM:MCREATE_ROLE` = `GENERATOR` or `CONSUMER`

Legacy name-prefix behavior (`CKB*`, `CKBG*`) is still supported for compatibility.

## Create-specific foundation added in this redesign

- Explicit Create block detection helper (`templates/mcreate/create_block_config.ftl`)
- Template routing for block + block entity now uses Create contract + legacy fallback
- List-style shaft configuration support in `CustomDirectionalKineticBlock`:
  - per-direction mode (`NONE`, `INPUT`, `OUTPUT`, `BOTH`)
  - independent-control flag
  - per-shaft speed multiplier
  - per-shaft visual toggle
- Rotating visual list support in `CustomDirectionalKineticBlock`
- Renderer support for configured shaft multipliers and rotating visual entries

## New procedure blocks

- `configure_shaft_entry`
- `clear_shaft_configurations`
- `add_rotating_visual`
- `clear_rotating_visuals`

These extend the existing kinetic procedures so complex Create behavior can be built as list-driven runtime configuration.
