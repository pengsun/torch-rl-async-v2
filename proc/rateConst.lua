local function create(args)
    local const = args.const or error('')

    local function schedule()
        return const
    end
    return schedule
end

return create
