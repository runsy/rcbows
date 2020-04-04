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
