
world = nil
worldGame = nil
worldBase = nil

function CreateEmptyWorld()
	local w = {}
	
	w.nextActorId = 0
	w.actors      = {}

	w.root_actor_id = nil

	w.mainActorId    = nil
	w.cameraActorIds = {}
	
	w.dt   = 1/60
	w.mode = 'Game'

	w.drawLayerActorIds = {}
	
	return w
end

function findtilemap()
	for _, actor in pairs(world.actors) do
		local r = findp(actor, 'tile_map')
		if r then
			return actor
		end
	end
end

function SpawnActor(actor)
	world.actors[actor.id] = actor

	--
	-- check if we can grab this actor as the main camera
	--
	
	local result = findp(actor, 'camera')
	if result then
		table.insert(world.cameraActorIds, actor.id)
		world.mainCameraId = world.mainCameraId or actor.id
	end

	if world.root_actor_id then
		local root = xfind(world.root_actor_id)
		setparent(actor, root)
	end
end

function GetNextActorId()
	local id = world.nextActorId
	world.nextActorId = world.nextActorId + 1
	return id
end

function setparent(actor, parent)
	if actor.parentid then
		local oldparent = world.actors[actor.parentid]
		if oldparent then
			table.remove(oldparent.childids, actor.id)
			actor.parentid = nil
		else
			logger.err('child has parentid (' .. actor.parentid .. ') but cannot find corresponding actor')
		end
	end
	table.insert(parent.childids, actor.id)
	actor.parentid = parent.id
end

function CreateEmptyActor()
	local actor = {}
	
	actor.id = GetNextActorId()
	actor.components = {}
	actor.behaviours = {}
	actor.parentid   = nil
	actor.childids   = {}

	addcomponent(actor, 'transform')
	
	return actor
end

function SpawnCamera()
	local actor = CreateEmptyActor()
	addcomponent(actor, 'camera')
	addbehaviour(actor, 'editor_camera_controller')
	SpawnActor(actor)
	return actor
end
 	
function SpawnTestActor()
	local actor = CreateEmptyActor()
	
	local d     = addcomponent(actor, 'drawable')
	d.color     = color.random()
	d.drawLayer = "Foreground"
	d.rect      =
	{
		left   = -0.45,
		right  =  0.45,
		top    =  1.5 ,
		bottom =   0  ,
	}

	addbehaviour(actor, 'draw')
	addbehaviour(actor, 'worldbasesaver')
	addbehaviour(actor, 'character_controller')
	addbehaviour(actor, 'chunkstreamer')

	SpawnActor(actor)

	local _, transform = xfind(actor, 'transform')
	if transform then
		transform.scale    = 0.9
		transform.rotation =   0
	end

	local hand = CreateEmptyActor()
	addbehaviour(hand, 'draw')
	local handdrawable = addcomponent(hand, 'drawable')
	setparent(hand, actor)
	SpawnActor(hand)

	handdrawable.color = { 1, 0, 0, 1 }
	handdrawable.drawLayer = "Foreground"

	local _, handtransform = xfind(hand, 'transform')
	handtransform.position.x = 0.5
	handtransform.position.y = 0.75
	handtransform.scale = 0.5

	setparent(hand, actor)

	return actor
end

function GetMainCamera()
	return findp(world.mainCameraId, 'camera').camera
end

function GetTileColor(tileMapChunk, i, j)
	local on  = tileMapChunk.dbg_coloron
	local off = tileMapChunk.dbg_coloroff
	if i % 2 == 0 then
		if j % 2 == 0 then
			return on
		else
			return off
		end
	else
		if j % 2 == 0 then
			return off
		else
			return on
		end
	end
end

function SetupDefaultWorld()
	local root = CreateEmptyActor()
	SpawnActor(root)
	world.root_actor_id = root.id

	SpawnCamera()
	
	local tilemap = CreateEmptyActor()
	addcomponent(tilemap, 'tile_map')
	addbehaviour(tilemap, 'tilemap_builder')
	SpawnActor  (tilemap)

	SpawnTestActor()
end

function SaveWorld()
	local outFile, errCode = io.open('data/worlds/base.world', 'w+')
	if not outFile then
		logger.err('failed to open world output file for writing, error code: ' .. errCode)
		return
	end
	local tmp = io.output()
	io.output(outFile)

	io.write('local result = ')
	Serialize(worldBase)
	io.write('\nreturn result')

	io.output(tmp)
	outFile:close()

	logger.info('saved world to data/worlds/base.world')
end

function startgame()
	logger.info('starting game')
	assert(worldBase ~= nil)
	worldGame = DeepCopy(worldBase)
	world = worldGame
	assert(world ~= nil)
	logger.info('game started')
end

function initworld()
	logger.info('loading the world')
	-- DEBUGGING(keagan): force world to be recreated instead of loaded from file
	name = 'foo'
	forceReloadFromFile = true
	if not worldBase or forceReloadFromFile then
		local path = 'data/worlds/' .. (name or 'base') .. '.world'
		local f, err = loadfile(path)
		if not f then
			logger.err('failed to load ' .. path .. ' for reading, err: ' .. err)
		end
		if f then
			worldBase = f()
			world = worldBase
			logger.info('loaded world from file')
		else
			worldBase = CreateEmptyWorld()
			world = worldBase
			SetupDefaultWorld()
			logger.info('created default world procedurally')
		end
	end
	startgame()
end

function updateworld(dt)
	world.dt = dt
	dobehaviours(Stage.update)
end

function drawworld()
	if not world.mainCameraId then
		love.graphics.setColor({ 0.25, 0.25, 0.25, 1.0 })
		love.graphics.rectangle('fill', 0, 0, windowWidth, windowHeight)
		love.graphics.setColor({ 1, 1, 1, 1 })
		love.graphics.print("No main camera", 10, 10);
	else
		dobehaviours(Stage.render)
		gizmo.draw()
	end
end
