require'torch'
require'image'

local function create(opt)
    local stateDim = opt.stateDim or error('no opt.stateDim')
    assert(#stateDim == 3, 'dim must be 3')
    local WW, HH = stateDim[3], stateDim[2]

    local function preprocess(observation)
        -- rescale
        local img = image.scale(observation:float(), WW, HH, 'bilinear')
        -- normalize value
        img = img:div(255)

        return img
    end

    return preprocess
end

return create