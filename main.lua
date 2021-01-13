
-- TODO list
-- ----
--
-- * Editor GUI (with IMGUI)
-- 	Watch Casey's lecture on Immediate Mode Graphical User Interfaces, then implement basic editor
--     gizmos to manipulate entities in the game

windowWidth  = 768*1.5
windowHeight = 480*1.5

require 'util'
require 'log'
require 'component'
require 'behaviour'

require 'actor'
require 'actorutil'

require 'gizmos'
require 'stream'
require 'draw'
require 'find'
require 'config'

require 'imgui'

require 'editor'
-- require 'console'

require 'color'
require 'vector'

logger.newdest(io.output()    , logger.level_info, true)
-- logger.newdest(default_console, logger.level_info, true)

function love.load()
	love.window.setMode(windowWidth, windowHeight)
	initworld()
end

function love.textinput(t)
	-- console.type(t)
end

function love.update(dt)
	config.update (dt)

	updateworld   (dt)

	
	editor .update(dt)
	-- console.update(dt)
end

function love.mousepressed(x, y, button)
	if button == 1 then
		ui.mouse_pressed = true
	end
end
 
function love.mousereleased(x, y, button)
   if button == 1 then
      ui.mouse_released = true
   end
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end

	-- TODO: move this to the console module
	--
	
	--[[
	if key == 'tab' then
		console.take_suggestion()
	end

	if key == '`' then
		console.toggle()
	end

	if key == 'backspace' then
		console.backspace()
	end

	if key == 'return' then
		console.ret()
	end

	if key == 'left' then
		console.move(-1)
	elseif key == 'right' then
		console.move( 1)
	end

	if key == 'up' then
		console.cycle(1)
	elseif key == 'down' then
		console.cycle(-1)
	end
	]]--
end

function love.draw()
	drawworld()
	renderer:draw()
	-- console.draw()
end


