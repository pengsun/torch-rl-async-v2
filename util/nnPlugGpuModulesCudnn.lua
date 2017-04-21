require'nn'
require'cudnn'

local function plugGpuModulesCudnn (net)
    -- head
    net:insert(nn.Copy('torch.FloatTensor', 'torch.CudaTensor'), 1)

    -- tail
    local tail = net:get(net:size())
    if torch.typename(tail) == 'nn.ConcatTable' then
        local pt = nn.ParallelTable()
        for i = 1, tail:size() do
            pt:add(nn.Copy('torch.CudaTensor', 'torch.FloatTensor'))
        end
        net:add(pt)
    else
        net:add(nn.Copy('torch.CudaTensor', 'torch.FloatTensor'))
    end

    net:cuda()
end

return plugGpuModulesCudnn