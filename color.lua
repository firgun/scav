
color = {}

color.red   = { 1, 0, 0, 1 }
color.green = { 0, 1, 0, 1 }
color.blue  = { 0, 0, 1, 1 }
color.white = { 1, 1, 1, 1 }

color.gray  = { 0.25, 0.25, 0.25, 1.0 }

function color.random()
	return {
		math.random(),
		math.random(),
		math.random(),
		math.random(),
	}
end