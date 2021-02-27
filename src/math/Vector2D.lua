Vector2D = Class{}

function Vector2D:init(x, y)
	self.x = x or 0
	self.y = y or 0
end

function Vector2D:up()
    self.x = 0
    self.y = 1
end

function Vector2D:right()
    self.x = 1
    self.y = 0
end

function Vector2D:square_mag()
    return self.x*self.x + self.y*self.y
end

function Vector2D:mag()
    return math.sqrt(self.x*self.x + self.y*self.y)
end

function Vector2D:normalize()
    local m = self:mag()
    self.x = self.x / m
    self.y = self.y / m
    return self
end

function Vector2D:normalized()
    local m = self:mag()
    return Vector2D:new(self.x / m, self.y / m)
end

function Vector2D:scale(k)
    self.x = self.x * k
    self.y = self.y * k
end

-- @Todo: do operator overloading