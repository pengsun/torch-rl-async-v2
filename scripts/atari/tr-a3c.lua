tablex = require'pl.tablex'
require'util.sharedRmsprop'

local stateDim = {1, 84, 84}
local nCombo = 4
local nActions = 3
local learningMaxSteps = 50*1000*1000
local learningUpdateFreq = 5

dofile('train-async.lua'){
    nThreads = 2,
    -- environment
    envName = 'env.EnvAtari',
    gameName = 'pong',
    stateDim = stateDim,
    nCombo = nCombo,
    nActions = nActions,
    isShow = false,
    isRandGame = true,
    -- trainer
    trainerName = 'A3CTrainer',
    sharedName = 'A3CShared',
    procStateName = 'proc.screenResizeY',
    procRewardName = 'proc.rateClip',
    procRewardOpt = {
        rMax = 1,
        rMin = -1,
    },
    -- trainer: net
    netName = 'net.Convx2ActorCritic',
    -- trainer: mem replay
    memReplayName = 'util.MemoryReplayRecentMinibatch',
    memReplayOpt = {
        stateDim = stateDim,
        nCombo = nCombo,
        capacity = 20,
    },
    -- trainer: learning
    learningMaxSteps = learningMaxSteps,
    learningStart = 20,
    learningUpdateFreq = learningUpdateFreq,
    gradNormClip = 40,
    betaEntropy = 0.01,
    optimConfig = {
        learningRate = 0.00025,
        momentum = 0.95,
    },
    learningRateShrinkName = 'proc.rateShrinkLinear',
    learningRateShrinkOpt = {
        tBeg = 1,
        tEnd = learningMaxSteps,
        rBeg = 1e-3,
        rEnd = 0,
    },
    -- validating
    validatorName = 'Validator',
    valUseGpu = true,
    valMaxSteps = 1001,
    valFreq = 1003,
    -- other
    printFreq = 1001,
    gcFreq = 3456,
    -- other: save & load
    saveParamsPath = 'save/atari-a3c/pong-params.t7',
    saveBestValParamsPath = 'save/atari-a3c/best-pong-params.t7',
    saveValMetersPath = 'save/atari-a3c/pong-val-meters.t7',
    logPath = 'save/atari-a3c/pong-log',
}