require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {1, 84, 84}
local nCombo = 1
local nActions = 6

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvAtari',
    gameName = 'space_invaders',
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
        capacity = 3*nCombo,
    },
    -- other
    printFreq = 99999,
    printWhenNZReward = true,
    sleepTime = 0.02,
    isPlayOneEpisode = true,
    animPath = 'si-lstm-demo.gif',
    -- other: load
    loadParamsPath = 'save/atari-a3c-lstm-ncombo4-T80M-update20/best-breakout-params.t7',
}