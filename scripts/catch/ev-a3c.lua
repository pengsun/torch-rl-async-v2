require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {1, 24, 24}
local nCombo = 4
local nActions = 2

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvCatch',
    stateDim = stateDim,
    nCombo = nCombo,
    nActions = nActions,
    isShow = true,
    isRandGame = true,
    -- validator
    agentName = 'Validator',
    procStateName = 'proc.screenIdentity',
    valUseGpu = true,
    valMaxSteps = 24*30,
    -- validator: net
    netName = 'net.SmallConvx2ActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 3*nCombo,
    },
    -- other
    gpu = 1,
    printFreq = 99999,
    printWhenNZReward = true,
    sleepTime = 0.01,
    isPlayOneEpisode = false,
    animPath = 'catch-demo.gif',
    -- other: load
    loadParamsPath = 'save/catch-a3c/best-params.t7',
}