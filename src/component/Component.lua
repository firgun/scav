
Component = Class{}

function Component:init(name)
    self.name    = name
    self.actor   = nil
    self.enabled = true
end

function Component:start    () end
function Component:update   () end
function Component:draw     () end

function Component:serialize() end