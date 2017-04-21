tablex = require'pl.tablex'
require'util.sharedRmsprop'

local stateDim = {1, 84, 84}
local nCombo = 1
local nActions = 4
local learningMaxSteps = 80*1000*1000
local learningUpdateFreq = 5
local learningRateStart = 0.0007

dofile('train-async.lua'){
    nThreads = 16,
    -- environment
    envName = 'env.EnvAtari',
    gameName = 'breakout',
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
    netName = 'net.Convx2LstmActorCritic',
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
        learningRate = learningRateStart,
        momentum = 0.99,
        rmsEpsilon = 0.1,
    },
    learningRateShrinkName = 'proc.rateShrinkLinear',
    learningRateShrinkOpt = {
        tBeg = 1,
        tEnd = learningMaxSteps,
        rBeg = learningRateStart,
        rEnd = 0,
    },
    -- validating
    validatorName = 'Validator',
    valUseGpu = true,
    valMaxSteps = 125*1000,
    valFreq = 250*1000,
    -- other
    printFreq = 10*1001,
    gcFreq = 3456,
    -- other: save & load
    saveParamsPath = 'save/atari-a3c-lstm/breakout-params.t7',
    saveBestValParamsPath = 'save/atari-a3c-lstm/best-breakout-params.t7',
    saveValMetersPath = 'save/atari-a3c-lstm/breakout-val-meters.t7',
    logPath = 'save/atari-a3c-lstm/breakout-log',
}