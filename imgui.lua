
ImguiContext = {}

function ImguiContext:new()
	local o = {}

	o.conf   = config.conf.imgui

	setmetatable(o, self)
	self.__index = self

	o.id_active = nil
	o.id_hot    = nil

	do
		--
		-- setup the frame stack
		--
		-- certain calls can modify the frame for successive calls (grouping, panels, etc.) and
		-- the previous frame should be restored once then 'aggregate' is ended.
		--
		-- note that here, frame means a rectangle defining the contents relative to the 'super'
		-- frame.
		--
		-- whenever the frame is updated, the cursor should be updated accordingly
		--
		-- anything drawn to the screen should be clipped according to the top of the frame stack
		--
		-- quite soon a frame should probably be a more complex data structure with information
		-- about padding for that frame etc.
		--
		-- perhaps I should use transforms for inheriting parent transform data but for now, simple
		-- addition works fine
		--

		o.frame_stack = {}
		table.insert(o.frame_stack, make_rect(0, 0, windowWidth, windowHeight))
	end

	do
		local f  = o.frame_stack[#o.frame_stack]
		o.cursor = makev2(f.x + o.conf.cursor_padding, f.y + o.conf.cursor_padding)

		--
		-- when moving the cursor, the # of columns must be decremented, if the # columns reaches 0
		-- then we must move the cursor to the next line
		--

		o.columns      = 1
		o.column_width = (f.w - 2 * o.conf.cursor_padding) / o.columns
	end

	o.next_id = 1

	-- input stuff
	do
		o.mouse_pressed  = false
		o.mouse_released = false
	end

	return o
end

function ImguiContext:update()
	self.mouse_pressed  = false
	self.mouse_released = false
end

-- debuggers

function ImguiContext:dump_frame_stack()
	for i, f in ipairs(self.frame_stack) do
		print(i .. ': x ' .. f.x .. ' y ' .. f.y .. ' w ' .. f.w .. ' h ' .. f.h)
	end
end

-- getters


function ImguiContext:get_frame()
	local f = self.frame_stack[#self.frame_stack]
	return make_rect(f.x, f.y, f.w, f.h)
end

function ImguiContext:get_cursor()
	return { x = self.cursor.x, y = self.cursor.y }
end

function ImguiContext:getid()
	local id = self.next_id
	self.next_id = self.next_id + 1
	return id
end

function ImguiContext:getids(n)
	local ids = {}
	for i=1,n do
		table.insert(ids, self:getid())
	end
	return ids
end

function ImguiContext:get_available_width()
	return self:get_frame().w - 2 * self.conf.cursor_padding
end

function ImguiContext:frame_push(f)
	local super_frame = self.frame_stack[#self.frame_stack]
	local actual_frame = make_rect(f.x + super_frame.x, f.y + super_frame.y, f.w, f.h)
	table.insert(self.frame_stack, actual_frame)
	self:align_cursor_to_frame()
end

function ImguiContext:frame_pop()
	if #self.frame_stack < 2 then
		logger.warn('trying to pop empty frame stack')
		return nil
	end
	local f = self.frame_stack[#self.frame_stack]
	table.remove(self.frame_stack, #self.frame_stack)
	self:align_cursor_to_frame()
	return f
end

function ImguiContext:align_cursor_to_frame()
	local f = self.frame_stack[#self.frame_stack]
	self.cursor.x = f.x + self.conf.cursor_padding
	self.cursor.y = f.y + self.conf.cursor_padding
	self.columns = 1
	self.column_width = (f.w - 2 * self.conf.cursor_padding) / self.columns
end

function ImguiContext:next_column()
	self.columns = self.columns - 1
	if self.columns == 0 then
		local f = self:get_frame()
		self.columns = 1
		self.column_width = (f.w - 2 * self.conf.cursor_padding) / self.columns
		self.cursor.y = self.cursor.y + self.conf.cursor_line_height + self.conf.cursor_padding
		self.cursor.x = f.x + self.conf.cursor_padding
	else
		self.cursor.x = self.cursor.x + self.column_width
	end
end

--
-- ImguiContext place API
--
-- 'low-level' API for building up more complex controls
--

function ImguiContext:place_dragger(id, modx, mody, x, y, w, h)
	if self.id_active == id then
		if self.drag_interaction then
			modx = love.mouse.getX() + self.drag_interaction.initial_position.x
			mody = love.mouse.getY() + self.drag_interaction.initial_position.y
		else
			logger.err('`drag_interaction` is nil, but this id is active?')
		end

		if self.mouse_released then
			self.id_active = nil
			self.drag_interaction = nil
		end
	elseif self.id_hot == id then
		if not in_rect(love.mouse.getX(), love.mouse.getY(), x, y, w, h) then
			self.id_hot = nil
		elseif self.mouse_pressed then
			self.id_hot    = nil
			self.id_active = id

			self.drag_interaction = {}
			self.drag_interaction.initial_position = { x = modx - love.mouse.getX(), y = mody - love.mouse.getY() }
		end
	else
		if in_rect(love.mouse.getX(), love.mouse.getY(), x, y, w, h) then
			self.id_hot = id
		end
	end

	if self.conf.do_debug_draw then
		renderer:push(function()
			love.graphics.setColor({ 0, 1, 0, 1 })
			love.graphics.rectangle('line', x, y, w, h)
		end)
	end

	print(modx, mody)

	return modx, mody
end

function ImguiContext:place_label(id, text, x, y, w, h)
	renderer:push(function()
		love.graphics.setColor(self.conf.text_color)
		love.graphics.printf(text, x, y, w, 'left')
	end)
end

function ImguiContext:place_button(id, text, x, y, w, h)
	local result = false

	local background_color = self.conf.button_background_color

	if self.id_active == id  then
		background_color = self.conf.button_active_background_color

		if self.mouse_released then
			result = true
			self.id_active = nil
		end
	elseif self.id_hot == id then
		background_color = self.conf.button_hot_background_color

		if not in_rect(love.mouse.getX(), love.mouse.getY(), x, y, w, h) then
			self.id_hot = nil
		elseif self.mouse_pressed then
			self.id_active = id
		end
	else
		if in_rect(love.mouse.getX(), love.mouse.getY(), x, y, w, h) then
			self.id_hot = id
		end
	end

	renderer:push(function()
		love.graphics.setColor(background_color)
		love.graphics.rectangle('fill', x, y, w, h)

		love.graphics.setColor(self.conf.text_color)
		love.graphics.printf(text, x, y, w, 'center')
	end)

	return result
end

function ImguiContext:place_selectable_button(id, selected, x, y, w, h)
	local result = false

	local background_color = self.conf.button_background_color

	if self.id_active == id  then
		background_color = self.conf.button_active_background_color

		if self.mouse_released then
			result = true
			self.id_active = nil
		end
	elseif self.id_hot == id then
		background_color = self.conf.button_hot_background_color

		if not in_rect(love.mouse.getX(), love.mouse.getY(), x, y, w, h) then
			self.id_hot = nil
		elseif self.mouse_pressed then
			self.id_active = id
		end
	else
		if in_rect(love.mouse.getX(), love.mouse.getY(), x, y, w, h) then
			self.id_hot = id
		end
	end

	if selected then
		background_color = self.conf.button_hot_background_color
	end

	renderer:push(function()
		love.graphics.setColor(background_color)
		love.graphics.rectangle('fill', x, y, w, h)

		-- love.graphics.setColor(self.conf.text_color)
		-- love.graphics.printf(text, x, y, w, 'center')
	end)

	return result
end

function ImguiContext:place_input_field(id, x, y, w, h)
	renderer:push(function()
		love.graphics.setColor(self.conf.input_field_background_color)
		love.graphics.rectangle('fill', x, y, w, h)

		love.graphics.setColor(self.conf.input_field_border_color)
		love.graphics.rectangle('line', x, y, w, h)
	end)
end

--
-- ImguiContext API
--

function ImguiContext:space()
	self:next_column()
end

function ImguiContext:label(id, text)
	local c = self:get_cursor()
	local w = self:get_available_width()

	self:place_label(id, text, c.x, c.y, w, self.conf.cursor_line_height)

	self:next_column()
end

function ImguiContext:button(id, text)
	local c = self:get_cursor()
	local w = self:get_available_width()

	self:place_button(id, text, c.x, c.y, w, self.conf.cursor_line_height)

	self:next_column()
end

function ImguiContext:input_field(text)
	local c = self:get_cursor()
	local w = self:get_available_width()

	self:place_input_field(id, c.x, c.y, w, self.conf.cursor_line_height)

	self:next_column()

	return text
end

function ImguiContext:panel_begin(is_open, x, y, title)
	local f = make_rect(x, y, self.conf.panel_width, self.conf.panel_height)

	self:frame_push(f)

	local f = self:get_frame()

	if not is_open then
		return is_open, f.x, f.y
	end

	local fc = DeepCopy(f)
	renderer:push(function()
		local f = fc
		love.graphics.setScissor(f.x, f.y, f.w, f.h)

		love.graphics.setColor(self.conf.panel_background_color)
		love.graphics.rectangle('fill', f.x, f.y, f.w, f.h)

		love.graphics.setColor(self.conf.panel_title_bar_background_color)
		love.graphics.rectangle('fill', f.x, f.y, f.w, self.conf.panel_title_bar_height)

		-- title bar title
		love.graphics.setColor({ 1, 1, 1, 1 })
		love.graphics.printf(title or 'Untitled', f.x + 2, f.y + 2, f.w, 'left')

		-- panel border
		love.graphics.setColor(self.conf.panel_border_color)
		love.graphics.rectangle('line', f.x, f.y, f.w, f.h)
	end)

	-- title bar
	do
		local dim = self.conf.panel_title_bar_height - 2*self.conf.panel_title_bar_padding
		local p   = self.conf.panel_title_bar_padding
		if self:place_button(-100, '', f.x + f.w - dim - p, f.y + p, dim, dim) then
			is_open = false
		end

		f.x, f.y = self:place_dragger(-500, f.x, f.y, f.x, f.y, f.w-self.conf.panel_title_bar_height, self.conf.panel_title_bar_height)
	end

	do
		local clientf = make_rect(
			0,
			self.conf.panel_title_bar_height + self.conf.cursor_padding,
			f.w,
			f.h - self.conf.panel_title_bar_height - self.conf.cursor_padding)

		self:frame_push(clientf)
	end

	return is_open, f.x, f.y
end

function ImguiContext:panel_end(is_open)
	if not is_open then
		return
	end

	renderer:push(function()
		love.graphics.setScissor()
	end)

	self:frame_pop() -- client area
	self:frame_pop() -- panel
end
