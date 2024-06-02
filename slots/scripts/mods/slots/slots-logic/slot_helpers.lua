local mod = get_mod("slots")

function mod:echo_table(tbl)
    for k, v in pairs(tbl) do
        self:echo(string.format("%s: %s", tostring(k), tostring(v)))
    end
end

function unit_alive(unit)
    return ALIVE[unit]
end

function log_argument_types_and_values(...)
    local args = {...}
    for i, arg in ipairs(args) do
        mod:echo(string.format("Argument %d: %s (type: %s)", i, tostring(arg), type(arg)))
    end
end

function debug_print_table(tbl, name)
    if tbl then
        mod:echo(name .. " contents:")
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                mod:echo(tostring(k) .. ": table: " .. tostring(v))
                for sub_k, sub_v in pairs(v) do
                    mod:echo("  " .. tostring(sub_k) .. ": " .. tostring(sub_v))
                end
            else
                mod:echo(tostring(k) .. ": " .. tostring(v))
            end
        end
    else
        mod:echo(name .. " is nil")
    end
end

function debug_print_table_contents(tbl, tbl_name)
    if not tbl then
        mod:echo(string.format("%s is nil", tbl_name))
        return
    end

    for key, value in pairs(tbl) do
        mod:echo(string.format("%s[%s] = %s", tbl_name, tostring(key), tostring(value)))
    end
end
