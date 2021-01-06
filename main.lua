
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
require 'gizmos'
require 'stream'
require 'draw'
require 'find'
require 'config'

require 'imgui'

require 'editor'
require 'console'

logger.newdest(io.output()    , logger.level_info, true)
logger.newdest(default_console, logger.level_info, true)

function love.load()
	love.window.setMode(windowWidth, windowHeight)
	initworld()
end

function love.textinput(t)
	console.type(t)
end

function love.update(dt)
	config.update (dt)
	
	updateworld   (dt)

	editor .update(dt)
	console.update(dt)
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
end

function love.draw()
	drawworld()
	renderer:draw()
	console.draw()
end













--[[
local camrot = 0
local transform = {}
	
transform.position = {}
transform.position[1] = 0
transform.position[2] = 0

transform.rotation = math.pi/4

transform.scale = {}
transform.scale[1] = 1.0
transform.scale[2] = 1.0
]]--

--[[
	local camscale = {}
	camscale.x = 5
	camscale.y = 5

	local aspectratio = windowWidth/windowHeight
	local campos = {}
	campos.x = 1
	campos.y = 1
	camrot = camrot + math.pi/100

	local t = windowtransform(windowWidth, windowHeight) *
			  viewtransform  (campos  .x, campos  .y,
							  camscale.x, camscale.y,
							  camrot                   ) *
			  worldtransform (transform.position[1], transform.position[2],
					          transform.scale   [1], transform.scale   [2],
					          transform.rotation       )

	love.graphics.push()
	love.graphics.applyTransform(t)
	love.graphics.rectangle('fill', -0.5, -0.5, 1, 1)
	love.graphics.pop()
]]--

--[[
	love.graphics.push()

	-- view to screen
	love.graphics.translate(windowWidth/2, windowHeight/2)
	love.graphics.scale(windowWidth,  windowHeight)
	love.graphics.scale(1/aspectratio, 1)

	-- world to view
	love.graphics.scale    (1/camscale.x, 1/camscale.y)
	love.graphics.rotate   (-camrot)
	love.graphics.translate(-campos.x, -campos.y)

	-- object to world
	love.graphics.translate(transform.position[1], transform.position[2])
	love.graphics.scale    (transform.scale   [1], transform.scale   [2])
	love.graphics.rotate   (transform.rotation)

	love.graphics.rectangle('fill', -0.5, -0.5, 1, 1)

	love.graphics.pop()
]]--

