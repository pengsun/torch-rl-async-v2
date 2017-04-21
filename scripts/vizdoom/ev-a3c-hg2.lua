require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {3, 84, 84}
local nCombo = 1
local nActions = 8

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvVizdoomHealthGathering',
    vizdoomPath = '/home/ps/ViZDoom',
    stateDim = stateDim,
    nCombo = nCombo,
    nActions = nActions,
    isShow = true,
    isRandGame = true,
    -- validator
    agentName = 'Validator',
    procStateName = 'proc.screenResizeNorm',
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
    printFreq = 525,
    valMaxSteps = 525*3,
    printWhenNZReward = false,
    sleepTime = 0.00,
    isPlayOneEpisode = false,
    animPath = 'hg2-demo.gif',
    -- other: load
    loadParamsPath = 'save/vizdoom-a3c-backup/best-hg2-params.t7',
}