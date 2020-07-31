rcbows = {}

local S = minetest.get_translator(minetest.get_current_modname())

--CONSTANTS
local DEFAULT_MAX_HEAR_DISTANCE = 10
local DEFAULT_GAIN = 0.5

function rcbows.spawn_arrow(user, strength, itemstack)
	local pos = user:get_pos()
	pos.y = pos.y + 1.5 -- camera offset
	local dir = user:get_look_dir()
	local yaw = user:get_look_horizontal()
	local meta = itemstack:get_meta()
	local arrow = meta:get_string("rcbows:charged_arrow")
	local obj = nil
	if pos and arrow then
		obj = minetest.add_entity(pos, arrow)
	end
	if not obj then
		return
	end
	local lua_ent = obj:get_luaentity()
	lua_ent.shooter_name = user:get_player_name()
	obj:set_yaw(yaw - 0.5 * math.pi)
	local velocity = vector.multiply(dir, strength)
	obj:set_velocity(velocity)
	return true
end

function rcbows.launch_arrow(user, name, def, itemstack)
	if not rcbows.spawn_arrow(user, def.strength, itemstack) then --throw arrow (spawn arrow entity)
		return -- something failed
	end
	if def.sounds then
		local user_pos = user:get_pos()
		if not def.sounds.soundfile_fire_arrow then
			def.sounds.soundfile_fire_arrow = "rcbows_fire_arrow"
		end
		rcbows.make_sound("pos", user_pos, def.sounds.soundfile_fire_arrow, DEFAULT_GAIN, DEFAULT_MAX_HEAR_DISTANCE)
	end
	itemstack:set_name(name)
	itemstack:set_wear(itemstack:get_wear() + 0x10000 / def.uses)
	if def.viewfinder then --reset the viewfinder-zoom
		if not(user:get_fov() == 0) then
			user:set_fov(0)
			remove_viewfinder(user, itemstack:get_meta():get_int( "rcbows:viewfinder_id"))
		end
	end
	return itemstack
end

local function show_viewfinder(player, texture)
	local hud_id = player:hud_add({
		hud_elem_type = "image",
		text = texture,
		position = {x=0, y=0},
		scale = {x=-100, y=-100},
		alignment = {x=1, y=1},
		offset = {x=0, y=0}
	})
	return hud_id
end

function remove_viewfinder(player, hud_id)
	if hud_id then
		player:hud_remove(hud_id)
	end
end

function rcbows.register_bow(name, def)
	assert(type(def.description) == "string")
	assert(type(def.image) == "string")
	assert(type(def.strength) == "number")
	assert(def.uses > 0)

	local function reload_bow(itemstack, user, pointed_thing)
		local inv = user:get_inventory()
		local arrow, inventory_arrows, inventory_arrow, inv_arrow_name
		local inv_list = inv:get_list("main")
		if type(def.arrows) == 'table' then --more than one arrow?
			for i = 1, #def.arrows do
				arrow = def.arrows[i]
				inv_arrow_name = minetest.registered_entities[arrow].inventory_arrow_name
				if inv:contains_item("main", inv_arrow_name) then
					if not inventory_arrows then
						inventory_arrows = {}
					end
					inventory_arrows[#inventory_arrows+1] = {arrow = arrow, inv_arrow_name = inv_arrow_name}
				end
			end
		else
			arrow = def.arrows
			inventory_arrow = minetest.registered_entities[def.arrows].inventory_arrow_name
		end
		if not inventory_arrow and not inventory_arrows then
			return
		end
		if inventory_arrows then --more than one arrow?
			for i = 1, #inv_list do
				if inventory_arrow then
					break
				end
				for j = 1, #inventory_arrows do
					local inv_arrow = inventory_arrows[j]
					if inv_list[i]:get_name() == inv_arrow.inv_arrow_name then
						arrow = inv_arrow.arrow
						inventory_arrow = inv_arrow.inv_arrow_name
						break
					end
				end
			end
			if not inventory_arrow then
				return
			end
		end
		if not inv:remove_item("main", inventory_arrow):is_empty() then
			minetest.after(def.charge_time or 0, function(user, name)
				local wielded_item = user:get_wielded_item()
				local wielded_item_name = wielded_item:get_name()
				if wielded_item_name == name then
					local meta = wielded_item:get_meta()
					meta:set_string("rcbows:charged_arrow", arrow) --save the arrow in the meta
					wielded_item:set_name(name .. "_charged")
					user:set_wielded_item(wielded_item)
				end
			end, user, name)
			if def.sounds then
				local user_pos = user:get_pos()
				if not def.sounds.soundfile_draw_bow then
					def.sounds.soundfile_draw_bow = "rcbows_draw_bow"
				end
				rcbows.make_sound("pos", user_pos, def.sounds.soundfile_draw_bow, DEFAULT_GAIN, DEFAULT_MAX_HEAR_DISTANCE)
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

	local charged_name = name .. "_charged"

	minetest.register_tool(charged_name, {
		description = def.description .. " " .. S("(use to fire)"),
		inventory_image = def.base_texture .. "^" ..def.overlay_charged,
		groups = {not_in_creative_inventory=1},

		on_use = function(itemstack, user, pointed_thing)
			return rcbows.launch_arrow(user, name, def, itemstack)
		end,

		on_secondary_use = function(itemstack, user, pointed_thing) --viewfinder
			if not def.viewfinder then
				return
			end
			if user:get_fov() == 0 then
				user:set_fov(def.viewfinder.zoom or 15)
				if def.viewfinder.texture then
					local viewfinder_texture = def.viewfinder.texture
					if viewfinder_texture == "" then
						viewfinder_texture = "rcbows_viewfinder.png"
					end
					itemstack:get_meta():set_int("rcbows:viewfinder_id", show_viewfinder(user, viewfinder_texture))
				end
			else
				user:set_fov(0)
				if def.viewfinder.texture then
					remove_viewfinder(user, itemstack:get_meta():get_int( "rcbows:viewfinder_id"))
				end
			end
			return itemstack
		end
	})
end

function rcbows.register_arrow(name, def)
	minetest.register_entity(name, {
		hp_max = 4,       -- possible to catch the arrow (pro skills)
		physical = false, -- use Raycast
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		visual = "wielditem",
		textures = {def.inventory_arrow.name},
		visual_size = {x = 0.2, y = 0.15},
		old_pos = nil,
		velocity = nil,
		liquidflag = nil,
		shooter_name = "",
		waiting_for_removal = false,
		inventory_arrow_name = def.inventory_arrow.name,
		groups = {arrow = 1},

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
			local velocity = self.object:get_velocity()
			local cast = minetest.raycast(self.old_pos, pos, true, true)
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
						if def.sounds then
							local thing_pos = thing.ref:get_pos()
							if not def.sounds.soundfile_hit_arrow then
								def.sounds.soundfile_hit_arrow = "rcbows_hit_arrow"
							end
							if thing_pos then
								rcbows.make_sound("pos", thing_pos, def.sounds.soundfile_hit_arrow, DEFAULT_GAIN, DEFAULT_MAX_HEAR_DISTANCE)
							end
						end

						-- no effects or not owner, nothing to do.
						-- some effects should also happen if hitting an other object. like tnt, water etc.
						if not def.effects or minetest.is_protected(pos, self.shooter_name) then
							return
						end

						rcbows.boom_effect(def, pos) -- BOOM
						rcbows.water_effect(def, pos) -- water - extinguish fires

						return
					end
				elseif thing.type == "node" then
					local name = minetest.get_node(thing.under).name
					local drawtype = minetest.registered_nodes[name]["drawtype"]
					if drawtype == 'liquid' then
						if not self.liquidflag then
							self.velocity = velocity
							self.liquidflag = true
							local liquidviscosity = minetest.registered_nodes[name]["liquid_viscosity"]
							local drag = 1/(liquidviscosity*6)
							self.object:set_velocity(vector.multiply(velocity, drag))
							self.object:set_acceleration({x = 0, y = -1.0, z = 0})
							rcbows.splash(self.old_pos, "rcbows_bubble.png")
						end
					elseif self.liquidflag then
						self.liquidflag = false
						if self.velocity then
							self.object:set_velocity(self.velocity)
						end
						self.object:set_acceleration({x = 0, y = -9.81, z = 0})
					end
					if minetest.registered_items[name].walkable then
						if not(def.drop) then
							minetest.item_drop(ItemStack(def.drop or def.inventory_arrow), nil, vector.round(self.old_pos))
						end
						self.waiting_for_removal = true
						self.object:remove()

						-- no effects or not owner, nothing to do.
						if not def.effects or minetest.is_protected(pos, self.shooter_name) then
							return
						end

						--replace node
						if def.effects.replace_node then
							minetest.set_node(pos, {name = def.effects.replace_node})
						end

						rcbows.boom_effect(def, pos) -- BOOM
						rcbows.water_effect(def, pos) -- water - extinguish fires

						return
					end
				end
				thing = cast:next()
			end
			if def.effects and def.effects.trail_particle then
				rcbows.trail(self.old_pos, pos, def.effects.trail_particle)
			end
			self.old_pos = pos
		end,
	})
	minetest.register_craftitem(def.inventory_arrow.name, {
		description = def.inventory_arrow.description,
		inventory_image = def.inventory_arrow.inventory_image,
		stack_max = def.stack_max or 99,
	})
end

--SOUND SYSTEM

function rcbows.make_sound(dest_type, dest, soundfile, gain, max_hear_distance)
	if dest_type == "object" then
		minetest.sound_play(soundfile, {object = dest, gain = gain or DEFAULT_GAIN, max_hear_distance = max_hear_distance or DEFAULT_MAX_HEAR_DISTANCE,})
	 elseif dest_type == "player" then
		local player_name = dest:get_player_name()
		minetest.sound_play(soundfile, {to_player = player_name, gain = gain or DEFAULT_GAIN, max_hear_distance = max_hear_distance or DEFAULT_MAX_HEAR_DISTANCE,})
	 elseif dest_type == "pos" then
		minetest.sound_play(soundfile, {pos = dest, gain = gain or DEFAULT_GAIN, max_hear_distance = max_hear_distance or DEFAULT_MAX_HEAR_DISTANCE,})
	end
end

--ARROW EFFECTS

function rcbows.boom_effect(def, pos)
	if def.effects.explosion and def.effects.explosion.mod then
		local mod_name = def.effects.explosion.mod
		if minetest.get_modpath(mod_name) ~= nil then
			if mod_name == "tnt" then
				tnt.boom(pos, {radius = def.effects.explosion.radius, damage_radius = def.effects.explosion.damage})
			elseif mod_name == "explosions" then
				explosions.explode(pos, {radius = def.effects.explosion.radius, strength = def.effects.explosion.damage})
			end
		end
	end
end

function rcbows.water_effect(def, pos)
	if def.effects.water then
		if def.effects.water.particles then
			rcbows.splash(pos, "rcbows_water.png")
		end
		local radius = def.effects.water.radius or 5
		local flames = minetest.find_nodes_in_area({x=pos.x -radius, y=pos.y -radius, z=pos.z -radius}, {x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}, {def.effects.water.flame_node})
		if flames and #flames > 0 then
			for i=1, #flames do
				minetest.set_node(flames[i], {name="air"})
				if def.effects.water.particles then
					rcbows.splash(flames[i], "rcbows_water.png")
				end
			end
		end
	end
end

--PARTICLES EFFECTS

function rcbows.trail(old_pos, pos, trail_particle)
	local texture, animation
	if type(trail_particle) == 'table' then
		texture = trail_particle.texture
		animation = trail_particle.animation
	else
		texture = trail_particle
		animation = ""
	end
    minetest.add_particlespawner({
        texture = texture,
        amount = 20,
        time = 0.2,
        minpos = old_pos,
        maxpos = pos,
        --minvel = {x=1, y=0, z=1},
        --maxvel = {x=1, y=0, z=1},
        --minacc = {x=1, y=0, z=1},
        --maxacc = {x=1, y=0, z=1},
        minexptime = 0.2,
        maxexptime = 0.5,
        minsize = 0.5,
        maxsize = 1.5,
        collisiondetection = false,
        vertical = false,
        glow = 14,
        animation = animation,
    })
end

function rcbows.splash(old_pos, splash_particle)
	minetest.add_particlespawner({
		amount = 5,
		time = 1,
		minpos = old_pos,
		maxpos = old_pos,
		minvel = {x=1, y=1, z=0},
		maxvel = {x=1, y=1, z=0},
		minacc = {x=1, y=1, z=1},
		maxacc = {x=1, y=1, z=1},
		minexptime = 0.2,
		maxexptime = 0.5,
		minsize = 1,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		texture = splash_particle,
		playername = "singleplayer"
	})
end
