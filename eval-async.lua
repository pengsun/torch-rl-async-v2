require'torch'
require'nn'
require'cudnn'
tds = require'tds'
tablex = require'pl.tablex' -- tablex.merge

local dftOpt = {
    -- environment
    envName = 'env.EnvAtari',
    gameName = 'breakout',
    stateDim = {1, 84, 84},
    nCombo = 4,
    isShow = false,
    isRandGame = true,
    procScreenName = 'proc.screenToY',
    -- validator
    validatorName = 'Validator',
    -- validator: net
    netName = 'net.CpuConvnetAtariFCSmall',
    -- agent: mem replay
    memReplayName = 'util.MemoryReplayRecent',
    memReplayOpt = {
        capacity = 100,
        stateSize = {1, 84, 84},
        nCombo = 4,
    },
    -- other
    maxValSteps = 100*1000,
    printFreq = 10*1000,
    animFilename = nil,
    -- other: load
    loadParamsPath = 'save/sharedParams.t7'
}


local function main(opt)
    -- config
    local opt = tablex.merge(dftOpt, opt, true)

    print('[opt]')
    print(opt)

    -- create env
    local env = require(opt.envName)(opt)

    -- create net & load params
    local net = require(opt.netName)(opt)
    local paramsSaved = torch.load(opt.loadParamsPath)
    local params = net:getParameters()
    params:copy(paramsSaved)

    -- do validating loop
    local val = require(opt.validatorName)(env, net, opt)
    val:doLoopSaveAnim()
    print('finished. close window to exit.')
end

return main