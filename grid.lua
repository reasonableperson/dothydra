ext.grid = {}

ext.grid.MARGINX = 0
ext.grid.MARGINY = 0
ext.grid.GRIDWIDTH = 6
ext.grid.GRIDHEIGHT = 4

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
    local widthdelta = screenrect.w / ext.grid.GRIDWIDTH
    local heightdelta = screenrect.h / ext.grid.GRIDHEIGHT
    return {
        x = round((winframe.x - screenrect.x) / widthdelta),
        y = round((winframe.y - screenrect.y) / heightdelta),
        w = math.max(1, round(winframe.w / widthdelta)),
        h = math.max(1, round(winframe.h / heightdelta)),
    }
end

local function set_grid_and_screen(grid, screen, win)
    -- default args
    win = win or window.focusedwindow()
    screen = screen or win:screen()

    local screenrect = screen:frame_without_dock_or_menu()
    local widthdelta = screenrect.w / ext.grid.GRIDWIDTH
    local heightdelta = screenrect.h / ext.grid.GRIDHEIGHT
    local newframe = {
        x = (grid.x * widthdelta) + screenrect.x,
        y = (grid.y * heightdelta) + screenrect.y,
        w = grid.w * widthdelta,
        h = grid.h * heightdelta,
    }
    newframe.x = newframe.x + ext.grid.MARGINX
    newframe.y = newframe.y + ext.grid.MARGINY
    newframe.w = newframe.w - (ext.grid.MARGINX * 2)
    newframe.h = newframe.h - (ext.grid.MARGINY * 2)
    win:setframe(newframe)
end

local function snap(win)
    if win:isstandard() then
        set_grid_and_screen(get_grid(win), win:screen(), win)
    end
end

local function adjust_width(by)
    ext.grid.GRIDWIDTH = math.max(1, ext.grid.GRIDWIDTH + by)
    hydra.alert("grid is now " .. tostring(ext.grid.GRIDWIDTH) .. " tiles wide", 1)
    fnutils.map(window.visiblewindows(), snap)
end

local function adjust_focused_window(fn)
    local f = get_grid()
    fn(f)
    set_grid_and_screen(f)
end

function ext.grid.maximize_window()
    local f = {x = 0, y = 0, w = ext.grid.GRIDWIDTH, h = 2}
    set_grid_and_screen(f)
end

local function screen_right()
    local win = win or window.focusedwindow()
    set_grid_and_screen(get_grid(), win:screen():next(), win)
    adjust_focused_window(function(f)
        f.x = 0
    end)
end

local function screen_left()
    local win = win or window.focusedwindow()
    set_grid_and_screen(get_grid(), win:screen():previous(), win)
    adjust_focused_window(function(f)
        f.x = ext.grid.GRIDWIDTH - f.w
    end)
end

local function go_down()
    adjust_focused_window(function(f)
        f.y = math.min(f.y + 1, ext.grid.GRIDHEIGHT)
    end)
end

local function go_up()
    adjust_focused_window(function(f)
        f.y = math.min(f.y - 1, ext.grid.GRIDHEIGHT - f.y)
    end)
end

-- Resize the window, or do nothing if we've hit a grid boundary.
-- We won't actually bind to these, because...
local function wider()
  adjust_focused_window(function(f)
    f.w = math.min(f.w + 1, ext.grid.GRIDWIDTH)
  end)
end
local function thinner()
  adjust_focused_window(function(f)
    f.w = math.max(f.w - 1, 1)
  end)
end
local function taller()
  adjust_focused_window(function(f)
    f.h = math.min(f.h + 1, ext.grid.GRIDHEIGHT)
  end)
end
local function shorter()
  adjust_focused_window(function(f)
    f.h = math.max(f.h - 1, 1)
  end)
end

-- Bindings work differently when we're at the screen edges.
local function edge_is (testFunc)
    local f = get_grid(window.focusedwindow())
    return testFunc(f)
end
local function at_left(f)
    return f.x == 0 end
local function at_bottom (f)
    return f.y == ext.grid.GRIDHEIGHT - f.x end
local function at_right(f)
    return f.x == ext.grid.GRIDWIDTH - f.w end

-- Here are the functions we'll actually bind.
local function go_left()
    if edge_is(at_left) then screen_left()
    else adjust_focused_window(function (f)
        f.x = math.max(f.x - 1, 0)
    end) end
end

local function go_right()
    if edge_is(at_right) then screen_right()
    else adjust_focused_window(function (f)
        f.x = math.min(f.x + 1, ext.grid.GRIDWIDTH - f.w)
    end) end
end

function ext.grid.resize_right()
  hydra.alert("→", 1)
  if at_right(f) then thinner(f); ext.grid.screen_right()
  else                wider(f) end
end
function ext.grid.resize_left()
  hydra.alert("←", 1)
  if at_right(f) then wider(f); ext.grid.screen_left()
  else                thinner(f) end
end
function ext.grid.resize_up()
  hydra.alert("↑", 1)
  if at_bottom(f) then taller(f); ext.grid.go_up()
  else                 shorter(f) end
end
function ext.grid.resize_down()
  hydra.alert("↓", 1)
  if at_bottom(f) then shorter(f); ext.grid.go_down()
  else                 taller(f) end
end

-- And now we will actually bind them.
ctrl_r:bind({}, "H", go_left)
ctrl_r:bind({}, "L", go_right)
ctrl_r:bind({}, "J", go_down)
ctrl_r:bind({}, "K", go_up)
ctrl_r:bind({"shift"}, "H", ext.grid.resize_left)
ctrl_r:bind({"shift"}, "J", ext.grid.resize_down)
ctrl_r:bind({"shift"}, "K", ext.grid.resize_up)
ctrl_r:bind({"shift"}, "L", ext.grid.resize_right)
