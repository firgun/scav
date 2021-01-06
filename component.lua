
componenttab = {}

local function register(name, constructor)
	logger.info('registered new component: ' .. name)
	componenttab[name] = constructor
end

function iscomponent(component_type)
	assert(type(component_type) == 'string', 'component_type should be "string" not ' .. type(component_type))
	return not not componenttab[component_type]
end

function hascomponent(actor, component_type)
	assert(type(component_type) == 'string', 'component_type should be "string" not ' .. type(component_type))
	return not not actor.components[component_type]
end

function addcomponent(actor, component_type)
	assert(type(component_type) == 'string', 'component_type should be "string" not ' .. type(component_type))

	if not iscomponent(component_type) then
		logger.warn(component_type .. ' is not a registered component')
		assert(false)
		return nil
	end

	if hascomponent(actor, component_type) then
		logger.warn('actor already has component: ' .. component_type)
		return nil
	end

	local component = {}
	component.type      = component_type
	component.actor_id  = actor.id
	component.is_active = true

	for k, v in pairs(componenttab[component_type]()) do
		if component[k] then
			logger.error('component overriding base component member: ' .. k)
			return nil
		end
		component[k] = v
	end

	actor.components[component_type] = component

	return component
end

register('transform', function()
	local o = {}
	o.position = {}
	o.position.x = 0
	o.position.y = 0
	o.position.z = 0
	o.rotation   = 0
	o.scale      = 1
	return o
end)

register('camera', function()
	local o = {}
	o.clearColor = { 0.09, 0.09, 0.12, 1.0 }
	o.aspectRatio = windowWidth/windowHeight
	o.minWorldSpaceCameraExtents = 1.0
	o.zoom = 0.05
	return o
end)

register('drawable', function()
	local o = {}
	o.imageAssetRef = nil
	o.color         = { 1, 1, 1, 1 }
	o.drawLayer     = 'Background'
	o.opacity       = 1
	o.rect          = {}
	o.rect.left     = -0.5
	o.rect.top      =  0.5
	o.rect.right    =  0.5
	o.rect.bottom   = -0.5
	return o
end)

register('tile_map', function()
	local o = {}
	o.numchunksx    = 1
	o.numchunksy    = 1
	o.chunkrows     = 5
	o.chunkcols     = 5
	o.chunkActorIds = {}
	o.chunksbyindex = {}
	return o
end)

register('tile_map_chunk', function()
	local o = {}
	o.rows = 25
	o.cols = 25
	o.tileActorIds = {}
	o.dbg_coloron  = { math.random() / 1.5, math.random() / 1.5, math.random() / 1.5, 1 }
	o.dbg_coloroff = { math.random() / 1.5, math.random() / 1.5, math.random() / 1.5, 1 }
	o.bounds = nil
	return o
end)

