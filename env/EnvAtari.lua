require'nn' -- in case package.searchpath missing (in lua 5.1)... nn happens to fix it

local ok, framework = pcall(require, 'alewrap')
assert(ok==true, "install alewrap first!")

do -- class def
    local EnvAtari = torch.class('EnvAtari')

    function EnvAtari:__init(opt)
        -- game
        local options = {
            game_path = opt.romPath or 'env/atariRom',
            env = opt.gameName or 'breakout',
            actrep = opt.actRep or 4,
            random_starts = opt.randomStarts or 1,
            gpu = opt.envGpu and (opt.envGpu-1) or -1, -- GPU flag (GPU enables faster screen buffer with CudaTensors)
            pool_frms = { -- Defaults to 2-frame mean-pooling
                type = opt.poolFrmsType or 'max', -- Max captures periodic events e.g. blinking lasers
                size = opt.poolFrmsSize or 2 -- Pools over frames to prevent problems with fixed interval events as above
            }
        }
        self.gameEnv = framework.GameEnvironment(options)

        -- actions
        self.actionSpace = self.gameEnv:getActions()
        self.nActions = opt.nActions or error('no opt.nActions')
        assert(self.nActions == #self.actionSpace, "desired #actions "..#self.actionSpace)

        -- show?
        self.isShow = opt.isShow

        -- start random game
        self.isRandGame = opt.isRandGame

        self:training()
    end

    function EnvAtari:start()
        local screen, reward, terminal
        if self.isRandGame then
            self.screen, self.reward, self.terminal = self.gameEnv:nextRandomGame()
        else
            self.screen, self.reward, self.terminal = self.gameEnv:newGame()
        end
    end

    function EnvAtari:getState()
        return self.screen:select(1, 1)
    end

    function EnvAtari:getReward()
        return self.reward
    end

    function EnvAtari:getTerminal()
        return self.terminal and 1 or 0
    end

    function EnvAtari:takeAction(action, isTiming)
        if isTiming then
            local t = torch.tic()
            self.screen, self.reward, self.terminal = self.gameEnv:step(self.actionSpace[action], self.isTrain)
            t = torch.toc(t)
            print('raw game env step '..t)
        else
            self.screen, self.reward, self.terminal = self.gameEnv:step(self.actionSpace[action], self.isTrain)
        end

        if self.isShow then
            self.window = image.display{image = self.screen, win = self.window}
        end

    end

    function EnvAtari:training()
        self.isTrain = true
    end

    function EnvAtari:evaluate()
        self.isTrain = false
    end
end -- class def

local function create(opt)
    return EnvAtari(opt)
end
return create
