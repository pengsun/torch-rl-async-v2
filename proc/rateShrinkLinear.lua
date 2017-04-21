local function create(args)
    local rBeg = args.rBeg or error'no args.rBeg'
    local rEnd = args.rEnd or error'no args.rEnd'
    local tBeg = args.tBeg or error'no args.tBeg'
    local tEnd = args.tEnd or error'no args.tEnd'

    local function schedule(t)
        local tmp = rEnd + math.max(rBeg - rEnd, 0) / math.max(tEnd - tBeg, 0) * math.max(tEnd - t, 0)
        return math.min(tmp, rBeg)
    end
    return schedule
end

return create
