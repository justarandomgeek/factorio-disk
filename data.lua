data:extend{
  {
    type = "item-with-tags",
    name = "disk",
    icon = "__disk__/graphics/disk-512.png",
    flags = {},
    subgroup = "other",
    order = "s[item-with-tags]-o[item-with-tags]",
    stack_size = 1
  },
  {
    type = "recipe",
    name = "disk",
    enabled = true,
    energy_required = 1,
    ingredients =
    {
      {"processing-unit",1},
      {"advanced-circuit", 10}
    },
    result = "disk",
    result_count = 1,
    icon = "__disk__/graphics/disk-512.png",
  },
  {
    type = "item",
    name = "diskreader",
    icon = "__base__/graphics/icons/roboport.png",
    flags = {"goes-to-quickbar"},
    subgroup = "logistic-network",
    order = "c[signal]-b[diskreader]",
    place_result="diskreader",
    stack_size = 50,
  },
  {
    type = "recipe",
    name = "diskreader",
    enabled = true,
    energy_required = 1,
    ingredients =
    {
      {"processing-unit", 2},
      {"decider-combinator",5}
    },
    result = "diskreader",
    result_count = 1,
    icon = "__base__/graphics/icons/roboport.png",
  },
  {
    type = "item",
    name = "diskreader-control",
    icon = "__base__/graphics/icons/roboport.png",
    flags = {"goes-to-quickbar", "hidden"},
    subgroup = "logistic-network",
    order = "c[signal]-b[diskreader-control]",
    place_result="diskreader-control",
    stack_size = 50,
  },
  {
    type = "recipe-category",
    name = "diskreader"
  },
  {
    type = "recipe",
    name = "diskreader-process",
    enabled = true,
    hidden = true,
    energy_required = 1,
    category = "diskreader",
    ingredients =
    {
      {"disk", 1}
    },
    result = "disk",
    result_count = 1,
    icon = "__base__/graphics/icons/processing-unit.png",
  },

  {
    type = "item-subgroup",
    name = "virtual-signal-diskreader",
    group = "signals",
    order = "z"
  },
  {
    type = "virtual-signal",
    name = "signal-diskreader-read",
    icon = "__disk__/graphics/disk-read.png",
    subgroup = "virtual-signal-diskreader",
    order = "z[diskreader]-[1R]"
  },
  {
    type = "virtual-signal",
    name = "signal-diskreader-write",
    icon = "__disk__/graphics/disk-write.png",
    subgroup = "virtual-signal-diskreader",
    order = "z[diskreader]-[2W]"
  },
  {
    type = "virtual-signal",
    name = "signal-diskreader-status",
    icon = "__disk__/graphics/disk-status.png",
    subgroup = "virtual-signal-diskreader",
    order = "z[diskreader]-[3S]"
  },

}


local diskreaderent = table.deepcopy(data.raw["furnace"]["electric-furnace"])
diskreaderent.name="diskreader"
diskreaderent.minable.result = "diskreader"
diskreaderent.fast_replaceable_group = nil
diskreaderent.crafting_categories = {"diskreader"}
diskreaderent.crafting_speed = 1
diskreaderent.module_specification = nil
diskreaderent.allowed_effects = nil
diskreaderent.collision_box = {{-1.2, -1.2}, {1.2, 0.8}} -- collision_box = {{-1.2, -1.2}, {1.2, 1.2}}
data:extend{diskreaderent}

local diskreaderctrl = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
diskreaderctrl.name="diskreader-control"
diskreaderctrl.minable= nil
diskreaderctrl.order="z[lol]-[diskreaderctrl]"
diskreaderctrl.item_slot_count = 500
diskreaderctrl.collision_box = {{-0.4,  0.0}, {0.4, 0.4}}
data:extend{diskreaderctrl}
