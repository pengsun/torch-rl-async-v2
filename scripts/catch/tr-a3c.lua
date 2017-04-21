tablex = require'pl.tablex'
require'util.sharedRmsprop'

local stateDim = {1, 24, 24}
local nCombo = 4
local nActions = 2
local learningMaxSteps = 15*1000*1000
local learningUpdateFreq = 5
local learningRateStart = 0.0005

dofile('train-async.lua'){
    nThreads = 2,
    -- environment
    envName = 'env.EnvCatch',
    stateDim = stateDim,
    nCombo = nCombo,
    nActions = nActions,
    isShow = false,
    isRandGame = true,
    -- trainer
    trainerName = 'A3CTrainer',
    sharedName = 'A3CShared',
    procStateName = 'proc.screenIdentity',
    procRewardName = 'proc.rateClip',
    procRewardOpt = {
        rMax = 1,
        rMin = -1,
    },
    -- trainer: net
    netName = 'net.SmallConvx2ActorCritic',
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
    gradNormClip = 0,
    betaEntropy = 0.01,
    optimConfig = {
        learningRate = learningRateStart,
        momentum = 0.99,
        rmsEpsilon = 0.1,
    },
    learningRateShrinkName = 'proc.rateShrinkLinear',
    learningRateShrinkOpt = {
        tBeg = 1,
        tEnd = learningMaxSteps,
        rBeg = learningRateStart,
        rEnd = learningRateStart,
    },
    -- validating
    validatorName = 'Validator',
    valUseGpu = true,
    valMaxSteps = 24*25,
    valFreq = 5*1000,
    -- other
    printFreq = 5001,
    gcFreq = 3456,
    -- other: save & load
    saveParamsPath = 'save/catch-a3c/params.t7',
    saveBestValParamsPath = 'save/catch-a3c/best-params.t7',
    saveValMetersPath = 'save/catch-a3c/val-meters.t7',
    logPath = 'save/catch-a3c/log',
}