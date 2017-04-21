require'torch'
require'image'

local function create(opt)
    local stateDim = opt.stateDim or error('no opt.stateDim')
    assert(#stateDim == 3, 'dim must be 3')
    assert(stateDim[1] == 1, 'dim[1] must be 1')
    local WW, HH = stateDim[3], stateDim[2]

    local function preprocess(observation)
        -- luminance
        local img = image.rgb2y(observation:float())
        -- rescale
        img = image.scale(img, WW, HH, 'bilinear')

        return img
    end

    return preprocess
end

return create