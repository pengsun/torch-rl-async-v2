require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {1, 84, 84}
local nCombo = 1
local nActions = 3

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvAtari',
    gameName = 'pong',
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
    netName = 'net.Convx2LstmActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 5,
    },
    -- other
    printFreq = 99999,
    printWhenNZReward = true,
    sleepTime = 0.01,
    valMaxSteps = 8000,
    isPlayOneEpisode = true,
    animPath = 'pong-lstm-demo.gif',
    -- other: load
    loadParamsPath = 'save/atari-a3c-lstm-update20/best-pong-params.t7',
}