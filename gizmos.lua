
--
-- a simple drawing api for in-game debugging and visualization
--

gizmo = {}
gizmo.commands = {}

gizmo.default_color   = { 1, 1, 1, 1 }
gizmo.default_opacity = 0.2

local Command = {
	rect  = 1,
	point = 2,
	line  = 3,
}

function gizmo._push_command(cmdtype, center)
	local cmd  = {}
	cmd.type   = cmdtype
	cmd.center = center
	cmd.color  = gizmo.default_color
	table.insert(gizmo.commands, cmd)
end

function gizmo.push_rect (center) gizmo._push_command(Command.rect , center) end
function gizmo.push_line (data  ) gizmo._push_command(Command.line , data  ) end
function gizmo.push_point(data  ) gizmo._push_command(Command.point, data  ) end

function gizmo.draw()
	local camactor, cam, camtransform = xfind(world.mainCameraId, 'camera', 'transform')
	for _, cmd in pairs(gizmo.commands) do
		local fn = ({
			[Command.rect ] = function()
				love.graphics.setColor({ 0, 1, 0, 0.2 })
				love.graphics.rectangle('fill', -0.5, -0.5, 1, 1)
				love.graphics.setColor({ 0, 1, 0, 1   })
				love.graphics.setLineWidth(0.02)
				love.graphics.rectangle('line', -0.5, -0.5, 1, 1)
			end,
			[Command.point] = function()
				assert(false, 'implementation missing')
			end,
			[Command.line ] = function()
				assert(false, 'implementation missing')
			end,
		})[cmd.type]

		if fn then
			cmd.color[4] = 0.5
			love.graphics.setColor(cmd.color)

			transform = {}
			transform.position = {}
			transform.position.x = cmd.center.x
			transform.position.y = cmd.center.y
			transform.scale    = 1
			transform.rotation = 0

			local t = transformation.object_world_view_window(
				transform,
				camtransform,
				windowWidth,
				windowHeight)

			love.graphics.push()
			love.graphics.applyTransform(t)
			fn()
			love.graphics.pop()
		else
			logger.err('unknown gizmo command type: ' .. cmd.type)
		end
	end

	gizmo.commands = {}
end
