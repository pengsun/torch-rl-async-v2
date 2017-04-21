require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {3, 84, 84}
local nCombo = 1
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
    procStateName = 'proc.screenResize',
    valUseGpu = true,
    -- validator: net
    netName = 'net.Convx2LstmActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 3*nCombo,
    },
    -- other
    printFreq = 99999,
    printWhenNZReward = true,
    sleepTime = 0.00,
    valMaxSteps = 99999,
    isPlayOneEpisode = true,
    animPath = 'breakout-lstm-rgb-demo.gif',
    -- other: load
    loadParamsPath = 'save/atari-a3c-lstm-rgb-T250M-update20/best-breakout-params.t7',
}