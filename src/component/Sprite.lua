
Sprite = Class{__includes = Component}

SpriteLayer = {
    background = 0,
    foreground = 1,
}

function Sprite:init()
    Component.init(self, 'Sprite')
    self.sprite = nil
    self.layer  = SpriteLayer.ground
    self.tint   = color.red
end

function Sprite:draw()
    local camera = self.actor.world.active_camera

    w = window_width
    h = window_height

    local vw = love.math.newTransform()
    vw:translate(w/2, h/2)
    vw:scale(w/2, -h/2)
    vw:scale(1/(w/h), 1)

    local wv = camera:transform():world_transform():inverse()
    local ow = self.actor.transform():world_transform()

    local transform = vw * wv * ow

    love.graphics.applyTransform(transform)
    love.graphics.setColor(self.tint)

    local b = self.actor.bounds

    local points = b:transformed_points(self.actor.world.transform * transform)
    print(points[1].x, points[1].y)

    if not self.sprite then
        print("hello")
        love.graphics.rectangle('fill', -b:width()/2, -b:height()/2, b:width(), b:height())
    else
        assert(false, "Implementation missing!")
    end
end
