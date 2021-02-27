
--
-- todo list
-- ===
-- * only load files that have been modified since the last time we loaded them (we may need to store config stuff
--   differently with meta stuff then we don't have to patch)
--

config = {}

--
-- base determines all config vars and their default values, to produce the actual config
-- we patch the base with various config files i.e. with the master config and a per user
-- config profiles
--
-- this serves both as documentation and a sort of weak type checking, as we can (and do)
-- check the default types of all config vars in the base when patching in a new object.
--
-- note that the base only contains very simple data types like numbers, strings and
-- simple tables -- this is important too, for copying the base.
--
-- why not just use base as master? because we need to restore to defaults during runtime
-- when the master will be different from the base.
--

config.base = {}

--
-- console vars, see console.lua
--

-- TODO: refactor these old style vars to 'config.base.console.var' form

config.base.CONSOLE_BGCOL_ON      = { 0.3, 0.5, 0.8, 0.3 }
config.base.CONSOLE_BGCOL_OFF     = { 0.3, 0.5, 0.8, 0.3 }
config.base.CONSOLE_FGCOL         = {    1,    1,    1,   1 }
config.base.CONSOLE_INPUT_BGCOL   = { 0.7, 0.24, 0.5, 0.9 }
config.base.CONSOLE_INPUT_FGCOL   = {    1,    1,    1,   1 }
config.base.CONSOLE_CURSOR_COLOR  = {  0.8, 0.7,  0.2, 1.0 }
config.base.CONSOLE_SPEED_SCROLL  =  600
config.base.CONSOLE_SPEED_OPEN    = 2000
config.base.CONSOLE_PROMPT        = '$ '

config.base.CONSOLE_PADDING_VERTICAL   = 4
config.base.CONSOLE_PADDING_HORIZONTAL = 4

config.base.CONSOLE_SPEED_BLINK = 5

config.base.imgui = {}

config.base.imgui.do_debug_draw = false

config.base.imgui.cursor_padding = 8
config.base.imgui.cursor_line_height = 20

config.base.imgui.text_color = { 1, 1, 1, 1 }

config.base.imgui.panel_background_color = { 0.3, 0.5, 0.8, 0.2 }
config.base.imgui.panel_border_color     = { 1, 1, 1, 0.8 }
config.base.imgui.panel_title_bar_background_color = { 0.7, 0.3, 0.5, 0.5 }
config.base.imgui.panel_width    = 400
config.base.imgui.panel_height   = 350
config.base.imgui.panel_title_bar_height = 20
config.base.imgui.panel_title_bar_padding = 3

config.base.imgui.button_background_color        = {  0.2, 0.5 , 0.4 , 0.5  }
config.base.imgui.button_hot_background_color    = { 0.25, 0.55, 0.44, 0.75 }
config.base.imgui.button_active_background_color = { 0.35, 0.75, 0.55, 1    }

config.base.imgui.input_field_background_color = { 0, 0, 0, 0 }
config.base.imgui.input_field_border_color = color_with_alpha(config.base.imgui.panel_background_color, 1)




config.watch = {
	-- 'data/config/master.config',
	-- 'data/config/user.config'  ,
}

function config.update()
	config.patchconfig(config.conf, config.base)
	for _, path in pairs(config.watch) do
		local c = config.loadconfig(path)
		if c then
			config.patchconfig(config.conf, c)
		end
	end
end

function config.patchconfig(conf, thepatch)
	for var, val in pairs(thepatch) do
		if not config.base[var] then
			logger.warning('unknown config var: "' .. var .. '"')
		elseif type(config.base[var]) ~= type(val) then
			logger.warning('config var: "' .. var .. '" should be "' ..
				type(config.base[var]) .. '" not "' .. type(val) .. '"')
		else
			conf[var] = val
		end
	end
end

function config.loadconfig(path)
	local path = 'data/config/base.config'

	local f, err = loadstring(path)
	
	if err then
		logger.err('failed to get open config at ' .. path)
		logger.err(err)
		return nil
	end

	local status, result = pcall(fn)

	if not status then
		logger.err('failed to execute config file, see error below ... ')
		logger.err(result)
		return nil
	end

	local configobj = result

	if not configobj then
		logger.err('config obj is nil at ' .. path .. ', did you forget to return it?')
		return nil
	end

	return configobj
end

config.conf = {}
config.patchconfig(config.conf, config.base)
