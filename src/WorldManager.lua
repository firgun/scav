WorldManager = Class{}

WorldState = {
    stopped = 0,
    playing = 1,
    paused  = 2,
}

function WorldManager:init()
    self.master = World()
    self.worlds = {} 
    self.state  = WorldState.stopped   
end

function WorldManager:update(dt)
    if self.state ~= WorldState.playing then
        return
    end

    for _, w in ipairs(self.worlds) do
        w:update(dt)
    end
end

function WorldManager:draw()
    if self.state == WorldState.stopped then
        self.master:draw(self.master.edit_camera)
    else
        for _, w in ipairs(self.worlds) do
            w:draw(w.game_camera)
        end
    end
end