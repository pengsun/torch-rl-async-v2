require'cutorch'
require'cunn'
require'torch-rnn'

local stateDim = {3, 84, 84}
local nCombo = 1
local nActions = 8

dofile('eval-async.lua'){
    -- environment
    envName = 'env.EnvVizdoomHealthGathering',
    vizdoomPath = '/home/ps/torch/install/lib/lua/5.1/vizdoom',
    doomScenarioPath = 'scenarios/health_gathering_supreme.wad',
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
    netName = 'net.Convx2LstmActorCritic',
    -- validator: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 30,
    },
    -- other
    gpu = 1,
    printFreq = 525,
    valMaxSteps = 525*3,
    printWhenNZReward = false,
    sleepTime = 0.1,
    animTimeDelay = 10, -- in mili-seconds
    isPlayOneEpisode = false,
    animPath = 'hgsup-demo.gif',
    -- other: load
    loadParamsPath = 'save/vizdoom-a3c-lstm-rgb/hgsup-params.t7',
}