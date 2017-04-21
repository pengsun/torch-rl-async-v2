local function logPrint(opt)
    local logPath = opt.logPath or error'no opt.logPath'
    local isTimeNow = opt.isTimeNow

    -- print time now?
    local strTimeNow
    if isTimeNow then
        strTimeNow = require'util.strTimeNow'
    end

    local old_print = print
    local pp = require'pl.pretty'

    local f_handle = assert(io.open(opt.logPath, 'w'),
        'cannot open file '..opt.logPath
    )
    return function (...)
        -- first print to screen
        if isTimeNow then old_print(strTimeNow()) end
        old_print(...)

        -- then print to file
        local function tbl_to_str(t, ident)
            local str = ""
            local ident = ident or ""

            for k, v in pairs(t) do
                local tp = torch.type(v)

                str = str .. ident .. k .. ": "
                if tp == 'table' then
                    str = str .. "\n" .. tbl_to_str(v, '  ' .. ident)
                elseif tp=='torch.FloatTensor' or tp=='torch.CudaTensor' or tp=='torch.LongTensor' or tp=='torch.DoubleTensor' then
                    str = str .. tostring(tp)
                else
                    str = str .. tostring(v)
                end
                str = str .. "\n"
            end
            return str
        end

        local str
        for i, item in ipairs({...}) do
            if torch.type(item)=='table' then
                str = tbl_to_str(item)
            else
                str = tostring(item)
            end

            if isTimeNow then old_print(strTimeNow()) end
            f_handle:write(str .. "\n")
            f_handle:flush()
        end
    end
end

return logPrint