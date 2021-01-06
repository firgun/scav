

--
-- find api -- a simple api for querying actors and components
--
-- usage:
--
-- you can specify the actor as directly or through an id
--
-- local actor, comp1, comp2 = find(id   , name1, name2)
-- local        comp1, comp2 = find(actor, name1, name2)
--
-- if you want to bundle items together, you can use findp, where 'p' is for packed
--
-- local info = findp(id, name1, name2) -- or findp(actor, name1, name2)
-- print(info.actor)
-- print(info.name1)
-- print(info.name2)
--
-- if you just want the actor you can do this
--
-- local actor = find(id)
--
-- if there was an error, the entire result is just nil (is this what we want?)
--
-- local result, err = findp(id, ... )
-- if err then
-- 	...
-- end
--
-- if you think an error would be a bug, then you can call xfind or xfindp, which
-- asserts that the error should be nil. You don't want to do this for things that
-- can be edited and change at runtime, but sometimes it's better to make absolute
-- sure that you're game is in some expected state
--
-- I want to extent the 'x' functions such that, if a find fails, the game can still
-- continue (instead of crashing the game and editor entirely.
--
-- I am still experimenting with the api, perhaps the solution should be to remove
-- 'x' functions entirely and just require that the caller check the result every
-- time? I am going to need more experience with the system to make that decision.
--

local FindErr = {}
FindErr.noactor     = 1 -- couldn't find actor in the world
FindErr.badcomp     = 2 -- could not recognize one of specified components
FindErr.missingcomp = 3 -- could not find component on entity

--
-- perhaps this would be better as a function
--

local find_errors = {}
find_errors[FindErr.noactor    ] = { code = FindErr.noactor    , msg = 'bad actor id'      }
find_errors[FindErr.badcomp    ] = { code = FindErr.badcomp    , msg = 'bad component'     }
find_errors[FindErr.missingcomp] = { code = FindErr.missingcomp, msg = 'missing component' }

local log_find_err = false

local function do_find(actor_or_actor_id, comps)
	assert(type(comps) == 'table')

	local err    = nil
	local result = {}

	result.actor = actor_or_actor_id
	if type(actor_or_actor_id) == 'number' then
		result.actor = world.actors[actor_or_actor_id]
		if not result.actor then
			err = find_errors[noactor]
		end
	end

	for _, c in pairs(comps) do
		if componenttab[c] then
			local comp = result.actor.components[c]
			if comp then
				result[c] = comp
			else
				err = find_errors[FindErr.missingcomp]
			end
		else
			err = find_errors[FindErr.badcomp]
		end
	end

	if err then
		result = nil
		if log_find_err then
			logger.err('find error (code ' .. err.code .. ') ' .. err.msg)
		end
	end
	
	return result, err
end

function findp(actor_or_id, ...)
	return do_find(actor_or_id, {...})
end

function find(actor_or_id, ...)
	local result, err = do_find(actor_or_id, {...})
	local r = nil
	if result then
		r = {}
		local the_args = {...}
		table.insert(r, result.actor)
		for i=1,#the_args do
			table.insert(r, result[the_args[i]])
		end
	end
	return r
end

function xfindp(actor_or_id, ...)
	local result, _ = findp(actor_or_id, ...)
	assert(result ~= nil)
	return result
end

function xfind(actor_or_id, ...)
	local result, _ = find(actor_or_id, ...)
	assert(result ~= nil)
	local the_args = {...}

	--
	-- I am not sure if you can unpack programmatically, but this solution isn't going to scale well
	-- with different variants of find -- perhaps I could use lua macros to make the unpacked version
	-- of functions, but I am not optimistic that that will be much better
	--
	-- also, if I was using a statically typed language, this is what I'd probably do anyways, so maybe
	-- it's not that bad
	--

		if #the_args == 0 then return result[1]
	elseif #the_args == 1 then return result[1], result[2]
	elseif #the_args == 2 then return result[1], result[2], result[3]
	elseif #the_args == 3 then return result[1], result[2], result[3], result[4]
	elseif #the_args == 4 then return result[1], result[2], result[3], result[4], result[5]
	elseif #the_args == 5 then return result[1], result[2], result[3], result[4], result[5], result[6]
	elseif #the_args == 6 then return result[1], result[2], result[3], result[4], result[5], result[6], result[7]
	else
		assert(false, 'too many args, add more branches?')
	end
end
