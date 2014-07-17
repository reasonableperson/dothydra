-- Special bindings.
local special_bindings = {
    X = "Excel",
    T = "iTerm",
    W = "VMware Fusion",
    V = "Cisco AnyConnect Secure Mobility Client"
}

-- Used to grab the first letter of an app title.
-- iTunes -> I, Microsoft Outlook -> O
local function first_letter(str)
    str = str.gsub(str, "Microsoft ", "")
    return string.upper(string.sub(str, 1, 1))
end

-- Find applications starting with this letter.
local function filter_apps(key)
    return fnutils.filter(application.runningapplications(), function(a)
        local it_matches = key == first_letter(a:title()) or
                           a:title() == special_bindings[key]
        return  it_matches and
                a:kind() == 1 and   -- must be in the Dock
                #a:allwindows() > 0 -- must have live windows
    end)
end

-- If multiple apps match the key, don't repeatedly select the
-- app that's already open.
local function cycle_apps(apps)
    local current_app = window.focusedwindow():application()
    local current_app_index = nil
    for i, a in pairs(apps) do
        if a:title() == current_app:title() then
            current_app_index = i
        end
    end
    local index = nil
    if not current_app_index then
        index = 1
    else
        index = current_app_index + 1
        if index > #apps then index = 1 end
    end
    apps[index]:activate()
end

-- Guess which of the filtered apps are wanted, and focus it.
local function select_app(initial)
    local apps = filter_apps(initial)
    if #apps == 1 then
        hydra.alert(apps[1]:title(), 1)
        local success = apps[1]:activate()
        if not success then hydra.alert("no windows?") end
    elseif #apps > 1 then
        cycle_apps(apps)
    else
        hydra.alert("No apps.", 1)
    end
end

-- Set modal key.
local modal = modalkey.new({"ctrl"}, "Y")
modal:bind({}, "ESCAPE", function() modal:exit() end)

-- Bind filter_apps to every alphanumeric key.
local alphanum = {}
for i=1,26  do alphanum[i] = string.char(i+64) end -- [a-z]
for i=27,36 do alphanum[i] = string.char(i+21) end -- [0-9]
for i=1,36 do
    modal:bind({}, alphanum[i], function()
        select_app(alphanum[i])
        modal:exit()
    end)
end
