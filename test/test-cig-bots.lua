require "vizdoom"
require "torch"
require "sys"
print = require'util.logPrint'({logPath = 'log-test-cig-bots'})

local vizdoomPath = '/home/ps/torch/install/lib/lua/5.1/vizdoom'
local isShow = true
local actrep = 4
local maxSteps = 250*1000*1000

-- Create DoomGame instance. It will run the game and communicate with you.
local game = vizdoom.DoomGame()

game:setViZDoomPath(paths.concat(vizdoomPath, 'vizdoom'))
game:loadConfig(paths.concat(vizdoomPath, "scenarios/mycig.cfg"))
game:setDoomMap("map01") -- Limited deathmatch.

-- Start multiplayer game only with your AI (with options that will be used in the competition, details in cig_host example).
game:addGameArgs("-host 1 -deathmatch +timelimit 4.0 "..
                 "+sv_forcerespawn 1 +sv_noautoaim 1 "..
                 "+sv_respawnprotect 1 +sv_spawnfarthest 1")

game:addGameArgs("+name WhoAmI +colorset 0")

game:setMode(vizdoom.Mode.SPECTATOR);
--game:setMode(vizdoom.Mode.PLAYER);

game:setWindowVisible(isShow)

game:init();

-- Three example sample actions
local actions = {
    [1] = torch.IntTensor({1,0,0,0,0,0,0,0,0}),
    [2] = torch.IntTensor({0,1,0,0,0,0,0,0,0}),
    [3] = torch.IntTensor({0,0,1,0,0,0,0,0,0}),
    [4] = torch.IntTensor({0,0,0,1,0,0,0,0,0}),
    [5] = torch.IntTensor({0,0,0,0,1,0,0,0,0}),
    [6] = torch.IntTensor({0,0,0,0,0,1,0,0,0}),
    [7] = torch.IntTensor({0,0,0,0,0,0,1,0,0}),
    [8] = torch.IntTensor({0,0,0,0,0,0,0,1,0}),
    [9] = torch.IntTensor({0,0,0,0,0,0,0,0,1})
}

-- Play with this many bots
local bots = 7

-- Run this many episodes
local epSteps = 6300
local episodes = math.ceil(maxSteps/epSteps)

-- To be used by the main game loop
local state, reward

for i = 1, episodes do

    print("Episode #"..i)
    -- Add specific number of bots
    -- (file examples/bots.cfg must be placed in the same directory as the Doom executable file,
    -- edit this file to adjust bots).
    game:sendGameCommand("removebots")
    for i = 1, bots do
        game:sendGameCommand("addbot")
    end

    -- Play until the game (episode) is over.
    while not game:isEpisodeFinished() do

        if game:isPlayerDead() then
            -- Respawn immediately after death, new state will be available.
            --sys.sleep(4)
            game:respawnPlayer()
        end

        --require'mobdebug'.start()
        -- Analyze the state
        state = game:getState()

        -- Make a random action
        local action = actions[torch.random(#actions)]
        reward = game:makeAction(action, actrep)

        local str = ("Episodes %d, Frags: %d, #players %d\n"):format(
            i,
            game:getGameVariable(vizdoom.GameVariable.FRAGCOUNT),
            game:getGameVariable(vizdoom.GameVariable.PLAYER_COUNT)
        )

        print(str)
    end

    print("Episode finished.")
    print("************************")

    game:newEpisode()
end

game:close()
