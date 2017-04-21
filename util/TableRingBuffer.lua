-- ring buffer, table as underlying storage
require'torch'

local TableRingBuffer = torch.class('TableRingBuffer')

function TableRingBuffer:__init(cap)
    self.cap = cap or error('no cap')
    self:reset()
end

function TableRingBuffer:reset()
    self.xBuf = {}
    self.pos = 0
    self.sz = 0
end

function TableRingBuffer:push(x)
    table.insert(self.xBuf, x)

    if #self.xBuf > self.cap then
        table.remove(self.xBuf, 1) -- ring buffer
    end
end

function TableRingBuffer:top(nPrev)
    return self:getAt(#self.xBuf, nPrev)
end

function TableRingBuffer:getAt(ind, nPrev)
    local nPrev = nPrev or 1
    local x = {}
    for i = ind-nPrev+1, ind, 1 do
        table.insert(x, self.xBuf[i])
    end
    return x
end

function TableRingBuffer:zeroAt(ind, nPrev)
    local nPrev = nPrev or 1
    for i = ind-nPrev+1, ind, 1 do
        if type(self.xBuf[i]) == 'number' then
            self.xBuf[i] = 0
        else -- tensor
            self.xBuf[i]:zero()
        end
    end
end

function TableRingBuffer:size()
    return #self.xBuf
end
