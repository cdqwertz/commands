commands = {}
commands.commands = {}
commands.vars = {}

minetest.register_privilege("code", {
	description = "Player can change command blocks",
	give_to_singleplayer= false,
})

function commands.register_command(name, def)
	commands.commands[name] = def
end

function commands.run_command(text)
	if not text then return end
	if text == "" then return end
	parts = {}

	for i in text:gmatch("([^ ]+)") do
		table.insert(parts, i)
	end

	if not parts[1] then return end

	name = parts[1]
	params = {}

	if parts[2] then
		for i in parts[2]:gmatch("([^,]+)") do
			if i:find("@") == 1 then
				table.insert(params, commands.vars[i])
			else
				table.insert(params, i)
			end
		end
	end

	if not commands.commands[name] then return end
	local out = commands.commands[name].run(params)
	commands.vars["@last_output"] = out
	return out
end

function commands.activate(pos)
	local node = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
	if node and node.name ~= "air" then
		local def = minetest.registered_nodes[node.name]
		if def.on_commands_activate then
			def.on_commands_activate({x=pos.x, y=pos.y+1, z=pos.z})
		end
	end
end

function commands.get_pos(a,b,c)
	if not(a) or not(b) or not(c) then
		return
	end

	if a.is_player and a:is_player() then
		if a:getpos() then
			local v = a:getpos()
			if b == "below" then
				v.y = v.y -1
			elseif b == "above" then
				v.y = v.y + 2
			end

			return v
		end
	else
		if not(tonumber(a)) or not(tonumber(b)) or not(tonumber(c)) then
			return
		end

		return vector.new(tonumber(a),tonumber(b),tonumber(c))
	end
end

minetest.register_node("commands:code", {
	description = "Code",
	tiles = {"commands_code.png"},
	groups = {cracky = 3, commands = 1},
	sounds = default.node_sound_stone_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[text;Code:;]")
		meta:set_string("code", "")
		meta:set_string("infotext", "Empty Code Block")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if not(minetest.get_player_privs(sender:get_player_name()).code) then
			return 
		end
		
		local meta = minetest.get_meta(pos)
		if not fields.text then return end
		meta:set_string("code", fields.text)
		meta:set_string("formspec", "field[text;Code:;"..fields.text.."]")
		if fields.text == "" then
			meta:set_string("infotext", "Empty Code Block")
		else
			meta:set_string("infotext", fields.text)
		end
	end,
	on_commands_activate = function(pos)
		local meta = minetest.get_meta(pos)
		local text = meta:get_string("code")
		if not text then return end
		
		commands.run_command(text)
		commands.activate(pos)
	end,
})

minetest.register_node("commands:if", {
	description = "If",
	tiles = {"commands_if.png"},
	groups = {cracky = 3, commands = 1},
	sounds = default.node_sound_stone_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[text;Code:;]")
		meta:set_string("code", "")
		meta:set_string("infotext", "Empty If Block")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if not(minetest.get_player_privs(sender:get_player_name()).code) then
			return 
		end

		local meta = minetest.get_meta(pos)
		if not fields.text then return end
		meta:set_string("code", fields.text)
		meta:set_string("formspec", "field[text;Code:;"..fields.text.."]")
		if fields.text == "" then
			meta:set_string("infotext", "Empty If Block")
		else
			meta:set_string("infotext", fields.text)
		end
	end,
	on_commands_activate = function(pos)
		local meta = minetest.get_meta(pos)
		local text = meta:get_string("code")
		if not text then return end
		
		local output = commands.run_command(text)
		if not output then return end
		commands.activate(pos)
	end,
})

minetest.register_node("commands:timer", {
	description = "Timer",
	tiles = {"commands_timer.png"},
	groups = {cracky = 3, commands = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_abm{
	nodenames = {"commands:timer"},
	interval = 1,
	chance = 1,
	action = function(pos)
		commands.activate(pos)
	end,
}

minetest.register_node("commands:save", {
	description = "Save",
	tiles = {"commands_save.png"},
	groups = {cracky = 3, commands = 1},
	sounds = default.node_sound_stone_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[text;Name:;]")
		meta:set_string("code", "")
		meta:set_string("infotext", "Empty Save Block")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if not(minetest.get_player_privs(sender:get_player_name()).code) then
			return 
		end

		local meta = minetest.get_meta(pos)
		if not fields.text then return end
		meta:set_string("code", fields.text)
		meta:set_string("formspec", "field[text;Name;"..fields.text.."]")
		if fields.text == "" then
			meta:set_string("infotext", "Empty Save Block")
		else
			meta:set_string("infotext", fields.text)
		end
	end,

	on_commands_activate = function(pos)
		local meta = minetest.get_meta(pos)
		local text = meta:get_string("code")
		if not text then return end

		commands.vars[text] = commands.vars["@last_output"]
		commands.activate(pos)
	end,
})

minetest.register_node("commands:button", {
	description = "Button",
	tiles = {"commands_button.png"},
	groups = {cracky = 3, commands = 1},
	sounds = default.node_sound_stone_defaults(),

	on_punch = function(pos, node, player, pointed_thing)
		commands.activate(pos)
	end
})

minetest.register_node("commands:mese_detector", {
	description = "Mese Detector",
	tiles = {"commands_mese_detector.png"},
	groups = {cracky = 3, commands = 1},
	sounds = default.node_sound_stone_defaults(),

	mesecons = {effector = {
		action_on = function (pos)
			commands.activate(pos)
		end,
		action_off = function (pos)
		end
	}}
})

minetest.register_node("commands:white_tile", {
	description = "White Tile",
	tiles = {"commands_white_tile.png"},
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})


commands.register_command("print", {
	run = function(params) 
		if not params[1] then return end
		local text = params[1]
		minetest.chat_send_all(text)
		return true
	end
})

commands.register_command("time", {
	run = function(params) 
		if not params[1] then return end
		local param = params[1]
		if param == "get" then
			return minetest.get_timeofday() * 24000
		elseif param == "set" then
			if not params[2] then return end
			minetest.set_timeofday(params[2]/24000)
		else
			return
		end
	end
})

commands.register_command("tp", {
	run = function(params) 
		if not params[1] then return end
		if not params[2] then return end
		if not params[3] then return end
		local param = params[1]
		local player = minetest.get_player_by_name(params[2])
		if not player then return end
		if param == "pos" then
			if not params[4] then return end
			if not params[5] then return end
			
			local p = commands.get_pos(params[3], params[4], params[5])
			player:setpos(p)
			return true
		elseif param == "player" then
			local other = minetest.get_player_by_name(params[3])
			if not other then return end
			player:setpos(other:getpos())
			return true
		else
			return
		end
	end
})


commands.register_command("node", {
	run = function(params) 
		if not params[1] then return end
		if not params[2] then return end
		if not params[3] then return end
		if not params[4] then return end
		local param = params[1]
		if param == "get" then
			local p = commands.get_pos(params[2], params[3], params[4])
			return minetest.get_node(p).name
		elseif param == "set" then
			if not params[5] then return end
			if params[5]  == "" then return end
			if not minetest.registered_nodes[params[5]] then return end

			local p = commands.get_pos(params[2], params[3], params[4])
			minetest.set_node(p, {name=params[5]})

			return true
		elseif param == "detect" then
			if not params[5] then return end
			if params[5]  == "" then return end
			if not minetest.registered_nodes[params[5]] then return end

			local p = commands.get_pos(params[2], params[3], params[4])
			if minetest.get_node(p).name == params[5] then
				return true
			else
				return false
			end
		else
			return
		end
	end
})


commands.register_command("player", {
	run = function(params) 
		if not params[1] then return end
		if not params[2] then return end
		local action = params[1]
		
		if action == "get" then
			local p  = minetest.get_player_by_name(params[2])
			return p
		end
		
		return false
	end
})

