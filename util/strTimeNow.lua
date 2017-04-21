local function strTimeNow()
    local now = os.date("*t")
    local tmpl = "%02d:%02d:%02d" .. "@" .. "%d-%d-%d"
    return string.format(tmpl,
        now.hour, now.min, now.sec,
        now.month, now.day, now.year
    )
end

return strTimeNow
