

transformation = {}

function transformation.view_window(w, h)
	local r = w / h
	local t = love.math.newTransform()
	t:translate(w/2,  h/2)
	t:scale    (w/2, -h/2)
	t:scale    (1/r, 1)
	return t
end

function transformation.world_view(transform)
	local t = love.math.newTransform()
	t:scale    (1/transform.scale, 1/transform.scale)
	t:rotate   (-transform.rotation)
	t:translate(-transform.position.x, -transform.position.y)
	return t
end

function transformation.object_world(transform)
	local t = love.math.newTransform()
	t:translate(transform.position.x, transform.position.y)
	t:scale    (transform.scale     , transform.scale     )
	t:rotate   (transform.rotation                        )
	return t
end

function transformation.local_parent(transform, parent)
	local t = transformation.object_world(transform)
	if parent then
		local t_parent = transformation.object_world(parent)
		t = t_parent * t
	end
	return t
end

function transformation.object_world_view_window(transform, camera_transform,  window_width, window_height)
	local vw = transformation.view_window   (window_width, window_height)
	local wv = transformation.world_view    (camera_transform)
	local ow = transformation.object_world  (transform)
	return vw * wv * ow
end

function transformation.world_view_window(transform, window_width, window_height)
	local vw = transformation.view_window(window_width, window_height)
	local wv = transformation.world_view (transform)
	return vw * wv
end

--- Experimental renderer, currently only used for rendering im gui stuff

--
-- The idea is, to avoid command buffers and creating more ideas, just pass a function to the render something
-- in a particular layer, the renderer can then do sorting and render at the appropriate time!
--
-- that way we can write rendering code anywhere, just tag it and it'll, for the most part, be as easy as
-- pure immediate mode.
--

Renderer = {}

function Renderer:new()
	local o = {}
	
	setmetatable(o, self)
	self.__index = self

	o.drawfuncs = {}

	return o
end

function Renderer:push(fn)
	table.insert(self.drawfuncs, fn)
end

function Renderer:draw()
	for _, fn in ipairs(self.drawfuncs) do
		fn()
	end
	self.drawfuncs = {}
end

renderer = Renderer:new()