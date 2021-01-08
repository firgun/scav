
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
	if result and result.transform then
		local t = result.transform
		local r = result.drawable.rect
		local m = transformation.object_world(t)
		local x, y = m:transformPoint(r.left, r.top)
		local w, h = r.right - r.left, r.top - r.bottom
		return make_rect(x, y, w, h)
	else
		return nil
	end
end