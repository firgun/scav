
chunkstreamer = Behaviour:new('chunkstreamer', Stage.update)

function chunkstreamer:on_update()
	local transform    = self.ctx.transform
	local _, tilemap   = xfind(findtilemap(), 'tile_map')
	local worldextents = 1
	local chunks = self:_getchunks(transform.position, worldextents, tilemap)
	for _, chunk in pairs(chunks) do
		for _, tileid in pairs(chunk.tileActorIds) do
			local tile_actor, tile_drawable = xfind(world.actors[tileid], 'drawable')
			tile_drawable.opacity = 1.0
		end
	end
end

--
-- get chunks surrounding the transform of the streamer (streamer is like our atlas, it orients us
-- in the world
--
function chunkstreamer:_getchunks(pos, extents, tilemap)
	local bounds = {}
	bounds.min = { x = pos.x - extents * 0.5, y = pos.y - extents * 0.5 }
	bounds.max = { x = pos.x + extents * 0.5, y = pos.y + extents * 0.5 }
	local chunks = {}
	for i=1, tilemap.numchunksy do
		for j=1, tilemap.numchunksx do
			local chunkid = tilemap.chunksbyindex[(i-1)*tilemap.numchunksx+(j-1)]
			local chunkactor = world.actors[chunkid]
			if chunkactor then
				local _, chunk = xfind(chunkactor, 'tile_map_chunk')
				if rect.intersects(bounds, chunk.bounds) then
					table.insert(chunks, chunk)
				end
			end
		end
	end
	return chunks
end

--
-- TODO(keagan): move this module to it's own file probably
--

rect = {}

function rect.contains(rect, x, y)
	return x >= rect.min.x and x <= rect.max.x and y >= rect.min.y and y <= rect.max.y
end

function rect.intersects(a, b)
	return rect.contains(a, b.min.x, b.min.y) or
		   rect.contains(a, b.max.x, b.max.y) or
		   rect.contains(a, b.min.x, b.max.y) or
		   rect.contains(a, b.max.x, b.min.y)
end