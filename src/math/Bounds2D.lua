Bounds2D = Class{}

function Bounds2D:init(min_x, min_y, max_x, max_y)
    self.min = Vector2D(min_x or 0, min_y or 0)
    self.max = Vector2D(max_x or 0, max_y or 0)
end

function Bounds2D.unit()
    return Bounds2D(-0.5, -0.5, 0.5, 0.5)
end

function Bounds2D:size()
    return Vector2D(self.max.x - self.min.x, self.max.y - self.min.y)
end

function Bounds2D:width()
    return self.max.x - self.min.x
end

function Bounds2D:height()
    return self.max.y - self.min.y
end

function Bounds2D:transformed_points(transform)
    min_x_prime, min_y_prime = transform:transformPoint(self.min.x, self.min.y)
    max_x_prime, max_y_prime = transform:transformPoint(self.max.x, self.min.y)
    return {
        [1] = Vector2D(min_x_prime, min_y_prime),
        [2] = Vector2D(max_x_prime, min_y_prime),
        [3] = Vector2D(max_x_prime, max_y_prime),
        [4] = Vector2D(min_x_prime, max_y_prime),
    }
end