require'meter.ScalarMeter'
require'gnuplot'

gameName = 'breakout'

function loadCurve(algoName)
    local p = ('save/%s/%s-val-meters.t7'):format(algoName, gameName)
    local m = torch.load(p)
    local it = torch.Tensor(m.iter.s)
    local r = torch.Tensor(m.reward.s)

    return it, r
end

it1, r1 = loadCurve('atari-a3c')
it2, r2 = loadCurve('atari-a3c-lstm-ncombo4-T80M-update20')

gnuplot.plot(
    {'a3c-ff', it1, r1},
    {'a3c-lstm', it2, r2}
)
