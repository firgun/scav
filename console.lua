

--
-- todo list
-- ===
-- * implement the console command context thingy
--

Console = {}

function Console:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.conf = config.conf

	o.command_context = {}

	o.max_lines    = 300
	o.lines        = {}

	o.input_buffer  = nil
	o.cursor        = 0

	o:set_input_buffer('')

	o.history = {}
	o.history_index = 0

	o.x      = 0
	o.y      = -windowHeight
	o.width  =  windowWidth
	o.height =  windowHeight

	o.openness        = 0
	o.recieving_input = false

	o.font = love.graphics.newFont('data/fonts/Inconsolata-Regular.ttf', 16)

	-- scroll vars

	o.scroll_target = 0
	o.scroll_offset = 0

	-- cursor animation vars

	o.running_time  = 0
	o.cursor_alpha  = 1

	-- suggestion
	
	self.suggestion = nil

	return o
end

function Console:bind(key, value)
	if self.command_context[key] then
		logger.warn('overwriting console command, is this correct?')
	end
	self.command_context[key] = value
end

function Console:set_input_buffer(input_buffer)
	self.input_buffer = input_buffer
	self:setcursor(#self.input_buffer+1)
end

function Console:lineheight()
	return self.font:getHeight() + self.conf.CONSOLE_PADDING_VERTICAL * 2
end

function Console:type(text)
	if not self.recieving_input then
		return
	end

	-- @HACK(keagan): figure out how modifiers work
	if text == '`' then
		return
	end

	local b = self.input_buffer
	self.input_buffer = string.sub(b, 1, self.cursor-1) .. text .. string.sub(b, self.cursor)

	self:move(#text)
end

function Console:writeline(text)
	-- TODO(keagan) memory leak
	table.insert(self.lines, text)
	self.scroll_offset = self.scroll_offset + self:lineheight()
end

function Console:write(text)
	-- TODO(keagan): implement this properly
	self:writeline(text)
end

function Console:ret()
	if not self.input_buffer or #self.input_buffer == 0 then
		return
	end
	
	self:writeline(self.input_buffer)

	--
	-- execute command
	--

	local fn, err = loadstring(self.input_buffer)
	if err then
		self:writeline(err)
	else
		local status, result = pcall(fn)
		if result then
			self:writeline(tostring(result))
		end
	end

	--
	-- flush input buffer and update history
	--

	table.insert(self.history, self.input_buffer)
	self.history_index = 0
	self:set_input_buffer('')
end

function Console:backspace()
	if self.cursor > 0 then
		local input_buffer = string.sub(self.input_buffer, 1, self.cursor-2) .. string.sub(self.input_buffer, self.cursor, #self.input_buffer)
		self.input_buffer = input_buffer
		self:move(-1)
	end
end

function Console:setcursor(pos)
	self.cursor       = clamp(pos, 1, #self.input_buffer+1)
	self.running_time = math.pi/2
end

function Console:move(offset)
	self:setcursor(self.cursor+offset)
end

function Console:close()
	self.recieving_input = false
	self.openness        = 0
end

function Console:open()
	self.recieving_input = true
	self.openness        = 0.45
end

function Console:toggle()
	if self.recieving_input then
		self:close()
	else
		self:open()
	end
end

function Console:cycle(offset)
	self.history_index = clamp(self.history_index + offset, 0, #self.history)
	local contents = ''
	if self.history_index > 0 then
		contents = self.history[#self.history+1-self.history_index]
	end
	self:set_input_buffer(contents)
end

function Console:take_suggestion()
	if self.suggestion then
		self:set_input_buffer(self.suggestion)
	end
end

function Console:clear()
	self.lines = {}
end

function Console:update(dt)
	self.running_time = self.running_time + dt

	function move_to_target(cur, targ, speed, dt)
		if cur < targ then
			cur = cur + speed * dt
			if targ > targ then
				targ = targ
			end
		elseif cur > targ then
			cur = cur - speed * dt
			if cur < targ then
				cur = targ
			end
		end
		return cur
	end
	
	local y_target = windowHeight * self.openness - windowHeight
	self.y = move_to_target(self.y, y_target, self.conf.CONSOLE_SPEED_OPEN, dt)

	local actual_scroll_speed = self.conf.CONSOLE_SPEED_SCROLL * self.scroll_offset / self:lineheight()
	self.scroll_offset = move_to_target(self.scroll_offset, self.scroll_target, actual_scroll_speed, dt)

	self.cursor_alpha = math.sin(self.running_time * self.conf.CONSOLE_SPEED_BLINK)

	--
	-- update search suggestion
	--

	do
		local found = false
		for k, v in pairs(_G) do
			-- TODO(keagan): this is a hack, I need an regex escaping function
			local status, result = pcall(function()
				return string.find(k, self.input_buffer)
			end)
			if status and result == 1 then
				if #self.input_buffer > 0 then
					found = true
					self.suggestion = k
					break
				end
			end
		end
		if not found then
			self.suggestion = nil
		end
	end
end

function Console:draw()
	love.graphics.setColor(self.conf.CONSOLE_INPUT_BGCOL)
	love.graphics.rectangle('fill', self.x, self.y + self.height - self:lineheight(), self.width, self:lineheight())

	local vpadding = self.conf.CONSOLE_PADDING_VERTICAL
	local hpadding = self.conf.CONSOLE_PADDING_HORIZONTAL

	local cx = self.x							       + hpadding
	local cy = self.y + self.height - self:lineheight() + vpadding

	--
	-- draw input buffer
	--

	do
		local cursx = self.x + hpadding
		local cursy = self.y + vpadding + self.height - self:lineheight()

		local cwidth  = 10
		local cheight = self:lineheight() - vpadding * 2

		-- TODO(keagan): utf8 hazard

		local input_buffer = self.conf.CONSOLE_PROMPT .. self.input_buffer

		if self.input_buffer and #input_buffer > 0 then
			if self.cursor <= #self.input_buffer then
				cwidth = self.font:getWidth(string.sub(input_buffer, self.cursor, self.cursor))
			end
			cursx  = cursx + self.font:getWidth(string.sub(input_buffer, 1, #self.conf.CONSOLE_PROMPT+self.cursor-1))
		end
	
		love.graphics.setColor(color_with_alpha(self.conf.CONSOLE_CURSOR_COLOR, self.cursor_alpha))
		love.graphics.rectangle('fill', cursx, cursy, cwidth, cheight)

		love.graphics.setFont(self.font)

		if self.suggestion then
			love.graphics.setColor(color_with_alpha(self.conf.CONSOLE_INPUT_FGCOL, 0.2))
			love.graphics.print(self.suggestion, cx + self.font:getWidth(self.conf.CONSOLE_PROMPT), cy)
		end

		love.graphics.setColor(self.conf.CONSOLE_INPUT_FGCOL)
		love.graphics.print(input_buffer, cx, cy)

	end

	--
	-- draw console contents
	--

	do
		cy = cy - self:lineheight() + self.scroll_offset

		love.graphics.setScissor(self.x, self.y, self.width, self.height-self:lineheight())

		local i = #self.lines
		while cy + self:lineheight() > 0 do
			local background_color = (#self.lines+1-i)%2 == 0
				and self.conf.CONSOLE_BGCOL_ON or self.conf.CONSOLE_BGCOL_OFF

			love.graphics.setColor(background_color)
			love.graphics.rectangle('fill', cx - hpadding, cy - vpadding, self.width, self:lineheight())

			if i >= 1 then
				love.graphics.setColor(self.conf.CONSOLE_FGCOL)
				love.graphics.print(self.lines[i], cx, cy)
			end

			cy = cy - self:lineheight()
			i  = i - 1
		end
	end

	love.graphics.setScissor()
end

-- exported module api

default_console = Console:new()

console = {}

function console.update   (dt)  default_console:update   (dt)  end
function console.draw     ()    default_console:draw     ()    end
function console.toggle   ()    default_console:toggle   ()    end
function console.type     (t)   default_console:type     (t)   end
function console.backspace()    default_console:backspace()    end
function console.move     (off) default_console:move     (off) end
function console.ret      ()    default_console:ret      ()    end
function console.cycle    (off) default_console:cycle    (off) end

function console.take_suggestion() default_console:take_suggestion() end