
Camera = Class{__includes = Component}

function Camera:init()
    Component.init(self, 'Camera')
    self.clear_color = { 0.5, 0.5, 0.5, 1.0 }
end