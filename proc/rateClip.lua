local function create(args)
    local rMax = args.rMax or error()
    local rMin = args.rMin or error()

    local function schedule(r)
        return math.min(rMax, math.max(rMin, r))
    end
    return schedule
end

return create
