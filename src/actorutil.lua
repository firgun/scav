
function get_up(transform)
	local t = transformation.object_to_world(transform)
	x, y = t:transformPoint(0, 1)
	return x, y
end

function get_right(transform)
	local t = transformation.object_to_world(transform)
	x, y = t:transformPoint(1, 0)
	return x, y
end

function get_actor_bounds(actor)
	local result = findp(actor, 'transform', 'drawable')
	if result and result.transform and result.drawable then
		local t = transformation.object_world(result.transform)

		local r = result.drawable.rect

		local min_x, min_y = t:transformPoint(r.left , r.bottom)
		local max_x, max_y = t:transformPoint(r.right, r.top   )

		return make_rect(min_x, min_y, max_x - min_x, max_y - min_y)
	else
		return nil
	end
end