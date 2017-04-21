require'torch'
require'util.TableRingBuffer'

do -- class def
    local MemoryReplayRecentMinibatch = torch.class('MemoryReplayRecentMinibatch')

    function MemoryReplayRecentMinibatch:__init(opt)
        local opt = opt or {}
        self.stateDim = opt.stateDim or error('no opt.stateDim')
        self.nCombo = opt.nCombo or error('no opt.nCombo')
        self.cap = opt.capacity or error('no opt.capacity')
        self:reset()
    end

    function MemoryReplayRecentMinibatch:reset()
        local sentinal = self.nCombo
        self.sBuf = TableRingBuffer(self.cap)
        self.aBuf = TableRingBuffer(self.cap)
        self.rBuf = TableRingBuffer(self.cap)
    end

    -- push
    function MemoryReplayRecentMinibatch:pushState(s)
        if self.sBuf:size() == 0 then
            for i = 1, self.cap - 1 do
                self.sBuf:push(torch.Tensor():typeAs(s):resizeAs(s):zero())
            end
        end

        self.sBuf:push(s:clone())
    end

    function MemoryReplayRecentMinibatch:pushAction(a)
        if self.aBuf:size() == 0 then
            for i = 1, self.cap -1 do
                self.aBuf:push( 0 )
            end
        end

        self.aBuf:push(a)
    end

    function MemoryReplayRecentMinibatch:pushReward(r)
        if self.rBuf:size() == 0 then
            for i = 1, self.cap -1 do
                self.rBuf:push( 0 )
            end
        end

        self.rBuf:push(r)
    end

    -- get
    function MemoryReplayRecentMinibatch:topStateCombo()
        local stateCombo = torch.cat(self.sBuf:top(self.nCombo), 1)
        stateCombo:resize(1, stateCombo:size(1), stateCombo:size(2), stateCombo:size(3))
        return stateCombo:clone()
    end

    function MemoryReplayRecentMinibatch:getStateComboAt(idx)
        local stateCombo = torch.cat(self.sBuf:getAt(idx, self.nCombo), 1)
        stateCombo:resize(1, stateCombo:size(1), stateCombo:size(2), stateCombo:size(3))
        return stateCombo:clone()
    end

    function MemoryReplayRecentMinibatch:getRecentMinibatch(nPrev)
        local nPrev = nPrev or 1
        local idx = self.sBuf:size()

        -- get s, a, r mini batch
        local s = torch.FloatTensor(nPrev, self.stateDim[1]*self.nCombo, self.stateDim[2], self.stateDim[3])
        local a = torch.FloatTensor(nPrev)
        local r = torch.FloatTensor(nPrev)

        local j = 0
        for i = idx - nPrev + 1, idx, 1 do
            j = j + 1

            s[j]:copy( torch.cat(self.sBuf:getAt(i - 1, self.nCombo), 1) )
            a[j] = self.aBuf:getAt(i)[1]
            r[j] = self.rBuf:getAt(i)[1]
        end

        return s, a, r
    end

    function MemoryReplayRecentMinibatch:capacity()
        return self.cap
    end

end -- class def

local function create(opt)
    return MemoryReplayRecentMinibatch(opt)
end
return create
