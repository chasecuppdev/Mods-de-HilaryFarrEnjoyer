local mod = get_mod("slots")

DebugDrawerRelease = class(DebugDrawerRelease)

function DebugDrawerRelease:init(line_object, mode)
    self._line_object = line_object
    self._mode = mode

    -- Debugging: Check the type of line_object
    if type(line_object) ~= "userdata" then
        mod:echo("Error: line_object is not userdata in DebugDrawerRelease:init")
    else
        mod:echo("DebugDrawerRelease:init line_object is userdata")
    end
end

function DebugDrawerRelease:update(world)
    -- Debugging: Check the type of self._line_object and world
    if type(self._line_object) ~= "userdata" then
        mod:echo("Error: self._line_object is not userdata in DebugDrawerRelease:update")
        return
    end

    if type(world) ~= "userdata" then
        mod:echo("Error: world is not userdata in DebugDrawerRelease:update")
        return
    end

    -- Debugging: Check if world is of type World
    if not World.is_world(world) then
        mod:echo("Error: world is not of type World in DebugDrawerRelease:update")
        return
    end

    LineObject.dispatch(self._line_object, world)
end

return DebugDrawerRelease