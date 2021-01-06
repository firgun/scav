behaviourtab = {}

Stage = {
	update = 1,
	render = 2,
}

for k, v in pairs(Stage) do
	behaviourtab[v] = {}
end

local behavioursteps = {
	'awake',
	'update',
	'enable',
	'disable',
	'destroy',
}

function resetbehaviours()
	for _, stage in pairs(Stage) do
		for _, b in pairs(behaviourtab[stage]) do
			b:invalidatecache()
		end
	end
end

function dobehaviours(stage)
	assert(stage == Stage.update or stage == Stage.render, 'invalid stage id: ' .. stage)
	for bname, b in pairs(behaviourtab[stage]) do
		b:buildcache_if_needed()
		b:on_stagebegin()
		for _, actor in pairs(b.cache.actors) do
			local tag = actor.behaviours[bname]
			b.actor = actor
			b.ctx = b.cache.dependencies[actor.id]
			for _, step in pairs(behavioursteps) do
				if tag.should[step] then
					b['on_' .. step](b)
					if step ~= 'update' then
						tag.should[step] = false
					end
				end
			end
		end
		b:on_stageend()
	end
end

function getbehaviourtag(behaviourname)
	assert(behaviourtab[Stage.update][behaviourname] or behaviourtab[Stage.render][behaviourname], 'unknown behaviour: ' .. behaviourname)
	local behaviourtag = {}
	behaviourtag.should = {}
	behaviourtag.should.awake   = true
	behaviourtag.should.enable  = true
	behaviourtag.should.update  = true
	behaviourtag.should.disable = false
	behaviourtag.should.destroy = false
	return behaviourtag
end

function setbehaviour_enabled(actor, name, enabled)
	local tag = actor.behaviours[name] or actor.behaviours[name]
	if tag and enabled ~= tag.should.update then
		tag.should.enable  =     enabled
		tag.should.update  =     enabled
		tag.should.disable = not enabled
	else
		logger.err('bad behaviour name "' .. name .. '"')
	end
end

function setbehaviour_disabled(actor, name, disabled)
	setbehaviour_enabled(actor, name, not disabled)
end

function getbehaviour(behaviourname)
	for _, stage in pairs(Stage) do
		if behaviourtab[stage][behaviourname] then
			return behaviourtab[stage][behaviourname]
		end
	end
	return nil
end

function addbehaviour(actor, behaviourname)
	local behaviour = getbehaviour(behaviourname)
	assert(behaviour)
	behaviour:invalidatecache() -- TODO(keagan): temp fix, handle caching more delicately I think

	local behaviourtag = getbehaviourtag(behaviourname)
	actor.behaviours[behaviourname] = behaviourtag
	return behaviourtag
end

--
-- MARK: behaviour, base class definition
--

Behaviour = {}

function Behaviour:new(name, stage)
	assert(stage == Stage.update or stage == Stage.render)

	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.name = name
	if behaviourtab[stage][name] then
		logger.err('trying to register multiple behaviours under same name: ' .. name)
	else
		behaviourtab[stage][name] = o
		logger.info('registered new behaviour: ' .. name)
	end

	o.meta = {}
	o.meta.dependencies = {}

	o:require('transform')

	o.ctx  = {}

	o.cache = nil

	return o
end

function Behaviour:clearcache     () self.cache = nil  end
function Behaviour:invalidatecache() self:clearcache() end

function Behaviour:buildcache()
	self:clearcache()
	self.cache = {}
	self.cache.actors = {}
	self.cache.dependencies = {}
	for _, actor in pairs(world.actors) do
		if actor and actor.behaviours[self.name] then
			table.insert(self.cache.actors, actor)
			self.cache.dependencies[actor.id] = {}
			for _, dependency in pairs(self.meta.dependencies) do
				local _, comp = xfind(actor, dependency)
				if comp then
					self.cache.dependencies[actor.id][dependency] = comp
				else
					logger.err('failed to find dependency: ' .. dependency .. ' on actor with id ' .. actor.id)
				end
			end
		end
		if not actor then
			logger.err('failed to find actor with id: ' .. actor.id)
		end
	end
end

function Behaviour:buildcache_if_needed()
	if not self.cache then
		self:buildcache()
	end
end

function Behaviour:require(component_type)
	if iscomponent(component_type) then
		table.insert(self.meta.dependencies, component_type)
	else
		logger.error('required component: ' .. component_type .. ' not found')
	end
end

function Behaviour:on_stagebegin  () end
function Behaviour:on_stageend    () end
function Behaviour:on_awake       () end
function Behaviour:on_update      () end
function Behaviour:on_destroy     () end
function Behaviour:on_enable      () end
function Behaviour:on_disable     () end
function Behaviour:on_editorupdate() end
function Behaviour:on_drawgizmos  () end

--
-- MARK: update behaviours
--

worldbasesaver = Behaviour:new('worldbasesaver', Stage.update)

function worldbasesaver:on_update()
	if love.keyboard.isDown('o') then
		SaveWorld()
	end

	if love.keyboard.isDown('p') then
		initworld()
		resetbehaviours()
	end
end

tilemap_builder = Behaviour:new('tilemap_builder', Stage.update)
tilemap_builder:require('tile_map')

function tilemap_builder:on_awake()
	logger.info('building tile map')
	local transform = self.ctx.transform
	local tilemap   = self.ctx.tile_map

	for i=1, tilemap.numchunksy do
		for j=1, tilemap.numchunksx do
			local actor = CreateEmptyActor()
			local chunk = addcomponent(actor, 'tile_map_chunk')
			addbehaviour(actor, 'tilemap_chunkbuilder')

			local _, t, c = xfind(actor, 'transform', 'tile_map_chunk')

			t.position.x = (j-1) * tilemap.chunkcols
			t.position.y = (i-1) * tilemap.chunkrows

			c.rows = tilemap.chunkrows
			c.cols = tilemap.chunkcols

			table.insert(tilemap.chunkActorIds, actor.id)
			tilemap.chunksbyindex[{ j-1, i-1 }] = actor.id
			tilemap.chunksbyindex[(i-1)*tilemap.numchunksx+(j-1)] = actor.id

			SpawnActor(actor)
		end
	end
end


tilemap_chunkbuilder = Behaviour:new('tilemap_chunkbuilder', Stage.update)
tilemap_chunkbuilder:require('tile_map_chunk')

function tilemap_chunkbuilder:on_awake()
	local chunk     = self.ctx.tile_map_chunk
	local transform = self.ctx.transform

	chunk.bounds = {}
	chunk.bounds.min = { x = transform.position.x             , y = transform.position.y              }
	chunk.bounds.max = { x = transform.position.x + chunk.cols, y = transform.position.y + chunk.rows }

	for i=1, chunk.rows do
		for j=1, chunk.cols do
			local tile = CreateEmptyActor()
			local d = addcomponent(tile, 'drawable')
			addbehaviour(tile, 'draw')

			d.color = GetTileColor(chunk, i, j)
						
			local _, t = xfind(tile, 'transform')

			t.position.x = transform.position.x + (j-1)
			t.position.y = transform.position.y + (i-1)

			SpawnActor(tile)

			table.insert(chunk.tileActorIds, tile.id)

			d.opacity = 0.2
		end
	end
end


character_controller = Behaviour:new('character_controller', Stage.update)

function character_controller:on_update()
	local transform = self.ctx.transform
	local j = love.joystick.getJoysticks()[1]
	if j then
		transform.position.x = transform.position.x +  j:getAxis(1) / 20 * 2
		transform.position.y = transform.position.y + -j:getAxis(2) / 20 * 2
	end

	if love.keyboard.isDown('space') then
		transform.rotation = transform.rotation + 0.01
	end

	gizmo.push_rect(transform.position)
end

editor_camera_controller = Behaviour:new('editor_camera_controller', Stage.update)
editor_camera_controller:require('camera')

function editor_camera_controller:on_update()
	local camera    = self.ctx.camera
	local transform = self.ctx.transform

	local cameraMoveSpeed = 2 / camera.zoom
	local cameraMoveAmount = cameraMoveSpeed * 1/60
	local zoomSpeed = 1.0 * camera.zoom
	local zoomAmount = zoomSpeed * 1/60

	if love.keyboard.isDown('q') then
		camera.zoom = camera.zoom + zoomAmount
	end

	if love.keyboard.isDown('a') then
		camera.zoom = camera.zoom - zoomAmount
	end

	if love.keyboard.isDown('down') then
		transform.position.y = transform.position.y - cameraMoveAmount
	end

	if love.keyboard.isDown('up') then
		transform.position.y = transform.position.y + cameraMoveAmount
	end

	if love.keyboard.isDown('left') then
		transform.position.x = transform.position.x - cameraMoveAmount
	end

	if love.keyboard.isDown('right') then
		transform.position.x = transform.position.x + cameraMoveAmount
	end

	transform.scale = 1/camera.zoom
end

draw = Behaviour:new('draw', Stage.render)
draw:require('drawable')

function draw:on_awake()
	local l = self.ctx.drawable.drawLayer
	world.drawLayerActorIds[l] = world.drawLayerActorIds[l] or {}
	table.insert(world.drawLayerActorIds[l], self.actor.id)
end

function draw:on_destroy()
	assert(world.drawLayers[c.drawable.layer])
	table.remove(world.drawLayers[c.drawable.layer], self.actor.id)
end

function draw:on_stageend()
	--
	-- compute transforms, for all actors in the scene -- we probably want to have some way
	-- to only calculate some subset of the transforms required for drawing?
	--

	local root, root_transform = xfind(world.root_actor_id, 'transform')
	
	local actorids              = root.childids
	local transform_matrices    = {}
	transform_matrices[root.id] = transformation.object_world(root_transform)
	
	for _, id in pairs(actorids) do
		local actor, transform = xfind(id, 'transform')
	
		local parent_transform_matrix = transform_matrices[actor.parentid]
		transform_matrices[actor.id]  = parent_transform_matrix * transformation.object_world(transform)
	
		for _, childid in pairs(actor.childids) do
			table.insert(actorids, childid)
		end
	end

	--
	-- draw the layers
	--

	local cam_actor, cam_transform, cam = xfind(world.mainCameraId , 'transform', 'camera')

	-- temp clear
	love.graphics.setColor(cam.clearColor)
	love.graphics.rectangle('fill', 0, 0, windowWidth, windowHeight)

	local w = windowWidth
	local h = windowHeight

	for _, layer in pairs({ "Background", "Foreground" }) do
		local ids = world.drawLayerActorIds[layer]
	
		if ids then
			for _, id in pairs(world.drawLayerActorIds[layer]) do
				local actor, transform, drawable = xfind(id, 'transform', 'drawable')
	
				if actor.behaviours['draw'].should.update then
					local t = transformation.world_view_window(cam_transform, w, h) * transform_matrices[actor.id]

					love.graphics.push()
					love.graphics.applyTransform(t)

					love.graphics.setColor(drawable.color)

					local r = drawable.rect
					love.graphics.rectangle('fill', r.left, r.bottom, r.right - r.left, r.top - r.bottom)
	
					love.graphics.pop()
				end
			end
		end
	end
end