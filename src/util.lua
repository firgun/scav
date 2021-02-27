
-- Taken and adapted from https://stackoverflow.com/questions/53990332/how-to-an-actual-copy-of-a-variable-in-lua/53992026

function  DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            	copy[orig_key] = DeepCopy(orig_value)
        end
        setmetatable(copy, getmetatable(orig))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Dump(o, depth)
	if not depth then
		depth = 1
	end
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. Dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function IsIdentifier(name)
	return type(name) == 'string' and string.match(name, '[_%a][_%w]*') == name
end

function Serialize(o, depth)
	if not depth then
		depth = 0
	end
	local indent = ""
	for i=0,depth do
		indent = indent .. "    "
	end
	if type(o) == "number" then
		io.write(o)
	elseif type(o) == "string" then
    	io.write(string.format("%q", o))
	elseif type(o) == 'nil' then
		io.write('nil')
	elseif type(o) == "boolean" then
		io.write(o and 'true' or 'false')
	elseif type(o) == "table" then
    	io.write("{\n")
		for k,v in pairs(o) do
			io.write(indent)
			local l, r = "", ""
			if IsIdentifier(k) then
				l = ''
				r = ''
			elseif type(k) == 'number' then
				l = '['
				r = ']'
			else
				l = '["'
				r = '"]'
			end
			io.write(l, k, r, " = ")
			Serialize(v, depth+1)
			io.write(",\n")
    	end
		for i=1,depth do
			io.write("    ")
		end
		io.write("}")
	else
		error("cannot serialize a " .. type(o))
	end
end

-- color utils

function color_with_alpha(c, a)
	return { c[1], c[2], c[3], c[4] * a }
end

-- math utils

function clamp(v, min, max)
	if v < min then
		v = min
	elseif v > max then
		v = max
	end
	return v
end

function makev2(x, y)
	return { x = x, y = y }
end

function make_rect(x, y, width, height)
	local o = {}
	o.x = x
	o.y = y
	o.w = width
	o.h = height
	return o
end

function in_rect(x, y, xr, yr, w, h)
	return x >= xr and x <= xr + w and y >= yr and y  <= yr + h
end