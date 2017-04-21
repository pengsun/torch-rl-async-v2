require'image'
timenow = require'util.strTimeNow'
print = require'util.logPrint'({logPath = 'log-test-EnvVizdoomTTT'})

maxSteps = 250*1000*1000

local opt = {
    vizdoomPath = '/home/ps/torch/install/lib/lua/5.1/vizdoom',
    isShow = true,
    nBots = 7,
    evalGameVar = 'FRAGCOUNT',
    stateDim = {3, 84, 84}, -- i.e., screen dim
    nActions = 6,
    procScreenName = 'proc.screenResize',
    nCombo = 4,
}
env = require'env.EnvVizdoomTTT'(opt)

proc = require'proc.screenResize'(opt)

env:evaluate()
env:start()

--local input = torch.CudaTensor(1, table.unpack(opt.stateDim))
--local g = torch.CudaTensor(1, opt.nActions)

local nEpisode = 1
local totalReward = 0
time = torch.tic()
for n = 1, maxSteps do
    sys.sleep(0.0)

    local action = math.random(1, opt.nActions)

    env:takeAction(action)

    s = env:getState()

    r = env:getReward()

    t = env:getTerminal()

    -- print reward
    totalReward = totalReward + r
    if r ~= 0 then
        print(string.format('%s it = %d, episode = %d, reward = %d, total reward = %d', timenow(), n, nEpisode, r, totalReward))
        print(env:tostring())
    end

    -- display preprocessed screen
    ss = proc(s)
    --winId = image.display{image = ss, win = winId}

    if t == 1 then
        nEpisode = nEpisode + 1
        sys.sleep(0)

        print('iter = '..n)
        print( ('%s end of episode, restarting...\n'):format(timenow()) )
        env:start()
        totalReward = 0
    end
end
time = torch.toc(time)
print('time = '..time)
