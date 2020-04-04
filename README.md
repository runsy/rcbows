# RCBOWS

## function rcbows.register_arrow(name, def)
Example:
```
rcbows.register_arrow("farbows:e_arrow", {
	projectile_texture = "farbows_proyectile_arrow",
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
	recipe = {
		{"", "group:wood", "farming:string"},
		{"group:wood", "", "farming:string"},
		{"", "group:wood", "farming:string"},
	},
	overlay_empty = "farbows_overlay_empty.png",
	overlay_charged = "farbows_overlay_charged.png",
	arrow = "farbows:e_arrow",
})
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
