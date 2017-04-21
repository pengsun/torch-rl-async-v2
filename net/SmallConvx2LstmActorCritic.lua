require'nn'
require'torch-rnn'

local function create(opt)
    local stateDim = opt.stateDim or error('no opt.stateDim')
    assert(#stateDim == 3, 'dim must be 3')
    local c, h, w = stateDim[1], stateDim[2], stateDim[3]
    local nCombo = opt.nCombo or 1
    c = c * nCombo
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
    -- n, D*h''*w''

    -- n, D*h''*w''
    local function inferSize()
        local input = torch.Tensor(1, c, h, w) -- n =1
        local output = net:forward(input)
        return output:numel()
    end
    net:add( nn.Linear(inferSize(), H) )
    net:add( nn.ReLU(true) )
    -- n, H

    -- n, H
    net:add( nn.Unsqueeze(1) )
    -- 1, n, H

    -- 1, n, H where n is viewed as sequence length
    local lstm = nn.LSTM(H, H)
    assert(lstm.remember_states ~= nil, 'no remeber_states')
    lstm.remember_states = true
    net:add( lstm )
    -- 1, n, H

    -- 1, n, H
    net:add( nn.Squeeze(1) )
    -- n, H
    local ct = nn.ConcatTable()
    ct:add( nn.Sequential():add(nn.Linear(H, K)):add(nn.SoftMax()) )
    ct:add( nn.Linear(H, 1) )
    net:add(ct)
    -- {[n, K], [n, 1]} where the 1st is policy pi(), the 2nd is value v()

    -- install resetStates
    net.resetStates = function ()
        lstm:resetStates()
    end

    net = net:float()

    return net
end
return create