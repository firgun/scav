
function magnitude(x, y)
	return math.sqrt(x*x + y*y)
end

function normalize(x, y)
	local m = magnitude(x, y)
	return x / m, y / m
end

function scale(x, y, k)
	return x * k, y * k
end