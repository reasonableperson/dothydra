ext.grid = {}

MARGINX = 0
MARGINY = 0
GRIDWIDTH = 6
GRIDHEIGHT = 4

-- [ UTILITY ] --

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function get_grid(win)
    local win = win or window.focusedwindow()
    if not win then hydra.alert("noop") end
    local winframe = win:frame()
    local screenrect = win:screen():frame_without_dock_or_menu()
    local widthdelta = screenrect.w / GRIDWIDTH
    local heightdelta = screenrect.h / GRIDHEIGHT
    return {
        x = round((winframe.x - screenrect.x) / widthdelta),
        y = round((winframe.y - screenrect.y) / heightdelta),
        w = math.max(1, round(winframe.w / widthdelta)),
        h = math.max(1, round(winframe.h / heightdelta)),
    }
end

-- These need to be grouped together because the screen size
-- helps determine what the window size will be.
local function set_grid_and_screen(grid, screen, win)
    -- default args
    win = win or window.focusedwindow()
    screen = screen or win:screen()

    local screenrect = screen:frame_without_dock_or_menu()
    local widthdelta = screenrect.w / GRIDWIDTH
    local heightdelta = screenrect.h / GRIDHEIGHT
    local newframe = {
        x = (grid.x * widthdelta) + screenrect.x,
        y = (grid.y * heightdelta) + screenrect.y,
        w = grid.w * widthdelta,
        h = grid.h * heightdelta,
    }
    newframe.x = newframe.x + MARGINX
    newframe.y = newframe.y + MARGINY
    newframe.w = newframe.w - (MARGINX * 2)
    newframe.h = newframe.h - (MARGINY * 2)
    win:setframe(newframe)
end

local function snap_all(win)
    fnutils.map(window.visiblewindows(), function(win) 
        if win:isstandard() then
            set_grid_and_screen(get_grid(win), win:screen(), win)
        end
    end)
end

local function adjust_width(by)
    GRIDWIDTH = math.max(1, GRIDWIDTH + by)
    hydra.alert("grid is now " .. tostring(GRIDWIDTH) .. " tiles wide", 1)
    fnutils.map(window.visiblewindows(), snap)
end

local function grid_map(mutator)
    local grid = get_grid()
    mutator(grid)
    set_grid_and_screen(grid)
end

function maximize_window()
    local f = {x = 0, y = 0, w = GRIDWIDTH, h = 2}
    set_grid_and_screen(f)
end

local function screen_right()
    local win = win or window.focusedwindow()
    set_grid_and_screen(get_grid(), win:screen():next(), win)
    grid_map(function(f)
        f.x = 0
    end)
end

local function screen_left()
    local win = win or window.focusedwindow()
    set_grid_and_screen(get_grid(), win:screen():previous(), win)
    grid_map(function(f)
        f.x = GRIDWIDTH - f.w
    end)
end

local function go_down()
    grid_map(function(f)
        f.y = math.min(f.y + 1, GRIDHEIGHT)
    end)
end

local function go_up()
    grid_map(function(f)
        f.y = math.min(f.y - 1, GRIDHEIGHT - f.y)
    end)
end

-- Resize the window, or do nothing if we've hit a grid boundary.
-- We won't actually bind to these, because...
local function wider()
    grid_map(function(grid)
        grid.w = math.min(grid.w + 1, GRIDWIDTH)
    end)
end
local function thinner()
    grid_map(function(f)
        f.w = math.max(f.w - 1, 1)
    end)
end
local function taller()
    grid_map(function(f)
        f.h = math.min(f.h + 1, GRIDHEIGHT)
    end)
end
local function shorter()
    grid_map(function(f)
        f.h = math.max(f.h - 1, 1)
    end)
end

-- Bindings work differently when we're at the screen edges.
local function edge_is (testFunc, grid)
    grid = grid or get_grid()
    return testFunc(grid)
end

local function at_left (grid)
    return grid.x == 0 end

local function at_bottom (grid)
    return grid.y == GRIDHEIGHT - grid.x end

local function at_right (grid)
    return grid.x == GRIDWIDTH - grid.w end

-- Here are the functions we'll actually bind.
local function go_left()
    if edge_is(at_left) then screen_left()
    else grid_map(function (f)
        f.x = math.max(f.x - 1, 0)
    end) end
end

local function go_right()
    if edge_is(at_right) then screen_right()
    else grid_map(function (f)
        f.x = math.min(f.x + 1, GRIDWIDTH - f.w)
    end) end
end

local function resize_right()
    if edge_is(at_right)
    then thinner(); go_right()
    else wider() end
end

local function resize_left()
    if edge_is(at_right)
    then go_left(); wider()
    else thinner() end
end

local function resize_up()
    if edge_is(at_bottom)
    then go_up(); taller()
    else shorter() end
end

local function resize_down()
    if edge_is(at_bottom)
    then shorter(); go_down()
    else taller() end
end

-- And now we will actually bind them.
ctrl_r:bind({}, "S", snap_all)
ctrl_r:bind({}, "H", go_left)
ctrl_r:bind({}, "L", go_right)
ctrl_r:bind({}, "J", go_down)
ctrl_r:bind({}, "K", go_up)
ctrl_r:bind({"shift"}, "H", resize_left)
ctrl_r:bind({"shift"}, "J", resize_down)
ctrl_r:bind({"shift"}, "K", resize_up)
ctrl_r:bind({"shift"}, "L", resize_right)
