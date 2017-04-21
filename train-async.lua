require'nn'
tablex = require'pl.tablex' -- tablex.merge
strTimeNow = require'util.strTimeNow'
require'meter.ScalarMeter'
require'util.sharedRmsprop'
nnweight = require'util.nnweight'
tds = require'tds'
require'image'
threads = require'threads'
threads.Threads.serialization('threads.sharedserialize')

local dftOpt = {
    nThreads = 4,
    -- environment
    envName = 'env.EnvAtari',
    stateDim = {1, 84, 84}, -- i.e., screen dim
    nCombo = 4, -- concatenate # states
    nActions = 4,
    isShow = false,
    isRandGame = true,
    -- trainer
    sharedName = 'A3CShared',
    trainerName = 'A3CTrainer',
    procRewardName = nil,
    procRewardOpt = nil,
    procStateName = 'proc.screenIdentity',
    -- trainer: memory replay
    memReplayName = 'util.MemoryReplayRecent',
    memReplayOpt = {
        nCombo = 4,
        foldUnfoldStateName = 'proc.foldUnfoldStateTable',
    },
    -- trainer: net
    netName = 'net.CpuConvnetAtariFC',
    targetNetUpdateFreq = 10*1000,
    -- trainer: learning
    --optimMethod = optim.sharedRmsprop,
    optimConfig = {
        learningRate = 0.00025,
        momentum = 0.95,
        rmsEpsilon = 0.01,
    },
    epsilonShrinkName = 'proc.rateRandEndShrinkLinear',
    epsilonShrinkOpt = {
        tBeg = 5,
        tEnd = 10*1000*1000,
        rBeg = 1,
        rEndDistrib = {0.4, 0.3, 0.3},
        rEndItem = {0.1, 0.01, 0.5}
    },
    learningRateShrinkName = 'proc.rateShrinkLinear',
    learningRateShrinkOpt = {
        tBeg = 1,
        tEnd = 1000*1000,
        rBeg = 1e-3,
        rEnd = 1e-9,
    },
    learningMaxSteps = 50*1000*1000,
    learningUpdateFreq = 4,
    learningStart = 50*1000,
    deltaMax = 1,
    deltaMin = -1,
    -- validating
    validatorName = 'Validator',
    valUseGpu = true,
    valMaxSteps = 1000,
    valFreq = 5000,
    -- save & load
    saveFreq = 30*1000,
    saveParamsPath = nil,
    saveBestValParamsPath = nil,
    saveAgentPath = 'agent.t7',
    saveValMetersPath = 'val-meters.t7',
    loadAgentPath = nil,
    -- print
    printFreq = 10*1000,
    -- other
    gcFreq = 10*1000,
}

local function setGlobal(opt)
    if opt.logPath then
        print = require'util.logPrint'{logPath = opt.logPath}
    end
end

local function wrapFunctionExitOnError(fun)
    return function()
        local status, err = xpcall(fun, debug.traceback)
        if not status then
            print('tid = '..__threadid..', error:')
            print(err)
            os.exit(128)
        end
    end
end

local function main(opt)
    -- global settings
    setGlobal(opt)

    --require'mobdebug'.start()
    -- config
    local opt = tablex.merge(dftOpt, opt, true)
    print('[opt]')
    print(opt)

    -- thread specific functions
    local function t_torchRequire()
        require'image'
        tds = require'tds'

        require'nn'
        pcall(require, 'cutorch')
        pcall(require, 'cunn')
        pcall(require, 'cudnn')
        pcall(require, 'torch-rnn')

        tablex = require'pl.tablex' -- tablex.merge
        strTimeNow = require'util.strTimeNow'
        require'meter.ScalarMeter'

        nnweight = require'util.nnweight'
    end

    local function t_torchSetup(tid)
        torch.setnumthreads(1) -- per thread
        local seed = 279*tid
        print('tid = '..tid..', seed = '..seed)
        torch.manualSeed(seed)

        print = require'util.logPrint'{
            logPath = string.format('%s-%d', opt.logPath, tid)
        }
    end

    local function t_torchSetupVal()
        torch.setnumthreads(1) -- per thread
        local seed = 358
        print('tid = val'..', seed = '..seed)
        torch.manualSeed(seed)

        print = require'util.logPrint'{
            logPath = string.format('%s-%s', opt.logPath, 'val')
        }
    end

    -- shared variables
    print'[shared]'
    local shared = require(opt.sharedName)(opt)

    -- validating stuff
    local valPool = threads.Threads(1,
        t_torchRequire,
        t_torchSetupVal,
        threads.safe(function ()
            valEnv = require(opt.envName)(opt)
        end)
    )

    local function t_valLoop()
        local function performSaving(valParams, valMeters)
            local function saveParams(fn, params)
                if not fn then return end

                print('saving network params to '..fn)
                torch.save(fn, params)
                print('saving done!')
            end

            local function saveValMeters(meters, opt)
                print('saving meters to '..opt.saveValMetersPath)
                torch.save(opt.saveValMetersPath, meters)
                print('saving done!')
            end

            -- saving best net?
            local rm = valMeters.reward
            if rm:num() == 0 or rm:getLast() == rm:max() then
                print('')
                print('new best net params found')
                saveParams(opt.saveBestValParamsPath, valParams)
            end

            -- regular saving?
            print('')
            saveParams(opt.saveParamsPath, valParams)

            -- save meters
            saveValMeters(valMeters, opt)
        end

        -- init validating
        local valFreq = opt.valFreq
        local lastValCount = 0
        local lastGCCount = 0
        local valMeters = {
            iter = ScalarMeter(),
            reward = ScalarMeter(),
        }

        -- validating
        while true do
            local T = shared.TCounter:get()

            -- should exit?
            if T > opt.learningMaxSteps then break end

            -- should do validating?
            if valFreq and T - lastValCount > valFreq then
                lastValCount = T

                -- prepare validating net. DO NOT OVERWRITE !!
                local valNet = shared.net:clone()
                local val = require(opt.validatorName)(valEnv, valNet, opt)

                -- do validating
                print('')
                print(string.format(
                    '%s, tid = val, T = %d, validating for %d steps',
                    strTimeNow(), T, opt.valMaxSteps
                ))

                local rMeter = val:doLoop()

                valMeters.reward:add(rMeter:mean())
                valMeters.iter:add(T)

                print(strTimeNow()..', tid = val'..', done validating')
                print(string.format(
                    '%s, tid = val, #episodes = %d, avg reward = %f, ',
                    strTimeNow(), rMeter:num(), rMeter:mean()
                ))

                -- saving stuff
                local valParams = valNet:getParameters()
                performSaving(valParams, valMeters)
            end -- if

            if opt.gcFreq and T - lastGCCount > opt.gcFreq then
                lastGCCount = T
                --collectgarbage()
                --print('tid = '..__threadid..', T = '..T..', collect garbage')
            end

        end -- while
    end

    valPool:addjob(wrapFunctionExitOnError(t_valLoop)) -- add validating thread

    -- training stuff
    local pool = threads.Threads(opt.nThreads,
        t_torchRequire,
        t_torchSetup,
        threads.safe(function ()
            local env = require(opt.envName)(opt)
            trainer = require(opt.trainerName)(env, shared, opt)

            print('done init context for thread '..__threadid)
        end)
    )

    pool:specific(true)
    for i = 1, opt.nThreads do -- add training threads
        pool:addjob(i, wrapFunctionExitOnError(function ()
            trainer:doLoop()
        end))
    end

    pool:synchronize()
    valPool:synchronize()

    pool:terminate()
    valPool:terminate()
end

return main