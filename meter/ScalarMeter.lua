require'torch'

local verysmall = 1e-12

local ScalarMeter = torch.class('ScalarMeter')

function ScalarMeter:__init()
    self:reset()
end

-- main
function ScalarMeter:reset()
    self.s = {}
end

function ScalarMeter:add(value)
    table.insert(self.s, value)
    return self
end

-- access
function ScalarMeter:getAt(ind)
    return self.s[ind]
end

function ScalarMeter:getLast()
    return self:getAt( self:num() )
end

-- statistics
function ScalarMeter:num()
    return #self.s
end

function ScalarMeter:sum()
    local t = torch.Tensor(self.s)
    return t:sum()
end

function ScalarMeter:mean()
    return self:sum() / (verysmall + self:num())
end

function ScalarMeter:max()
    local t = torch.Tensor(self.s)
    return t:max()
end