window_width  = 768
window_height = 480

Class = require 'src/lib/class'

require 'src/math/Vector2D'
require 'src/math/Bounds2D'

require 'src/color'

require 'src/component/Component'
require 'src/component/Transform'
require 'src/component/Sprite'
require 'src/component/Camera'

require 'src/Actor'

require 'src/World'
require 'src/WorldManager'

-- require 'src/util'
-- require 'src/log'
-- require 'src/component'
-- require 'src/behaviour'

-- require 'src/xxx_actor'
-- require 'src/actorutil'

-- require 'src/gizmos'
-- require 'src/stream'
-- require 'src/draw'
-- require 'src/find'
-- require 'src/config'

-- require 'src/imgui'

-- require 'src/editor'
-- require 'src/console'

-- require 'src/vector'

-- logger.newdest(io.output()    , logger.level_info, true)
-- logger.newdest(default_console, logger.level_info, true)

event_manager = nil
world_manager = nil
imgui_manager = nil
editor        = nil
console       = nil

function love.load()
	love.window.setMode(window_width, window_height)
	love.window.setTitle('Scav')

	world_manager = WorldManager()
	-- editor = Editor ()
	-- console = Console()
end

function love.update(dt)
	world_manager:update(dt)
	-- editor:update(dt)
	-- console:update(dt)
end

function love.draw()
	world_manager:draw()
end
