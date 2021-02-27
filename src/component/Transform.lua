
Transform = Class{__includes = Component}

function Transform:init()
    Component.init(self, 'Transform')
    self.translation = Vector2D()
    self.scale       = Vector2D(1, 1)
    self.rotation    = 0
    self.parent      = nil
end

function Transform:world_transform()
    local t = self:local_transform()
    if self.parent then
        t = self.parent:world_transform() * self:local_transform()
    end
    return t
end

function Transform:local_transform()
	local t = love.math.newTransform()
	t:translate(self.translation.x, self.translation.y)
	t:scale    (self.scale      .x, self.scale      .y)
	t:rotate   (self.rotation                         )
	return t
end

function Transform:up   () self:world_matrix():transformPoint(Vector2D:up   ()) end
function Transform:right() self:world_matrix():transformPoint(Vector2D:right()) end
