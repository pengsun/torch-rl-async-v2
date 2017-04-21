require'torch'
require'sys'
require'meter.ScalarMeter'
local VERY_SMALL = 1e-20

do -- class def
    local Validator = torch.class('Validator')

    -- main interfaces
    function Validator:__init(env, net , opt)
        self.env = env

        self.maxSteps = opt.valMaxSteps or 1000

        -- preprocessing
        self.procState = opt.procStateName and require(opt.procStateName)(opt) or nil

        -- local net
        self.net = net:clone()
        -- equip gpu?
        if opt.valUseGpu == true then
            local plugGpu = require'util.nnPlugGpuModulesCudnn'
            plugGpu(self.net)
        end

        -- memory replay
        self.memReplay = require(opt.memReplayName)(opt.memReplayOpt)

        -- validating style
        self.isPlayOneEpisode = opt.isPlayOneEpisode
        self.sleepTime = opt.sleepTime

        -- print
        self.printFreq = opt.printFreq
        self.lastPrintT = self.printFreq
        self.printWhenNZReward = opt.printWhenNZReward

        -- anim file saving?
        self.animPath = opt.animPath
        self.animTimeDelay = opt.animTimeDelay

        self:reset()
    end

    function Validator:reset()
        self.nStep = 0 -- local counter
        self.memReplay:reset()

        self:resetEpisode()
    end

    function Validator:resetEpisode()
        -- restart environment
        self.env:evaluate()
        self.env:start()

        -- for RNN (if any)
        if self.net.resetStates then
            self.net:resetStates()
        end
    end

    function Validator:doLoop()
        self:reset()

        local terminal
        local rMeter, rMeterInner = ScalarMeter(), ScalarMeter()
        for it = 1, self.maxSteps do
            -- get current state
            local state = self.env:getState()
            state = self.procState and self.procState(state) or state
            self.memReplay:pushState(state)
            local stateCombo = self.memReplay:topStateCombo()

            -- make action
            local a = self:predictAction(stateCombo)
            self.env:takeAction(a)

            -- get reward
            local r = self.env:getReward()

            -- record
            rMeterInner:add(r)

            -- end of episode?
            terminal = self.env:getTerminal()
            if terminal > 0 then
                -- record
                rMeter:add(rMeterInner:sum())
                rMeterInner:reset()

                -- restart
                self:resetEpisode()
            end
        end

        return rMeter
    end

    function Validator:doLoopSaveAnim()
        gd = require "gd"
        require'image'

        self:reset()

        -- prepare writing
        local im, previm, animTimeDelay
        animTimeDelay = self.animTimeDelay or 3 -- 2 milli seconds

        local state = self.env:getState()
        local jpg
        jpg = image.compressJPG(state:squeeze(), 100)
        im = gd.createFromJpegStr(jpg:storage():string())
        im:trueColorToPalette(false, 256)
        im:gifAnimBegin(self.animPath, true, 0)
        im:gifAnimAdd(self.animPath, false, 0, 0, animTimeDelay, gd.DISPOSAL_NONE)
        previm = im

        local nEpisode = 0
        local terminal
        local rMeter, rMeterInner = ScalarMeter(), ScalarMeter()
        for it = 1, self.maxSteps do
            -- get current RAW state
            local state = self.env:getState()

            -- write?
            local jpg
            jpg = image.compressJPG(state:squeeze(), 100)

            im = gd.createFromJpegStr(jpg:storage():string())
            im:trueColorToPalette(false, 256)
            im:paletteCopy(previm)
            im:gifAnimAdd(self.animPath, false, 0, 0, animTimeDelay, gd.DISPOSAL_NONE)
            previm = im

            -- get current state
            state = self.procState and self.procState(state) or state
            self.memReplay:pushState(state)
            local stateCombo = self.memReplay:topStateCombo()

            -- make action
            local a = self:predictAction(stateCombo)
            self.env:takeAction(a)

            -- get reward
            local r = self.env:getReward()

            -- get terminal
            terminal = self.env:getTerminal()

            -- record
            rMeterInner:add(r)

            -- print ?
            if (self.printWhenNZReward == true and r ~=0) or (self.printFreq and it % self.printFreq == 0) then
                print('iter = '..it..', action = '..a..', reward = '..r..', totalReward = '..rMeterInner:sum()..', terminal = '..terminal)
            end

            -- sleep ?
            if self.sleepTime then
                sys.sleep(self.sleepTime)
            end

            -- end of episode?
            if terminal > 0 then

                -- record
                rMeter:add(rMeterInner:sum())
                rMeterInner:reset()

                if self.isPlayOneEpisode == true then
                    print('end of episode, last iter = '..it)
                    break
                else
                    nEpisode = nEpisode + 1
                    print('end of #episode = '..nEpisode..', last iter = '..it)
                end

                -- restart
                self:resetEpisode()
            end
        end

        return rMeter
    end

    -- make actions
    function Validator:predictAction(state)
        -- sample over the probability
        local p, v = table.unpack(self.net:forward(state)) -- [n, K], [n, 1]
        local action = torch.multinomial(p, 1):view(-1) -- [n]
        v = v:view(-1)

        return (action:nElement()==1) and action[1] or action, (v:nElement()==1) and v[1] or v -- n==1: number, n>1: [n] tensor
    end
end -- class def

-- class factory
local function create(...)
    return Validator(...)
end
return create