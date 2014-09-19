--  TODO: When multiple apps match a letter, prefer to switch to apps
--  that are visible or on the same screen. Test with "Console.app".

-- Special bindings.
local special_bindings = {
    F = "Firefox",
    X = "Microsoft Excel",
    T = "iTerm",
}

-- Used to grab the first letter of an app title.
-- iTunes -> I, Microsoft Outlook -> O
local function first_letter(str)
    str = str.gsub(str, "Microsoft ", "")
    return string.upper(string.sub(str, 1, 1))
end

-- Find applications starting with this letter.
local function filter_apps(key)
    local apps = fnutils.filter(application.runningapplications(), function(a)
        local it_matches = key == first_letter(a:title()) or
                           a:title() == special_bindings[key]
        return  it_matches and
                a:kind() == 1 and   -- must be in the Dock
                #a:allwindows() > 0 -- must have live windows
    end)
    -- Apps with a special binding should be selected first.
    table.sort(apps, function(a, b)
        return a:title() == special_bindings[key]
    end)
    return apps
end

-- If multiple apps match the key, don't repeatedly select the
-- app that's already open.
local function cycle_apps(apps)
    local win = window.focusedwindow()
    local app = nil
    if win then app = win:application() end
    local current_app_index = nil
    for i, a in pairs(apps) do
        hydra.alert(a:title(), 1)
        if app and a:title() == app:title() then
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
    apps[index]:unhide()
    apps[index]:activate()
end

-- Guess which of the filtered apps are wanted, and focus it.
local function select_app(key)
    local apps = filter_apps(key)
    if #apps > 0 then
        cycle_apps(apps)
    else
        hydra.alert("No apps starting with " .. key .. ".", 1)
    end
end

-- Bind filter_apps to (almost) every alphanumeric key.
local alphanum = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
for i = 1, #alphanum do
    local char = alphanum:sub(i,i)
    ctrl_e:bind({}, char, function()
        select_app(char)
        ctrl_e:exit()
    end)
end
