-- S shape clipping
local function create(args)
    local rMax = math.abs(args.rMax) or error()

    local function schedule(r)
        local rr = math.abs(r)
        if rr < rMax then
            return r/rMax
        else
            return (r > 0) and 1 or -1
        end
    end
    return schedule
end

return create
