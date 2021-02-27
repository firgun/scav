
Actor = Class{}

function Actor:init(world)
    assert(world, "Provide a world when creating an entity.")
    self.world = world
    self.guid = 0
    self.name = 'New Actor'
    self.tag = ''
    self.bounds = Bounds2D(-0.5, -0.5, 0.5, 0.5)
    self.components = {}
    self:add_component(Transform())
    self.world:spawn(self)
end

function Actor:add_component(component)
    component.actor = self
    table.insert(self.components, component)
    --
    -- @Note: This creates a method on the actor _instance_ that retrieves the component. So don't
    -- think of it as a method of an actor, but rather a method available if the instance has the
    -- corresponding component.
    -- 
    -- If you know some actor has a component with name 'Transform' then you call actor.transform()
    -- to retrieve it
    --
    Actor[string.lower(component.name)] = function(self_)
        return component
    end
end

function Actor:start()
    for _, c in ipairs(self.components) do
        c:start()
    end
end

function Actor:update(dt)
    print(self.name .. ' updating')

    for _, c in ipairs(self.components) do
        c:update(dt)
    end
end

function Actor:draw()
    print(self.name .. ' drawing')

    for _, c in ipairs(self.components) do
        c:draw()
    end
end

--
-- @Note it may be tempting to use this as a hit rect, but perhaps we should separate that,
-- right now, this is only used for picking.
--
-- If an actor does not have a Sprite component, then there it does not have a visual presence
-- in the world and will not be selectable from the view port.
--
function Actor:get_world_bounds()
    local t = self:transform():world_matrix()
    local b = self:bounds()
    local min_x, min_y = t:transformPoint(b.min.x, b.min.y)
    local max_x, max_y = t:transformPoint(b.max.x, b.max.y)
    return Bounds2D:new(min_x, min_y, max_x, max_y)
end

function Actor:serialize(output)
    -- @Todo: To serialize an actor, serialize it's primitive members then serialize 
    -- all it's components -- kroos
end
