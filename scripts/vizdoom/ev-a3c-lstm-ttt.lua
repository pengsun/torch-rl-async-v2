require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {3, 84, 84}
local nCombo = 1
local nActions = 6

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvVizdoomTTT',
    vizdoomPath = '/home/ps/torch/install/lib/lua/5.1/vizdoom',
    evalGameVar = 'FRAGCOUNT',
    stateDim = stateDim,
    nCombo = nCombo,
    nActions = nActions,
    nBots = 3,
    isShow = true,
    -- validator
    agentName = 'Validator',
    procStateName = 'proc.screenResizeNorm',
    valUseGpu = true,
    -- validator: net
    netName = 'net.Convx2LstmActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 30,
    },
    -- other
    printFreq = 99999,
    printWhenNZReward = true,
    sleepTime = 0.1,
    valMaxSteps = 2*6300,
    isPlayOneEpisode = false,
    animPath = 'ttt-lstm-demo.gif',
    -- other: load
    loadParamsPath = 'save/vizdoom-a3c-lstm-rgb/best-ttt-params.t7',
}