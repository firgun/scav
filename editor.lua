
editor = {}

ui = ImguiContext:new()

local id_test_button = ui:getid()
local id_real_button = ui:getid()
local id_label       = ui:getid()
local wedge_id       = ui:getid()
local button_ids     = ui:getids(10)

editor.p_x = 100
editor.p_y = 100
editor.is_open = true
editor.selected_actor_id = nil

function editor.update()
	do_picking()
	
	do_tool_selection_menu_thing()
	
	do_test_panel()
	
	ui:update()
end

function do_test_panel()
	local was_open = editor.is_open
	editor.is_open, editor.p_x, editor.p_y = ui:panel_begin(editor.is_open, editor.p_x, editor.p_y, 'Super Panel')
	if editor.is_open then
		ui:label(id_label, 'Label')

		if ui:button(id_test_button, 'Button') then
			print('hello, world')
		end
		for i=1,10 do
			if ui:button(button_ids[i], 'Button') then
			end
			local text = ui:input_field('Hello, World')
			ui:space()
		end
	end
	ui:panel_end(was_open)
end

function draw_wedge(ox, oy, rx, ry, color)
	local d   = 25
	local off = 20
	love.graphics.setColor(color_with_alpha(color, 0.6))
	love.graphics.rectangle('fill', ox + off, oy - d - off, d, d)
	love.graphics.setColor(color)
	love.graphics.rectangle('line', ox + off, oy - d - off, d, d)
end

function draw_arrow(ox, oy, dx, dy, color)
	love.graphics.setColor(color)
	local tx, ty = ox + dx, oy + dy
	love.graphics.line(ox, oy, tx, ty)
	local px, py = normalize(dy, -dx)
	local arrow_head_perp_extents = 7
	local p1x, p1y = px * arrow_head_perp_extents, py * arrow_head_perp_extents
	local p2x, p2y = -p1x, -p1y
	-- the tip, hehe
	local arrow_head_length = 20
	local p3x, p3y = normalize(dx, dy)
	local p3x, p3y = p3x * arrow_head_length, p3y * arrow_head_length
	love.graphics.polygon(
		'fill',
		tx + p1x, ty + p1y,
		tx + p2x, ty + p2y,
		tx + p3x, ty + p3y)
end

function screen_to_world(x, y)
	local _, cam_transform = xfind(world.mainCameraId, 'transform')
	local t = transformation.world_view_window(cam_transform, windowWidth, windowHeight)
	x, y = t:inverse():transformPoint(x, y)
	return x, y
end

function do_picking()
	local x, y = screen_to_world(love.mouse.getX(), love.mouse.getY())

	gizmo.push_rect({ x = x, y = y })

	for _, a in ipairs(world.actors) do
		local b = get_actor_bounds(a)
		if b then
			gizmo.push_rect({ x = b.x + 0.5, y = b.y - 0.5})
		end
		if b and in_rect(x, y, b.x, b.y, b.w, b.h) then
			editor.selected_actor_id = a.id
		end
	end
end

-- actor manipulation tools

editor.uiid_select_translate = ui:getid()
editor.uiid_select_rotate    = ui:getid()
editor.uiid_select_scale     = ui:getid()
editor.uiid_toggle_space     = ui:getid()

editor.are_tools_world_space = false

editor.uiid_tools = {}
table.insert(editor.uiid_tools, editor.uiid_select_translate)
table.insert(editor.uiid_tools, editor.uiid_select_rotate   )
table.insert(editor.uiid_tools, editor.uiid_select_scale    )

function do_tool_selection_menu_thing()
	local x, y = 20, 20
	local d    = 20

	for _, uiid in pairs(editor.uiid_tools) do
		local selected = editor.uiid_selected_tool == uiid
		if ui:place_selectable_button(uiid, editor.uiid_selected_tool == uiid, x, y, d, d) then
			if selected then
				editor.uiid_selected_tool = nil
			else
				editor.uiid_selected_tool = uiid
			end
		end
		x = x + d
	end

	x = x + 10

	if ui:place_button(editor.uiid_toggle_space, editor.are_tools_world_space and 'world' or 'local', x, y, 45, d) then
		editor.are_tools_world_space = not editor.are_tools_world_space
	end

	if editor.selected_actor_id and editor.uiid_selected_tool then
		local uiid_tool = editor.uiid_selected_tool
		    if uiid_tool == editor.uiid_select_translate then do_actor_tool_translate()
		elseif uiid_tool == editor.uiid_select_rotate    then do_actor_tool_rotate   ()
		elseif uiid_tool == editor.uiid_select_scale     then do_actor_tool_scale    ()
		end
	end
end

function do_actor_tool_translate()
	if not editor.selected_actor_id then
		return
	end

	if editor.selected_actor_id then
		local _, cam_transform   = xfind(world.mainCameraId, 'transform')
		local _, actor_transform = xfind(editor.selected_actor_id , 'transform')

		local wvw = transformation.world_view_window(cam_transform, windowWidth, windowHeight)
		local ow  = transformation.object_world(actor_transform)

		local t = wvw * ow

		local cx, cy = t:transformPoint(0, 0)
		local ux, uy = t:transformPoint(0, 1)
		local rx, ry = t:transformPoint(1, 0)

		local ux, uy = normalize(ux - cx, uy - cy)
		local rx, ry = normalize(rx - cx, ry - cy)

		local arrow_length = 100

		local ux, uy = ux * arrow_length, uy * arrow_length
		local rx, ry = rx * arrow_length, ry * arrow_length

		do
			local d = 25
			local new_x, new_y = ui:place_dragger(wedge_id, cx, cy, cx + 20, cy - d - 20, d, d)

			new_x, new_y = wvw:inverse():transformPoint(new_x, new_y)

			gizmo.push_rect({ x = new_x, y = new_y })

			actor_transform.position.x = new_x
			actor_transform.position.y = new_y
		end

		renderer:push(function()
			love.graphics.setLineWidth(1.5)
			draw_wedge(cx, cy, rx, ry, color.white)
			draw_arrow(cx, cy, ux, uy, color_with_alpha(color.red  , 1.0))
			draw_arrow(cx, cy, rx, ry, color_with_alpha(color.green, 0.8))
		end)
	end
end

function do_actor_tool_rotate()
	
end

function do_actor_tool_scale()
	
end
