require'cudnn'
require'cunn'
require'nn'

local b = 4
local opt = {
    isShow = false,
    stateDim = {1, 84, 84}, -- i.e., screen dim
    nActions = 4,
    procScreenName = 'proc.screenToY',
    nCombo = 1,
}
env = require'env.EnvAtari'(opt)

net = require'net.ConvnetAtariFC'(opt):cuda()
print(net)

s, r, t = env:start()

local input = torch.CudaTensor(b, table.unpack(opt.stateDim))
local g = torch.CudaTensor(b, opt.nActions)

time = torch.tic()
for n = 1, b*600 do
    local action = math.random(1, opt.nActions)
    ss, rr, tt = env:step(action)

    --local q = net:forward(input)
    --net:backward(input, g)
end
time = torch.toc(time)
print('time = '..time)
