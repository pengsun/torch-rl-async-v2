require'nn'
require'rnn'

local function create(opt)
    local stateDim = opt.stateDim or error('no opt.stateDim')
    assert(#stateDim == 3, 'dim must be 3')
    local c, h, w = stateDim[1], stateDim[2], stateDim[3]
    local nCombo = opt.nCombo or 1
    c = c * nCombo
    local K = opt.nActions or 10

    local D = 32
    local H = 256

    local net = nn.Sequential()
    -- n, c, h, w
    net:add( nn.SpatialConvolution(c, D/2, 8, 8, 4, 4, 1, 1) )
    net:add( nn.ReLU(true) )
    -- n, D/2, h', w'
    net:add( nn.SpatialConvolution(D/2, D, 4, 4, 2, 2, 0, 0) )
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
    local viewIn = nn.View(-1)
    net:add( viewIn )
    -- n, 1, H

    -- n, 1, H where n is viewed as sequence length
    local lstm = nn.FastLSTM(H, H)
    assert(lstm.forget ~= nil, 'no function forget()')
    net:add( nn.Sequencer(lstm) )
    -- n, 1, H

    -- n, 1, H
    local viewOut = nn.View(-1)
    net:add( viewOut )
    -- n, H

    -- n, H
    local ct = nn.ConcatTable()
    ct:add( nn.Sequential():add(nn.Linear(H, K)):add(nn.SoftMax()) )
    ct:add( nn.Linear(H, 1) )
    net:add(ct)
    -- {[n, K], [n, 1]} where the 1st is policy pi(), the 2nd is value v()

    -- install resetStates
    net.resetStates = function ()
        lstm:forget()
    end

    -- reload updateOutput to allow variable size
    local old_updateOutput = net.updateOutput
    net.updateOutput = function(self, input)
        local n = input:size(1)
        viewIn:resetSize(n, 1, -1)
        viewOut:resetSize(n, -1)

        return old_updateOutput(self, input)
    end

    net = net:float()

    return net
end
return create