require "torch"

local function recursive_map(module, field, func)
    local str = ""
    if module[field] or module.modules then
        str = str .. torch.typename(module) .. ": "
    end
    if module[field] then
        str = str .. func(module[field])
    end
    if module.modules then
        str = str .. "["
        for i, submodule in ipairs(module.modules) do
            local submodule_str = recursive_map(submodule, field, func)
            str = str .. submodule_str
            if i < #module.modules and string.len(submodule_str) > 0 then
                str = str .. " "
            end
        end
        str = str .. "]"
    end

    return str
end

local function abs_mean(w)
    return torch.mean(torch.abs(w:clone():float()))
end

local function abs_max(w)
    return torch.abs(w:clone():float()):max()
end

local this = {}

-- Build a string of average absolute weight values for the modules in the
-- given network.
local tostringWeightNorms = function(module)
    return "Weight norms:\n" .. recursive_map(module, "weight", abs_mean) ..
            "\nWeight max:\n" .. recursive_map(module, "weight", abs_max)
end

-- Build a string of average absolute weight gradient values for the modules
-- in the given network.
local tostringGradNorms = function(module)
    return "Weight grad norms:\n" .. recursive_map(module, "gradWeight", abs_mean)..
            "\nWeight grad max:\n" .. recursive_map(module, "gradWeight", abs_max)
end

local tostringNorm = function(module)
    return  tostringWeightNorms(module)..'\n'..
            tostringGradNorms(module)
end

-- export
this.tostringWeightNorms = tostringWeightNorms
this.tostringGradNorms = tostringGradNorms
this.tostringNorm = tostringNorm
return this
