local function create(args)
    local tBeg = args.tBeg or error'no args.tBeg'
    local tEnd = args.tEnd or error'no args.tEnd'
    local rBeg = args.rBeg or error'no args.rBeg'
    local rEndDistrib = args.rEndDistrib or error'no args.rEndDistrib'
    local rEndItem = args.rEndItem or error'no args.rEndItem'

    local function randSampleItem(distrib, item)
        assert(#distrib == #item)
        local ind = torch.multinomial(torch.Tensor(distrib), 1)
        ind = ind[1]
        return item[ind]
    end
    local rEnd = randSampleItem(rEndDistrib, rEndItem)

    local uderlySchedule = require'proc.rateShrinkLinear'{
        tBeg = tBeg,
        tEnd = tEnd,
        rBeg = rBeg,
        rEnd = rEnd,
    }

    local function schedule(t)
        return uderlySchedule(t)
    end
    return schedule
end

return create
