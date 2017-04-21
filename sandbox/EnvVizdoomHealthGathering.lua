require'vizdoom'
require'torch'
ffi = require'ffi'

do -- class def
    local EnvVizdoomHealthGathering = torch.class('EnvVizdoomHealthGathering')

    -- main interface
    function EnvVizdoomHealthGathering:__init(opt)
        -- Create DoomGame instance. It will run the game and communicate with you.
        local game = vizdoom.DoomGame()

        -- game path
        local vizdoomPath = opt.vizdoomPath or '.'
        game:setViZDoomPath( paths.concat(vizdoomPath, 'vizdoom') )
        game:loadConfig( paths.concat(vizdoomPath, "scenarios/health_gathering.cfg") )

        -- game scenario
        if opt.doomScenarioPath and type(opt.doomScenarioPath) == 'string' then
            game:setDoomScenarioPath( paths.concat(vizdoomPath, opt.doomScenarioPath) )
        end
        -- game map
        if opt.doomMap and type(opt.doomMap) == 'string' then
            game:setDoomMap(opt.doomMap)
        end

        -- #actions
        assert(opt.nActions == 8, "nActions must be "..8)
        self.nActions = opt.nActions
        local actionTable = {
            {0, 0, 0},
            {0, 0, 1},
            {0, 1, 0},
            {0, 1, 1},
            {1, 0, 0},
            {1, 0, 1},
            {1, 1, 0},
            {1, 1, 1},
        }
        self.convertActionIndex = function(actionIndex)
            return actionTable[actionIndex]
        end

        -- #repeate actions
        self.actrep = opt.actrep or 4

        -- screen
        game:setScreenResolution(vizdoom.ScreenResolution.RES_160X120)
        game:setScreenFormat(vizdoom.ScreenFormat.RGB24)
        game:setDepthBufferEnabled(false)
        game:setLabelsBufferEnabled(false)
        game:setAutomapBufferEnabled(false)

        -- render
        self.isShow = true
        if not opt.isShow then self.isShow = false end
        game:setWindowVisible(self.isShow )
        game:setSoundEnabled(false)

        game:setMode(vizdoom.Mode.PLAYER)

        -- Initialize the game. Further configuration won't take any effect from now on.
        game:init()

        self.game = game

        self.lastTotalShapingReward = 0
        self:training()
    end

    function EnvVizdoomHealthGathering:start()
        self.game:newEpisode()

        -- init reward
        self.reward = 0
        self.lastTotalShapingReward = 0
    end

    function EnvVizdoomHealthGathering:getState()
        local obs
        if self:getTerminal() == 0 then
            local state = self.game:_getState()
            obs = self:converScreen(state.screenBuffer)
        else
            obs = self:createNullScreen()
        end
        return obs
    end

    function EnvVizdoomHealthGathering:getReward()
        local reward = self.reward
        if self.isShapingReward then -- also count shaping reward
            local currentTotalShapingReward = vizdoom.doomFixedToNumber(
                self.game:getGameVariable(vizdoom.GameVariable.USER1)
            )
            reward = reward + (currentTotalShapingReward - self.lastTotalShapingReward)
            self.lastTotalShapingReward = currentTotalShapingReward
        end
        return reward
    end

    function EnvVizdoomHealthGathering:getTerminal()
        local terminal = self.game:isEpisodeFinished()
        return (terminal==true) and 1 or 0
    end

    function EnvVizdoomHealthGathering:takeAction(actionIndex)
        -- make action & get reward
        local a = self.convertActionIndex(actionIndex)
        self.reward = self.game:makeAction(a, self.actrep)
    end

    function EnvVizdoomHealthGathering:training()
        self.isShapingReward = true
    end

    function EnvVizdoomHealthGathering:evaluate()
        self.isShapingReward = false
    end

    -- helpers
    function EnvVizdoomHealthGathering:converScreen(screenBuffer)
        local obs = torch.ByteTensor(3*120*160)
        ffi.copy(obs:data(), screenBuffer, 3*120*160)

        obs = obs:view(120, 160, 3)
            :permute(3, 1, 2)
            :index(1, torch.LongTensor{3, 2, 1})

        return obs
    end

    function EnvVizdoomHealthGathering:createNullScreen()
        local obs = torch.zeros(3, 120, 160):byte()
        return obs
    end
end -- class def

-- class factory
local function create(opt)
    return EnvVizdoomHealthGathering(opt)
end
return create