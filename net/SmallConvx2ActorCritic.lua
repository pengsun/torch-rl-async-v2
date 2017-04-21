require'nn'

local function create(opt)
    local stateDim = opt.stateDim or error('no opt.stateDim')
    assert(#stateDim == 3, 'dim must be 3')
    local h, w = stateDim[2], stateDim[3]
    local c = opt.nCombo or error('no opt.nCombo')
    c = c * stateDim[1]
    local K = opt.nActions or 10

    local D = 32
    local H = 32

    local net = nn.Sequential()
    -- n, c, h, w
    net:add( nn.SpatialConvolution(c, D, 5, 5, 2, 2, 1, 1) )
    net:add( nn.ReLU(true) )
    -- n, D/2, h', w'
    net:add( nn.SpatialConvolution(D, D, 5, 5, 2, 2, 0, 0) )
    net:add( nn.ReLU(true) )
    -- n, D, h'', w''
    net:add( nn.View(-1):setNumInputDims(3) )
    -- n, D*h'',*w''

    -- n, D*h'',*w''
    local function inferSize()
        local input = torch.Tensor(1, c, h, w)
        local output = net:forward(input)
        return output:numel()
    end
    net:add( nn.Linear(inferSize(), H) )
    net:add( nn.ReLU(true) )
    -- n, H

    -- n, H
    local ct = nn.ConcatTable()
    ct:add( nn.Sequential():add(nn.Linear(H, K)):add(nn.SoftMax()) )
    ct:add( nn.Linear(H, 1) )
    net:add(ct)
    -- {[n, K], [n, 1]}

    net = net:float()

    return net
end
return create

