require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {1, 24, 24}
local nCombo = 1
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
    -- validator: net
    netName = 'net.SmallConvx2LstmActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 5,
    },
    -- other
    gpu = 1,
    printFreq = 99999,
    printWhenNZReward = true,
    sleepTime = 0.01,
    valMaxSteps = 23*50,
    isPlayOneEpisode = false,
    animPath = 'catch-lstm-demo.gif',
    -- other: load
    loadParamsPath = 'save/catch-a3c-lstm/best-params.t7',
}