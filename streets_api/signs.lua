streets.signs = {}

streets.signs.registered_collections = {}
streets.signs.registered_sections = {}
streets.signs.registered_signs = {}

streets.signs.build_node_name = function(belongs_to, name, variation, omit_colon)
	local node_name = ""
	if not omit_colon then
		node_name = node_name .. ":"
	end
	node_name = node_name .. "streets:signs_" .. belongs_to:gsub(":", "__") .. "__" .. name
	if variation then
		node_name = node_name .. "__" .. variation
	end
	return node_name
end

streets.signs.build_texture_name = function(belongs_to, name)
	return "streets_signs_" .. belongs_to:gsub(":", "__") .. "__" .. name .. ".png"
end

streets.signs.register_collection = function(def)
	streets.signs.registered_collections[def.name] = def
end


streets.signs.register_section = function(def)
	streets.signs.registered_sections[def.belongs_to .. ":" .. def.name] = def
end

local signs_after_place = function(pos, placer, itemstack, pointed_thing)
	local behind_pos = { x = pos.x, y = pos.y, z = pos.z }
	local node = minetest.get_node(pos)
	local param2 = node.param2
	if param2 == 0 then
		behind_pos.z = behind_pos.z + 1
	elseif param2 == 1 then
		behind_pos.x = behind_pos.x + 1
	elseif param2 == 2 then
		behind_pos.z = behind_pos.z - 1
	elseif param2 == 3 then
		behind_pos.x = behind_pos.x - 1
	end
	local behind_node = minetest.get_node(behind_pos)
	if minetest.registered_nodes[behind_node.name]
			and minetest.registered_nodes[behind_node.name].buildable_to
			and pointed_thing.type == "node" then
		behind_pos = pointed_thing.under
		behind_node = minetest.get_node(behind_pos)
	end
	if not minetest.registered_nodes[behind_node.name] then
		return
	end
	local behind_nodes = {}
	behind_nodes["streets:concrete_wall"] = true
	behind_nodes["streets:concrete_wall_top"] = true
	behind_nodes["technic:concrete_post"] = true
	behind_nodes["default:fence_acacia_wood"] = true
	behind_nodes["default:fence_aspen_wood"] = true
	behind_nodes["default:fence_junglewood"] = true
	behind_nodes["default:fence_pine_wood"] = true
	behind_nodes["default:fence_wood"] = true
	behind_nodes["default:mese_post_light"] = true
	local behind_nodes_same_parity = {}
	behind_nodes_same_parity["streets:concrete_wall_straight"] = true
	behind_nodes_same_parity["streets:concrete_wall_top_straight"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_type_1_left"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_type_1_right"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_type_2_left"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_type_2_right"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_type_3_left"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_type_3_right"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_direction_left"] = true
	behind_nodes_same_parity["streets:roadwork_us_barricade_direction_right"] = true
	if (minetest.registered_nodes[behind_node.name].groups.bigpole
			and minetest.registered_nodes[behind_node.name].streets_pole_connection[param2][behind_node.param2 + 1] ~= 1)
			or behind_nodes[behind_node.name] == true
			or (behind_nodes_same_parity[behind_node.name] and (behind_node.param2 + param2) % 2 == 0) then
		node.name = node.name .. "__polemounted"
		minetest.set_node(pos, node)
	end
end

streets.signs.register_sign = function(def)
	streets.signs.registered_signs[def.belongs_to .. ":" .. def.name] = def
	local d = table.copy(def)
	local style = d.style
	if style == "box" then
		d.drawtype = "nodebox"
		d.tiles = d.tiles or {
			"streets_signs_back.png",
			"streets_signs_back.png",
			"streets_signs_back.png",
			"streets_signs_back.png",
			"streets_signs_back.png",
			d.tex or streets.signs.build_texture_name(def.belongs_to, def.name)
		}
		d.size = d.size or {-0.5, -0.5, 0.5, 0.5 }
	elseif style == "flat" then
		d.drawtype = "mesh"
		d.tiles = d.tiles or {
			{
				name = d.tex or streets.signs.build_texture_name(def.belongs_to, def.name),
				backface_culling = true
			},
			{
				name = (d.tex or streets.signs.build_texture_name(def.belongs_to, def.name))
						.. "^[colorize:#fff^[mask:("
						.. (d.tex or streets.signs.build_texture_name(def.belongs_to, def.name))
						.. "^streets_signs_back.png)^[transformFX",
				backface_culling = true,
			},
		}
		d.size = d.size or 1
	end
	d.description = d.description or string.gsub(" " .. d.name:gsub("_", " "), "%W%l", string.upper):sub(2)
	d.inventory_image = d.inventory_image or d.tiles[6] and d.tiles[6] or d.tex and d.tex or streets.signs.build_texture_name(def.belongs_to, def.name)
	d.paramtype = d.paramtype or "light"
	d.paramtype2 = d.paramtype2 or "facedir"
	d.light_source = d.light_source or 3
	d.groups = d.groups or { sign = 1, snappy = 2, dig_immediate = 2, --[[not_in_creative_inventory = 1,]] }
	d.groups.streets_sign = 1
	d.streets = {
		category = "sign",
		belongs_to = def.belongs_to,
		name = def.belongs_to,
	}
	d.sounds = d.sounds or default and default.node_sound_metal_defaults()
	d.drop = streets.signs.build_node_name(def.belongs_to, def.name, nil, true)
	local old_on_construct = d.on_construct
	d.on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", d.description)
		if old_on_construct then
			old_on_construct(pos)
		end
	end
	if d.display_entities and font_api and display_api and signs_api then
		d.groups.display_modpack_node = 1
	end
	local normal_def = table.copy(d)
	normal_def.after_place_node = signs_after_place
	local polemounted_def = table.copy(d)
	polemounted_def.description = polemounted_def.description .. " (Pole-Mounted)"
	polemounted_def.groups.not_in_creative_inventory = 1
	polemounted_def.streets.variation = "polemounted"
	if style == "box" then
		normal_def.node_box = {
			type = "fixed",
			fixed = { d.size[1], d.size[2], 0.5, d.size[3], d.size[4], 0.45 }
		}
		polemounted_def.node_box = {
			type = "fixed",
			fixed = { d.size[1], d.size[2], 0.8, d.size[3], d.size[4], 0.85 }
		}

		if d.display_entities and font_api and display_api and signs_api then
			for k,v in pairs(normal_def.display_entities) do
				v.depth = 0.45 - display_lib.entity_spacing
				polemounted_def.display_entities[k].depth = 0.8 - display_lib.entity_spacing
			end
		end
	elseif style == "flat" then
		normal_def.mesh = "streets_signs_flat_" .. normal_def.size .. ".obj"
		polemounted_def.mesh = "streets_signs_flat_" .. polemounted_def.size .. "_polemounted.obj"

		if d.display_entities and font_api and display_api and signs_api then
			for k,v in pairs(normal_def.display_entities) do
				v.depth = 0.5 - display_lib.entity_spacing
				polemounted_def.display_entities[k].depth = 0.85 - display_lib.entity_spacing
			end
		end

		d.box = d.box or {-d.size / 2, -d.size / 2, d.size / 2, d.size / 2}
		
		local normal_box = { d.box[1], d.box[2], 0.5, d.box[3], d.box[4], 0.45 }
		local polemounted_box = { d.box[1], d.box[2], 0.8, d.box[3], d.box[4], 0.85 }

		normal_def.selection_box = {
			type = "fixed",
			fixed = normal_box
		}
		normal_def.collision_box = {
			type = "fixed",
			fixed = normal_box
		}
		polemounted_def.selection_box = {
			type = "fixed",
			fixed = polemounted_box
		}

		polemounted_def.collision_box = {
			type = "fixed",
			fixed = polemounted_box
		}
	end
	minetest.register_node(streets.signs.build_node_name(def.belongs_to, def.name), normal_def)
	minetest.register_node(streets.signs.build_node_name(def.belongs_to, def.name, "polemounted"), polemounted_def)
end


streets.signs.get_collection_definition = function(name)
	local def = streets.signs.registered_collections[name]
	if type(def) == "table" then
		return table.copy(def)
	else
		return nil
	end
end

streets.signs.get_section_definition = function(name)
	local def = streets.signs.registered_sections[name]
	if type(def) == "table" then
		return table.copy(def)
	else
		return nil
	end
end

streets.signs.get_sign_definition = function(name)
	local def = streets.signs.registered_signs[name]
	if type(def) == "table" then
		return table.copy(def)
	else
		return nil
	end
end

streets.signs.get_section_definitions_by_collection = function(name)
	local definitions = {}
	for k, v in pairs(streets.signs.registered_sections) do
		if v.belongs_to == name then
			definitions[k] = table.copy(v)
		end
	end
	return definitions
end

streets.signs.get_sign_definitions_by_collection = function(name)
	local definitions = {}
	for k, v in pairs(streets.signs.registered_signs) do
		if v.belongs_to:find(name) == 1 then
			definitions[k] = table.copy(v)
		end
	end
	return definitions
end

streets.signs.get_sign_definitions_by_section = function(name)
	local definitions = {}
	for k, v in pairs(streets.signs.registered_signs) do
		if v.belongs_to == name then
			definitions[k] = table.copy(v)
		end
	end
	return definitions
end