
logger = {}

logger.level_err  = 1
logger.level_warn = 2
logger.level_info = 3

logger.dests = {}

logger.level_names = {
	[logger.level_err ] = "[error] ",
	[logger.level_warn] = "[warning] ",
	[logger.level_info] = "[info] ",
}

logger.level_set = {
	[logger.level_err]  = true,
	[logger.level_warn] = true,
	[logger.level_info] = true,
}

function logger.put_log(level, str)
	for _, dest in pairs(logger.dests) do
		if dest.level >= level then
			dest.outfile:write(logger.level_names[level] .. str .. '\n')
			if dest.isverbose then
				-- TODO(keagan): debug.getinfo(2) to get caller information like the name and location (file, line etc.)
			end
		end
	end
end

function logger.info(str) logger.put_log(logger.level_info, str) end
function logger.warn(str) logger.put_log(logger.level_warn, str) end
function logger.err (str) logger.put_log(logger.level_err , str) end

--[[
	'dest' must be something with a :write(s) method, i.e. file-like objects according to some
]]--
function logger.newdest(dest, destlevel, isverbose)
	assert(logger.level_set[destlevel or logger.level_err] ~= nil, 'unknown destlevel: ' .. destlevel)
	table.insert(logger.dests, {
		outfile   = dest,
		level     = destlevel or logger.level_err, -- just show errors by default
		isverbose = isverbose or false,
	})
end