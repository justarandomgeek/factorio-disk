local meld = require("meld")

data.extend{
  {
    type = "item-with-tags",
    name = "disk",
    icon = "__disk__/graphics/disk-icon.png",
    icon_size = 64,
    flags = { "not-stackable", "spawnable" },
    subgroup = "other",
    order = "s[item-with-tags]-o[item-with-tags]",
    stack_size = 1,
  },
  {
    type = "shortcut",
    name = "give-disk",
    order = "b[disk]-g[disk]",
    action = "spawn-item",
    technology_to_unlock = "circuit-network",
    item_to_spawn = "disk",
    style = "default",
    icon = "__disk__/graphics/shortcut.png",
    icon_size = 56,
    small_icon = "__disk__/graphics/shortcut.png",
    small_icon_size = 24
  },
  {
    type = "item",
    name = "diskreader",
    icon = "__disk__/graphics/disk-combinator-icon.png",
    icon_size = 64,
    subgroup = "circuit-network",
    order = "c[combinators]-d[diskreader]",
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
  },
  meld.meld(table.deepcopy(data.raw["decider-combinator"]["decider-combinator"]), {
    keep_animation = true,
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
    sprites = meld.overwrite(make_4way_animation_from_spritesheet({ layers =
      {
        {
          scale = 0.5,
          filename = "__disk__/graphics/disk-combinator-entity.png",
          width = 154,
          height = 160,
          shift = util.by_pixel( 1.0, -1.0)
        },
        {
          scale = 0.5,
          filename = "__base__/graphics/entity/combinator/selector-combinator-shadow.png",
          width = 134,
          height = 94,
          shift = util.by_pixel( 8.0, 7.0),
          draw_as_shadow = true
        }
      }
    })),
    activity_led_sprites = data.raw["selector-combinator"]["selector-combinator"].activity_led_sprites,
    input_connection_points = data.raw["selector-combinator"]["selector-combinator"].input_connection_points,
    output_connection_points = data.raw["selector-combinator"]["selector-combinator"].output_connection_points,
    equal_symbol_sprites = meld.overwrite({
      north = {
        layers = {util.draw_as_glow{
            scale = 0.5,
            filename = "__disk__/graphics/disk-display.png",
            width = 30,
            height = 22,
            shift = util.by_pixel_hr(1, -10)
          },
          {
            scale = 0.5,
            filename = "__disk__/graphics/disk-sticking-out.png",
            width = 154,
            height = 160,
            x = 154*0,
            shift = util.by_pixel( 1.0, -1.0)
          }
        },
      },
      east = {
        layers = {util.draw_as_glow{
            scale = 0.5,
            filename = "__disk__/graphics/disk-display.png",
            width = 30,
            height = 22,
            shift = util.by_pixel_hr(1, -22)
          },
          {
            scale = 0.5,
            filename = "__disk__/graphics/disk-sticking-out.png",
            width = 154,
            height = 160,
            x = 154*1,
            shift = util.by_pixel( 1.0, -1.0)
          }
        },
      },
      south = {
        layers = {
          util.draw_as_glow{
            scale = 0.5,
            filename = "__disk__/graphics/disk-display.png",
            width = 30,
            height = 22,
            shift = util.by_pixel_hr(1, -10)
          },
          {
            scale = 0.5,
            filename = "__disk__/graphics/disk-sticking-out.png",
            width = 154,
            height = 160,
            x = 154*2,
            shift = util.by_pixel( 1.0, -1.0)
          }
        },
      },
      west = {
        layers = {util.draw_as_glow{
            scale = 0.5,
            filename = "__disk__/graphics/disk-display.png",
            width = 30,
            height = 22,
            shift = util.by_pixel_hr(1, -22)
          },
          {
            scale = 0.5,
            filename = "__disk__/graphics/disk-sticking-out.png",
            width = 154,
            height = 160,
            x = 154*3,
            shift = util.by_pixel( 1.0, -1.0)
          }
        },
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
    collision_box = {{-0.5, -0.5}, {0.5, 0.5}}, -- a box for inserters to reach
    collision_mask = {layers = {}}, -- but no mask so it doesn't really collide
  },
  {
    type = "custom-input",
    name = "disk-fast-entity-transfer",
    key_sequence = "",
    linked_game_control= "fast-entity-transfer",
    action = "lua",
  },
  {
    type = "custom-input",
    name = "disk-fast-entity-split",
    key_sequence = "",
    linked_game_control= "fast-entity-split",
    action = "lua",
  },
}
