data:extend{
  {
    type = "item-with-tags",
    name = "datatape",
    icon = "__base__/graphics/icons/processing-unit.png",
    flags = {},
    subgroup = "other",
    order = "s[item-with-tags]-o[item-with-tags]",
    stack_size = 1
  },
  {
    type = "item",
    name = "datareader",
    icon = "__base__/graphics/icons/roboport.png",
    flags = {"goes-to-quickbar"},
    subgroup = "logistic-network",
    order = "c[signal]-b[datareader]",
    place_result="datareader",
    stack_size = 50,
  },
  {
    type = "item",
    name = "datareader-control",
    icon = "__base__/graphics/icons/roboport.png",
    flags = {"goes-to-quickbar", "hidden"},
    subgroup = "logistic-network",
    order = "c[signal]-b[datareader-control]",
    place_result="datareader-control",
    stack_size = 50,
  },
  {
    type = "recipe-category",
    name = "datareader"
  },
  {
    type = "recipe",
    name = "datareader-process",
    enabled = true,
    energy_required = 1,
    category = "datareader",
    ingredients =
    {
      {"datatape", 1}
    },
    result = "datatape",
    result_count = 1,
    icon = "__base__/graphics/icons/roboport.png",
  },

  {
    type = "item-subgroup",
    name = "virtual-signal-datareader",
    group = "signals",
    order = "z"
  },
  {
    type = "virtual-signal",
    name = "signal-datareader-read",
    icon = "__base__/graphics/icons/signal/signal_R.png",
    subgroup = "virtual-signal-datareader",
    order = "z[datareader]-[R]"
  },
  {
    type = "virtual-signal",
    name = "signal-datareader-write",
    icon = "__base__/graphics/icons/signal/signal_W.png",
    subgroup = "virtual-signal-datareader",
    order = "z[datareader]-[W]"
  },

}


local datareaderent = table.deepcopy(data.raw["furnace"]["electric-furnace"])
datareaderent.name="datareader"
datareaderent.minable.result = "datareader"
datareaderent.fast_replaceable_group = nil
datareaderent.crafting_categories = {"datareader"}
datareaderent.crafting_speed = 1
datareaderent.module_specification = nil
datareaderent.allowed_effects = nil
datareaderent.collision_box = {{-1.2, -1.2}, {1.2, 0.8}} -- collision_box = {{-1.2, -1.2}, {1.2, 1.2}}
data:extend{datareaderent}

local datareaderctrl = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
datareaderctrl.name="datareader-control"
datareaderctrl.minable= nil
datareaderctrl.order="z[lol]-[datareaderctrl]"
datareaderctrl.item_slot_count = 500
datareaderctrl.collision_box = {{-0.4,  0.0}, {0.4, 0.4}}
data:extend{datareaderctrl}
