require'vizdoom'
require'torch'
ffi = require'ffi'

do -- class def
    local EnvVizdoomRocketBasic = torch.class('EnvVizdoomRocketBasic')

    -- main interface
    function EnvVizdoomRocketBasic:__init(opt)
        -- Create DoomGame instance. It will run the game and communicate with you.
        local game = vizdoom.DoomGame()

        -- game path
        local vizdoomPath = opt.vizdoomPath or '.'
        game:setViZDoomPath( paths.concat(vizdoomPath, 'vizdoom') )
        game:loadConfig( paths.concat(vizdoomPath, 'scenarios/rocket_basic.cfg') )

        -- game scenario
        if opt.doomScenarioPath and type(opt.doomScenarioPath) == 'string' then
            game:setDoomScenarioPath( paths.concat(vizdoomPath, opt.doomScenarioPath) )
        end
        -- game map
        if opt.doomMap and type(opt.doomMap) == 'string' then
            game:setDoomMap(opt.doomMap)
        end

        -- screen
        game:setScreenResolution(vizdoom.ScreenResolution.RES_160X120)
        game:setScreenFormat(vizdoom.ScreenFormat.RGB24)
        game:setDepthBufferEnabled(false)
        game:setLabelsBufferEnabled(false)
        game:setAutomapBufferEnabled(false)

        -- render
        self.isShow = false
        if opt.isShow == true then self.isShow = true end
        game:setWindowVisible(self.isShow)
        game:setSoundEnabled(false)

        -- other options
        --game:addGameArgs("-host 1 -deathmatch +timelimit 4.0 "..
        --        "+sv_forcerespawn 1 +sv_noautoaim 1 "..
        --        "+sv_respawnprotect 1 +sv_spawnfarthest 1")

        -- Name your agent and select color
        -- colors: 0 - green, 1 - gray, 2 - brown, 3 - red, 4 - light gray, 5 - light brown, 6 - light red, 7 - light blue
        --game:addGameArgs("+name WhoAmI +colorset 0")

        -- Actions
        assert(opt.nActions == 3, "nActions must be "..3) -- no up/down left/right delta
        self.nActions = opt.nActions
        local actionTable = {
            {1, 0, 0},
            {0, 1, 0},
            {0, 0, 1},
        }
        self.convertActionIndex = function(actionIndex)
            return actionTable[actionIndex]
        end
        -- #repeate actions
        self.actrep = opt.actrep or 4

        -- #built-in bots
        self.nBots = opt.nBots or 3
        if self.nBots > 3 then self.nBots = 3 end

        -- game mode
        if opt.isSpectator == true then
            game:setMode(vizdoom.Mode.SPECTATOR)
        else
            game:setMode(vizdoom.Mode.PLAYER)
        end

        -- Initialize the game. Further configuration won't take any effect from now on.
        game:init()

        self.game = game

        -- interested reward when evaluating time
        self.evalGameVar = opt.evalGameVar or 'FRAGCOUNT'
        self:training()
    end

    function EnvVizdoomRocketBasic:start()
        self.game:sendGameCommand("removebots")
        for i = 1, self.nBots do
            self.game:sendGameCommand("addbot")
        end

        self.game:newEpisode()

        -- init reward
        self.reward = 0
        -- measurements
        self['FRAGCOUNT'] = nil
        self['KILLCOUNT'] = nil
        self['ITEMCOUNT'] = nil
        self['HEALTH'] = nil
        self['SELECTED_WEAPON_AMMO'] = nil
    end

    function EnvVizdoomRocketBasic:getState()
        local obs
        if self:getTerminal() == 0 then

            local state = self.game:_getState()

            if not state.screenBuffer then
                obs = self:createNullScreen()
            else
                obs = self:convertScreen(state.screenBuffer)
            end
        else
            obs = self:createNullScreen()
        end
        return obs
    end

    function EnvVizdoomRocketBasic:getReward()
        local function sgn(x)
            if x < 0 then return -1 end
            if x > 0 then return 1 end
            return 0
        end

        local function getGameVariableAndUpdate (name)
            local curVar = self.game:getGameVariable(vizdoom.GameVariable[name])
            self[name] = self[name] and self[name] or curVar
            local varDelta = curVar - self[name]
            self[name] = curVar

            return varDelta
        end

        -- return instant reward
        local reward = self.reward

        --if self.isShapingReward then -- count all "measurements" as rewards
        --    local r = {
        --        2*sgn(getGameVariableAndUpdate('FRAGCOUNT')),
        --    }
        --
        --    for _, value in ipairs(r) do reward = reward + value end
        --else -- count only one interested reward
        --    reward = reward + getGameVariableAndUpdate(self.evalGameVar)
        --end

        return reward
    end

    function EnvVizdoomRocketBasic:getTerminal()
        local terminal = self.game:isEpisodeFinished()
        return (terminal==true) and 1 or 0
    end

    function EnvVizdoomRocketBasic:takeAction(actionIndex)
        -- make action & get reward
        local a = self.convertActionIndex(actionIndex)
        self.reward = self.game:makeAction(a, self.actrep)

        if self.game:isPlayerDead() then
            -- Respawn immediately after death, new state will be available.
            self.game:respawnPlayer()
        end
    end

    --
    function EnvVizdoomRocketBasic:training()
        self.isShapingReward = true
    end

    function EnvVizdoomRocketBasic:evaluate()
        self.isShapingReward = false
    end

    -- for reporting
    function EnvVizdoomRocketBasic:tostring()
        local str = ''

        -- this player
        local id = self.game:getGameVariable(vizdoom.GameVariable.PLAYER_NUMBER)
        str = str .. 'this player: '..(id+1)..'\n'

        -- list frags for all
        local n = self.game:getGameVariable(vizdoom.GameVariable.PLAYER_COUNT)

        for i = 1, n do
            local varName = ('PLAYER%d_FRAGCOUNT'):format(i)
            local frag = self.game:getGameVariable(vizdoom.GameVariable[varName])
            str = str .. ('player %d, frag %d\n'):format(i, frag)
        end
        return str
    end

    -- helpers
    function EnvVizdoomRocketBasic:convertScreen(screenBuffer)
        local obs = torch.ByteTensor(3*120*160)
        ffi.copy(obs:data(), screenBuffer, 3*120*160)

        obs = obs:view(120, 160, 3)
            :permute(3, 1, 2)
            :index(1, torch.LongTensor{3, 2, 1})

        return obs
    end

    function EnvVizdoomRocketBasic:createNullScreen()
        local obs = torch.zeros(3, 120, 160):byte()
        return obs
    end
end -- class def

-- class factory
local function create(opt)
    return EnvVizdoomRocketBasic(opt)
end
return create