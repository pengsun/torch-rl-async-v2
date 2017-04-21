require'torch'
require'util.sharedRmsprop'
local nnweight = require'util.nnweight' -- printing weights
local normClip = require'util.normClip' -- grad norm clipping
local VERY_SMALL = 1e-20

do -- class def
    local A3CTrainer = torch.class('A3CTrainer')

    -- main interfaces
    function A3CTrainer:__init(env, shared , opt)
        self.env = env

        -- preprocessing
        self.procState = opt.procStateName and require(opt.procStateName)(opt) or nil
        self.procReward = opt.procRewardName and require(opt.procRewardName)(opt.procRewardOpt) or nil

        -- local net
        self.net = shared.net:clone()
        self.params, self.gradParams = self.net:getParameters()
        self.gradParams:zero()

        -- shared params
        self.sharedParams = shared.params

        -- shared counter
        self.sharedTCounter = shared.TCounter

        -- shared optim state
        local optimConfig = opt.optimConfig or {}
        self.optimConfig = {
            learningRate = optimConfig.learningRate,
            momentum = optimConfig.momentum,
            rmsEpsilon = optimConfig.rmsEpsilon,
            g = shared.g,
        }

        -- memory replay
        self.memReplay = require(opt.memReplayName)(opt.memReplayOpt)

        -- learning: net
        self.learningStart = opt.learningStart or 10*1000
        self.learningUpdateFreq = opt.learningUpdateFreq or 5
        -- learning: other
        self.isTrain = true
        self.learningMaxSteps = opt.learningMaxSteps or 1000
        self.gradNormClip = opt.gradNormClip or 0
        self.betaEntropy = opt.betaEntropy or 0.1
        self.discount = opt.discount or 0.99

        -- learning rate
        if opt.learningRateShrinkName then
            self.learningRateShrink = require(opt.learningRateShrinkName)(opt.learningRateShrinkOpt)
        end

        -- print
        self.printFreq = opt.printFreq
        self.lastPrintT = self.printFreq

        self:reset()
    end

    function A3CTrainer:reset()
        self.nStep = 0 -- local counter
        self.batchSize = 0 -- for mini batch learning
        self.T = 0 -- global counter
        self.memReplay:reset()
        if self.net.resetStates then self.net:resetStates() end

        self.env:start()
    end

    function A3CTrainer:doLoop()
        local function receiveState()
            local state = self.env:getState()
            state = self.procState and self.procState(state) or state
            self.memReplay:pushState(state)
            local stateCombo = self.memReplay:topStateCombo()
            return stateCombo
        end

        self:reset()
        local stateCombo = receiveState()
        local terminal = 0

        repeat
            -- reset net?
            if self.net.resetStates then self.net:resetStates() end -- reset states (for RNN)

            -- synchronize local params
            self.params:copy(self.sharedParams)

            -- init
            self.batchSize = 0

            repeat
                -- print?
                if self.printFreq and self.T - self.lastPrintT > self.printFreq then
                    self.lastPrintT = self.T

                    self:print()
                    if self.env.tostring then
                        print(self.env:tostring())
                    end
                end

                --require'mobdebug'.start()

                -- perform action and cache
                local action = self:predictAction(stateCombo)
                if terminal == 0 then
                    self.env:takeAction(action)
                end
                self.memReplay:pushAction(action)

                -- receive reward and cache
                local reward = self.env:getReward()
                reward = self.procReward and self.procReward(reward) or reward
                self.memReplay:pushReward(reward)

                -- reset enviroment? NOTE: the correct place to do this!!
                if terminal == 1 then self.env:start() end

                -- receive next state and cache
                stateCombo = receiveState()

                -- receive next terminal
                terminal = self.env:getTerminal()

                -- step++
                self.batchSize = self.batchSize + 1
                self.nStep = self.nStep + 1
                self.T = self.sharedTCounter:inc() + 1

            until terminal == 1 or self.batchSize == self.learningUpdateFreq

            if self.nStep > self.learningStart then
                -- fprop, bprop, update by gradient
                self:learnMinibatch(stateCombo, terminal)
            end

        until self.T > self.learningMaxSteps
    end

    -- printing
    function A3CTrainer:print()
        print('\n'..
                strTimeNow()..' tid = '..__threadid..', T '..self.T..'\n'..
                self:tostringStatus()..'\n'..
                self:tostringNetWeight()..'\n'
        )
    end

    function A3CTrainer:tostringNetWeight()
        return nnweight.tostringWeightNorms(self.net) .. '\n' ..
                nnweight.tostringGradNorms(self.net)
    end

    function A3CTrainer:tostringStatus()
        local M = math.sqrt(self.sharedParams:numel())
        local gpNorm = torch.norm(self.gradParams)
        local pNorm = torch.norm(self.sharedParams)
        return 'trainer step '..self.nStep..' T '..self.T..'\n'..
            'trainer memory replay capacity '..self.memReplay:capacity()..'\n'..
            'trainer gradParams norm '..gpNorm..'\n'..
            'trainer gradParams norm avg '..gpNorm/M..'\n'..
            'trainer gradNormClip '..self.gradNormClip..'\n'..
            'trainer betaEntropy '..self.betaEntropy..'\n'..
            'shared learning rate '..self.optimConfig.learningRate..'\n'..
            'shared params norm '..pNorm..'\n'..
            'shared params norm avg '..pNorm/M..'\n'
    end

    -- make actions
    function A3CTrainer:predictAction(state)
        -- sample over the probability
        local p, v = table.unpack(self.net:forward(state)) -- [n, K], [n, 1]
        local action = torch.multinomial(p, 1):view(-1) -- [n]
        v = v:view(-1)

        return (action:nElement()==1) and action[1] or action, (v:nElement()==1) and v[1] or v -- n==1: number, n>1: [n] tensor
    end

    -- learning
    function A3CTrainer:makeRewards(r, lastState, lastTerminal)
        local n = r:nElement()
        local rewards = torch.FloatTensor(n)

        -- Bootstrap from last state (or zero)
        local R = 0
        if lastTerminal == 0 then
            local __, v = self:predictAction(lastState)
            R = v
        end

        -- make the rewards vector
        rewards[n] = r[n] + self.discount * R
        for i = n - 1, 1, -1 do
            rewards[i] = r[i] + self.discount * rewards[i+1]
        end

        return rewards
    end

    function A3CTrainer:makeGradOutputs(outputs, rewards, actions)
        local probs, values = outputs[1], outputs[2] -- n, k & n, 1
        probs:add(VERY_SMALL)
        values = values:view(-1) -- n
        local n, K = probs:size(1), probs:size(2)

        -- precomputed (V - R)
        local diff = values:clone():add(-rewards) -- n

        -- d Pi = (V - R)./prob + (-beta* (d entropy))
        local gradProbs = probs:clone():log():add(1):mul(self.betaEntropy) -- beta*(1+log(p))
        for i = 1, n do
            local action = actions[i]
            local p = probs[i][action]
            gradProbs[i][action] = gradProbs[i][action] + diff[i]/p
        end

        -- d V = 0.5*(V - R)
        local gradValues = diff:clone():mul(0.5)
        gradValues:resize(n, 1)

        return {gradProbs, gradValues}
    end

    function A3CTrainer:learnMinibatch(lastState, lastTerminal)
        -- prepare data
        local s, a, r = self.memReplay:getRecentMinibatch(self.batchSize) -- size n mini-batch
        local rewards = self:makeRewards(r, lastState, lastTerminal) -- [n]

        -- fprop
        if self.net.resetStates then self.net:resetStates() end -- for RNN
        local outputs = self.net:forward(s) -- {[n,K], [n, 1]} probability & value respectively

        -- bprop
        self.gradParams:zero() -- zero gradients
        local gradOutputs = self:makeGradOutputs(outputs, rewards, a) -- {[n, K], [n, 1]}
        self.net:backward(s, gradOutputs)

        -- apply shared optimization over shared parameters asynchronously
        if self.learningRateShrink then
            self.optimConfig.learningRate = self.learningRateShrink(self.T)
        end
        if self.gradNormClip > 0 then
            normClip(self.gradParams, self.gradNormClip)
        end
        local feval = function(x)
                return 0, self.gradParams -- fine to return 0 loss
            end
        optim.sharedRmsprop(feval, self.sharedParams, self.optimConfig)
    end
end -- class def

-- class factory
local function create(...)
    return A3CTrainer(...)
end
return create