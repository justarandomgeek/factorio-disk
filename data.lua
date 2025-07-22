local meld = require("meld")

data.extend{
  {
    type = "item-with-tags",
    name = "disk",
    icon = "__disk__/graphics/disk-512.png",
    icon_size = 32,
    flags = { "not-stackable", "spawnable" },
    subgroup = "other",
    order = "s[item-with-tags]-o[item-with-tags]",
    stack_size = 1,
    can_be_mod_opened=true
  },
  {
    type = "shortcut",
    name = "give-disk",
    order = "b[disk]-g[disk]",
    action = "spawn-item",
    --technology_to_unlock = "construction-robotics",
    item_to_spawn = "disk",
    style = "default",
    icon = "__disk__/graphics/disk-512.png",
    icon_size = 32, -- 56
    small_icon = "__disk__/graphics/disk-512.png",
    small_icon_size = 32 -- 24
  },
  {
    type = "item",
    name = "diskreader",
    icon = "__base__/graphics/icons/roboport.png",
    icon_size = 64,
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
      { type="item", name="processing-unit", amount=2 },
      { type="item", name="decider-combinator", amount=5 }
    },
    results = {
      { type="item", name="diskreader", amount=1 }
    },
    icon = "__base__/graphics/icons/roboport.png",
    icon_size = 64,
  },
  meld.meld(table.deepcopy(data.raw["decider-combinator"]["decider-combinator"]), {
    name = "diskreader",
    minable = {
      result = "diskreader",
    },
    fast_replaceable_group = meld.delete(),
    created_effect = meld.overwrite{
      type = "direct",
      action_delivery = {
        type = "instant",
        source_effects = {
          {
            type = "script",
            effect_id = "diskreader-created",
          },
        }
      }
    },
    sprites = data.raw["selector-combinator"]["selector-combinator"].sprites,
    activity_led_sprites = data.raw["selector-combinator"]["selector-combinator"].activity_led_sprites,
    input_connection_points = data.raw["selector-combinator"]["selector-combinator"].input_connection_points,
    output_connection_points = data.raw["selector-combinator"]["selector-combinator"].output_connection_points,
    equal_symbol_sprites = meld.overwrite({
      north = util.draw_as_glow
        {
          scale = 0.5,
          filename = "__disk__/graphics/combinator-display.png",
          width = 30,
          height = 22,
          shift = util.by_pixel(0, -4.5)
        },
      east = util.draw_as_glow
        {
          scale = 0.5,
          filename = "__disk__/graphics/combinator-display.png",
          width = 30,
          height = 22,
          shift = util.by_pixel(0, -10.5)
        },
      south = util.draw_as_glow
        {
          scale = 0.5,
          filename = "__disk__/graphics/combinator-display.png",
          width = 30,
          height = 22,
          shift = util.by_pixel(0, -4.5)
        },
      west = util.draw_as_glow
        {
          scale = 0.5,
          filename = "__disk__/graphics/combinator-display.png",
          width = 30,
          height = 22,
          shift = util.by_pixel(0, -10.5)
        }
    }),
    greater_symbol_sprites = meld.delete(),
    less_symbol_sprites = meld.delete(),
    not_equal_symbol_sprites = meld.delete(),
    greater_or_equal_symbol_sprites = meld.delete(),
    less_or_equal_symbol_sprites = meld.delete(),
  }),
  {
    type = "container",
    name = "diskreader-chest",
    inventory_size = 1,
    inventory_type = "with_filters_and_bar",
    flags = {"placeable-off-grid"},
    allow_copy_paste = false,
    selection_box = {{-0.4, -0.4}, {0.4, 0.4}},
    collision_box = {{-0.5, -0.5}, {0.5, 0.5}}, -- a box for inserters to reach
    collision_mask = {layers = {}}, -- but no mask so it doesn't really collide
  },
}
