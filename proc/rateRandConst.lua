local function create(args)
    local distrib = args.distrib or {0.6, 0.2, 0.2}
    local item = args.item or {0.343, 0.298, 0.0111}

    local function randSampleItem(distrib, item)
        assert(#distrib == #item)
        local ind = torch.multinomial(torch.Tensor(distrib), 1)
        ind = ind[1]
        return item[ind]
    end
    local rate = randSampleItem(distrib, item)

    local function schedule()
        return rate
    end
    return schedule
end

return create
