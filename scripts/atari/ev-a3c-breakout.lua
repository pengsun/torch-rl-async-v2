require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {1, 84, 84}
local nCombo = 4
local nActions = 4

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvAtari',
    gameName = 'breakout',
    stateDim = stateDim,
    nCombo = nCombo,
    nActions = nActions,
    isShow = true,
    isRandGame = true,
    -- validator
    agentName = 'Validator',
    procStateName = 'proc.screenResizeY',
    valUseGpu = true,
    -- validator: net
    netName = 'net.Convx2ActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 3*nCombo,
    },
    -- other
    gpu = 1,
    printFreq = 999999,
    valMaxSteps = 99999,
    printWhenNZReward = true,
    sleepTime = 0.00,
    isPlayOneEpisode = true,
    animPath = 'breakout-demo.gif',
    -- other: load
    loadParamsPath = 'save/atari-a3c/best-breakout-params.t7',
}