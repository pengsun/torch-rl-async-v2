tablex = require'pl.tablex'
require'util.sharedRmsprop'

local stateDim = {3, 84, 84}
local nCombo = 4
local nActions = 9
local learningMaxSteps = 250*1000*1000
local learningUpdateFreq = 20
local learningRateStart = 0.0007

dofile('train-async.lua'){
    nThreads = 16,
    -- environment
    envName = 'env.EnvVizdoomTTT2',
    vizdoomPath = '/home/ps/torch/install/lib/lua/5.1/vizdoom',
    nBots = 3,
    evalGameVar = 'FRAGCOUNT',
    stateDim = stateDim,
    nActions = nActions,
    isShow = false,
    -- trainer
    trainerName = 'A3CTrainer',
    sharedName = 'A3CShared',
    nCombo = nCombo,
    procStateName = 'proc.screenResizeNorm',
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
        capacity = 30,
    },
    -- trainer: learning
    learningMaxSteps = learningMaxSteps,
    learningStart = 30,
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
    valMaxSteps = 5*6300,
    valFreq = 250*1000,
    -- other
    printFreq = 10*1001,
    gcFreq = 3456,
    -- other: save & load
    saveParamsPath = 'save/vizdoom-a3c-rgb/ttt2-params.t7',
    saveBestValParamsPath = 'save/vizdoom-a3c-rgb/best-ttt2-params.t7',
    saveValMetersPath = 'save/vizdoom-a3c-rgb/ttt2-val-meters.t7',
    logPath = 'save/vizdoom-a3c-rgb/ttt2-log',
}