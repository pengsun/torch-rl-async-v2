require'torch'

do -- class def

  local EnvCatch = torch.class('EnvCatch')

  -- main interface
  function EnvCatch:__init(opts)
    local opts = opts or {}

    -- actions
    assert(opts.nActions == 2, "#actions = 2")

    -- show?
    self.isShow = opts.isShow

    -- Difficulty level
    self.level = opts.level or 2
    -- Probability of screen flickering
    self.flickering = opts.flickering or 0
    self.flickered = false
    -- Obscured
    self.obscured = opts.obscured or false

    -- Width and height
    self.size = 24
    self.screen = torch.FloatTensor(1, self.size, self.size):zero()
    self.blank = torch.FloatTensor(1, self.size, self.size):zero()
    assert(opts.stateDim[1] == 1)
    assert(opts.stateDim[2] == self.size)
    assert(opts.stateDim[3] == self.size)

    -- Player params/state
    self.player = {
      width = opts.playerWidth or math.ceil(self.size / 12)
    }
    -- Ball
    self.ball = {}
  end

  function EnvCatch:start()
      -- Reset player and ball
      self.player.x = math.ceil(self.size / 2)
      self.ball.x = torch.random(self.size)
      self.ball.y = 1
      -- Choose new trajectory
      self.ball.gradX = torch.uniform(-1/3, 1/3)*(1 - self.level)

      -- Redraw screen
      self:redraw()

      self.reward = 0

      self.terminal = false
  end

  function EnvCatch:getState()
    return self.screen
  end

  function EnvCatch:getReward()
    return self.reward
  end

  function EnvCatch:getTerminal()
    return self.terminal == true and 1 or 0
  end

  function EnvCatch:takeAction(action)
    -- Reward is 0 by default
    self.reward = 0

    -- Move player (0 is no-op)
    if action == 1 then
      self.player.x = math.max(self.player.x - 1, 1)
    elseif action == 2 then
      self.player.x = math.min(self.player.x + 1, self.size - self.player.width + 1)
    end

    -- Move ball
    self.ball.y = self.ball.y + 1
    self.ball.x = self.ball.x + self.ball.gradX
    -- Bounce ball if it hits the side
    if self.ball.x >= self.size then
      self.ball.x = self.size
      self.ball.gradX = -self.ball.gradX
    elseif self.ball.x < 2 and self.ball.gradX < 0 then
      self.ball.x = 5/3
      self.ball.gradX = -self.ball.gradX
    end

    -- Check terminal condition
    self.terminal = false
    if self.ball.y == self.size then
      self.terminal = true
      -- Player wins if it caught ball
      if self.ball.x >= self.player.x and self.ball.x <= self.player.x + self.player.width - 1 then
        self.reward = 1
      end
    end

    -- Redraw screen
    self:redraw()

    -- Flickering
    if math.random() < self.flickering then
      self.screen = self.blank
      self.flickered = true
    else
      self.flickered = false
    end

    if self.isShow then
      self.window = image.display{image = self.screen, win = self.window}
    end
  end

  function EnvCatch:training()
  end

  function EnvCatch:evaluate()
  end

  -- helpers
  function EnvCatch:getStateSpec()
    return {'int', {1, self.size, self.size}, {0, 1}}
  end

  function EnvCatch:getActionSpec()
    return {'int', 1, {0, 2}}
  end

  function EnvCatch:getDisplaySpec()
    return {'real', {3, self.size, self.size}, {0, 1}}
  end

  function EnvCatch:getRewardSpec()
    return 0, 1
  end

  function EnvCatch:redraw()
    -- Reset screen
    self.screen:zero()
    -- Draw ball
    self.screen[{{1}, {self.ball.y}, {self.ball.x}}] = 1
    -- Draw player
    self.screen[{{1}, {self.size}, {self.player.x, self.player.x + self.player.width - 1}}] = 1

    -- Obscure screen?
    if self.obscured then
      local barrier = math.ceil(self.size / 4)
      self.screen[{{1}, {self.size-barrier, self.size-1}, {}}] = 0
    end
  end

  function EnvCatch:getDisplay()
    if self.flickered then
      return torch.repeatTensor(self.blank, 3, 1, 1)
    else
      return torch.repeatTensor(self.screen, 3, 1, 1)
    end
  end

end -- class def

local function create(opt)
  return EnvCatch(opt)
end
return create