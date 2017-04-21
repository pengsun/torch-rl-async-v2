local function createShared(opt)
    -- shared nets
    print('[shared net structure]')
    local net = require(opt.netName)(opt)
    print(net)

    -- shared parameters
    local tmpParams = net:parameters()
    local params = nn.Module.flatten(tmpParams)
    print('#params = '.. params:numel())

    -- shared atomic counter
    local TCounter = tds.AtomicCounter()

    -- shared optimStates.g
    local g = torch.Tensor():typeAs(params):resizeAs(params):fill(0)

    return {net = net, params = params, TCounter = TCounter, g = g}
end

return createShared