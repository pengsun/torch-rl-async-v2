local function create(opt)

    local function preprocess(observation)
        return observation:float():clone()
    end

    return preprocess
end

return create