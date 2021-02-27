
WorldViewMode = {
    from_editor,
    from_game,
}

World = Class{}

function World:init()
    self.actors           = {}
    self.title            = ''
    self.transform        = nil

    if name then
        self:read(name)
    else
        self.title = 'New World'

        self.game_camera = Actor(self)
        self.game_camera.name = 'Game Camera'
        self.game_camera:add_component(Camera())
        self.game_camera:camera().clear_color = color.blue
    
        self.edit_camera = Actor(self)
        self.edit_camera.name = 'Editor Camera'
        self.edit_camera:add_component(Camera())
        self.edit_camera:camera().clear_color = color.gray

        local square = Actor(self)
        square.name = 'Square'
        square:add_component(Sprite())
    end
end

function World:dump_actors()
    for _, actor in ipairs(self.actors) do
        print(actor.name)
        for _, c in ipairs(actor.components) do
            print('    ' .. c.name)
        end
        print()
    end
end

function World:read(name)
    assert(false, "implement")
end

function World:spawn(actor)
    table.insert(self.actors, actor)
end

function World:update(dt)
    for _, a in ipairs(self.actors) do
        a:update(dt)
    end
end

function World:draw(actor)
    if actor:camera().clear_color[4] ~= 0 then
        love.graphics.setColor(actor:camera().clear_color)
        love.graphics.rectangle('fill', 0, 0, window_width, window_height)
    end

    love.graphics.push()

    self.transform = love.math.newTransform()
	self.transform:translate(window_width / 2,  window_height / 2)
	self.transform:scale    (window_width / 2, -window_height / 2)
    self.transform:scale    (1 / window_width / window_height, 1 )

    -- love.graphics.applyTransform(self.transform)

    self.active_camera = actor

    for _, a in ipairs(self.actors) do
        a:draw()
    end

    love.graphics.pop()
end

function World:serialize()
end