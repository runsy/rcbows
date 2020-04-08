# RCBOWS

## function rcbows.register_arrow(name, def)
Example:
```
rcbows.register_arrow("farbows:e_arrow", {
	damage = 5,
	inventory_arrow = {
		name = "farbows:inv_arrow",
		description = S("Arrow"),
		inventory_image = "farbows_arrow.png",
	}
})
```
## function rcbows.register_bow(name, def)
Example:
```
rcbows.register_bow("farbows:bow_wood", {
	description = S("Wooden Bow"),
	image = "farbows_bow_wood.png",
	strength = 30,
	uses = 150,
	charge_time = 0.5,
	recipe = {
		{"", "group:wood", "farming:string"},
		{"group:wood", "", "farming:string"},
		{"", "group:wood", "farming:string"},
	},
	overlay_empty = "farbows_overlay_empty.png",
	overlay_charged = "farbows_overlay_charged.png",
	arrows = "farbows:e_arrow",
	sounds = {
		max_hear_distance = 10,
		gain = 0.4,
	}
})
```

You can define "arrows" as a single arrow (string) or a table of arrows.

In this case the order matters. The first ones have preference over the last ones when charging the bow.

I.e:
```
arrows = {"farbows:e_arrow", ""farbows:ice_arrow""},
```


## Audio

1. If you define ``sounds={}``, you get the default sounds.

For no sound at all do not declare 'sounds'.

Also you can set the sound parameters 'max_hear_distance' and 'gain'.

In example:
```
sounds = {
	max_hear_distance = 10,
	gain = 0.4,
}
```

2. You also can define your own soundfiles.

In example:
```
sounds = {
	soundfile_draw_bow = "my_draw_bow"
	soundfile_fire_arrow = "my_fire_arrow"
	soundfile_hit_arrow = "my_hit_arrow"
	max_hear_distance = 5,
	--set the gain by default (0.5)
}
```

## Drop

By default the arrow drops the inventory_arrow when reachs a solid node.

If you want to define another item to drop, define it with 'drop':
```
rcbows.register_arrow("farbows:e_arrow", {
	damage = 5,
	inventory_arrow = {
		name = "farbows:inv_arrow",
		description = S("Arrow"),
		inventory_image = "farbows_arrow.png",
	}
	drop = "farbows_drop_arrow"
})
```

## Arrow Effects
You can define some arrow effects
- replace_node : Replace the hit node for this one.
- trail_particle : Particle texture to create an arrow trail.
In example:
```
rcbows.register_arrow("farbows:fire_arrow", {
	damage = 7,
	inventory_arrow = {
		name = "farbows:inv_fire_arrow",
		description = S("Fire Arrow"),
		inventory_image = "farbows_arrow_fire.png",
	},
	drop = "farbows:inv_arrow",
	effects = {
		replace_node = "fire:basic_flame",
		trail_particle = "farbows_particle_fire.png",
	}
})
```
