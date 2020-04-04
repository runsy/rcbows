rcbows = {}

local S = minetest.get_translator(minetest.get_current_modname())

function rcbows.spawn_arrow(user, strength, arrow)
	local pos = user:get_pos()
	pos.y = pos.y + 1.5 -- camera offset
	local dir = user:get_look_dir()
	local yaw = user:get_look_horizontal()

	local obj = minetest.add_entity(pos, arrow)
	if not obj then
		return
	end
	obj:get_luaentity().shooter_name = user:get_player_name()
	obj:set_yaw(yaw - 0.5 * math.pi)
	obj:set_velocity(vector.multiply(dir, strength))
	return true
end

function rcbows.register_bow(name, def)
	assert(type(def.description) == "string")
	assert(type(def.image) == "string")
	assert(type(def.strength) == "number")
	assert(def.uses > 0)

	local function reload_bow(itemstack, user)
		local inv = user:get_inventory()
		local inventory_arrow_name = minetest.registered_entities[def.arrow].inventory_arrow_name or ""
		if not inv:remove_item("main", inventory_arrow_name):is_empty() then
			itemstack:set_name(name .. "_charged")
			if def.sounds then
				local user_pos = user:get_pos()
				if not def.sounds.soundfile_draw_bow then
					def.sounds.soundfile_draw_bow = "rcbows_draw_bow"
				end
				rcbows.make_sound("pos", user_pos, def.sounds.soundfile_draw_bow, gain, max_hear_distance)
			end
			return itemstack
		end
	end

	minetest.register_tool(name, {
		description = def.description .. " ".. S("(place to reload)"),
		inventory_image = def.image .. "^" .. def.overlay_empty,

		on_use = function() end,
		on_place = reload_bow,
		on_secondary_use = reload_bow,
	})

	if def.recipe then
		minetest.register_craft({
			output = name,
			recipe = def.recipe
		})
	end

	minetest.register_tool(name .. "_charged", {
		description = def.description .. " " .. S("(use to fire)"),
		inventory_image = def.image .. "^" ..def.overlay_charged,
		groups = {not_in_creative_inventory=1},

		on_use = function(itemstack, user, pointed_thing)
			if not rcbows.spawn_arrow(user, def.strength, def.arrow) then
				return -- something failed
			end
			if def.sounds then
				local user_pos = user:get_pos()
				if not def.sounds.soundfile_fire_arrow then
					def.sounds.soundfile_fire_arrow = "rcbows_fire_arrow"
				end
				rcbows.make_sound("pos", pos, def.sounds.soundfile_fire_arrow, gain, max_hear_distance)
			end
			itemstack:set_name(name)
			itemstack:set_wear(itemstack:get_wear() + 0x10000 / def.uses)
			return itemstack
		end,
	})
end

function rcbows.register_arrow(name, def)
	minetest.register_entity(name, {
		hp_max = 4,       -- possible to catch the arrow (pro skills)
		physical = false, -- use Raycast
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		visual = "wielditem",
		textures = {def.projectile_texture},
		visual_size = {x = 0.2, y = 0.15},
		old_pos = nil,
		shooter_name = "",
		waiting_for_removal = false,
		inventory_arrow_name = def.inventory_arrow.name,

		on_activate = function(self)
			self.object:set_acceleration({x = 0, y = -9.81, z = 0})
		end,

		on_step = function(self, dtime)
			if self.waiting_for_removal then
				self.object:remove()
				return
			end
			local pos = self.object:get_pos()
			self.old_pos = self.old_pos or pos
			local cast = minetest.raycast(self.old_pos, pos, true, false)
			local thing = cast:next()
			while thing do
				if thing.type == "object" and thing.ref ~= self.object then
					if not thing.ref:is_player() or thing.ref:get_player_name() ~= self.shooter_name then
						thing.ref:punch(self.object, 1.0, {
							full_punch_interval = 0.5,
							damage_groups = {fleshy = def.damage}
						})
						self.waiting_for_removal = true
						self.object:remove()
						return
					end
				elseif thing.type == "node" then
					local name = minetest.get_node(thing.under).name
					if minetest.registered_items[name].walkable then
						minetest.item_drop(ItemStack(def.inventory_arrow), nil, vector.round(self.old_pos))
						self.waiting_for_removal = true
						self.object:remove()
						return
					end
				end
				thing = cast:next()
			end
			self.old_pos = pos
		end,
	})
	minetest.register_craftitem(def.inventory_arrow.name, {
		description = def.inventory_arrow.description,
		inventory_image = def.inventory_arrow.inventory_image,
	})
end

local DEFAULT_MAX_HEAR_DISTANCE = 10
local DEFAULT_GAIN = 0.5

function rcbows.make_sound(dest_type, dest, soundfile, gain, max_hear_distance)
	if dest_type == "object" then
		minetest.sound_play(soundfile, {object = dest, gain = gain or DEFAULT_GAIN, max_hear_distance = max_hear_distance or mokapi.consts.DEFAULT_MAX_HEAR_DISTANCE,})
	 elseif dest_type == "player" then
		local player_name = dest:get_player_name()
		minetest.sound_play(soundfile, {to_player = player_name, gain = gain or DEFAULT_GAIN, max_hear_distance = max_hear_distance or mokapi.consts.DEFAULT_MAX_HEAR_DISTANCE,})
	 elseif dest_type == "pos" then
		minetest.sound_play(soundfile, {pos = dest, gain = gain or DEFAULT_GAIN, max_hear_distance = max_hear_distance or mokapi.consts.DEFAULT_MAX_HEAR_DISTANCE,})
	end
end
