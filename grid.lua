ext.grid = {}

ext.grid.MARGINX = 0
ext.grid.MARGINY = 0
ext.grid.GRIDWIDTH = 6
ext.grid.GRIDHEIGHT = 4

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ext.grid.get(win)
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

function ext.grid.set(win, grid, screen)
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

function ext.grid.snap(win)
  if win:isstandard() then
    ext.grid.set(win, ext.grid.get(win), win:screen())
  end
end

function ext.grid.adjustwidth(by)
  ext.grid.GRIDWIDTH = math.max(1, ext.grid.GRIDWIDTH + by)
  hydra.alert("grid is now " .. tostring(ext.grid.GRIDWIDTH) .. " tiles wide", 1)
  fnutils.map(window.visiblewindows(), ext.grid.snap)
end

local function adjust_focused_window(fn)
  local win = window.focusedwindow()
  local f = ext.grid.get(win)
  fn(f)
  ext.grid.set(win, f, win:screen())
end

function ext.grid.maximize_window()
  local win = window.focusedwindow()
  local f = {x = 0, y = 0, w = ext.grid.GRIDWIDTH, h = 2}
  ext.grid.set(win, f, win:screen())
end

function ext.grid.pushwindow_nextscreen()
  local win = window.focusedwindow()
  ext.grid.set(win, ext.grid.get(win), win:screen():next())
end

function ext.grid.pushwindow_prevscreen()
  local win = window.focusedwindow()
  ext.grid.set(win, ext.grid.get(win), win:screen():previous())
end

function ext.grid.pushwindow_left()
  adjust_focused_window(function(f) f.x = math.max(f.x - 1, 0) end)
end

function ext.grid.pushwindow_right()
  adjust_focused_window(function(f) f.x = math.min(f.x + 1, ext.grid.GRIDWIDTH - f.w) end)
end

function ext.grid.pushwindow_down()
  adjust_focused_window(function(f)
    f.y = math.min(f.y + 1, ext.grid.GRIDHEIGHT - f.y)
  end)
end

function ext.grid.pushwindow_up()
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

-- ...resize bindings work differently when we're at the bottom or right screen
-- edges. Let's detect those cases.
local function at_bottom()
  local win = window.focusedwindow()
  local f = ext.grid.get(win)
  return f.y ~= 0 and f.y + f.h == ext.grid.GRIDHEIGHT
end
local function at_right()
  local win = window.focusedwindow()
  local f = ext.grid.get(win)
  return f.x ~= 0 and f.x + f.w == ext.grid.GRIDWIDTH
end

-- Here are the functions we'll actually bind.
function ext.grid.resizewindow_right()
  hydra.alert("→", 1)
  if at_right(f) then thinner(f); ext.grid.pushwindow_right()
  else                wider(f) end
end
function ext.grid.resizewindow_left()
  hydra.alert("←", 1)
  if at_right(f) then wider(f); ext.grid.pushwindow_left()
  else                thinner(f) end
end
function ext.grid.resizewindow_up()
  hydra.alert("↑", 1)
  if at_bottom(f) then taller(f); ext.grid.pushwindow_up()
  else                 shorter(f) end
end
function ext.grid.resizewindow_down()
  hydra.alert("↓", 1)
  if at_bottom(f) then shorter(f); ext.grid.pushwindow_down()
  else                 taller(f) end
end

-- And now we will actually bind them.
ctrl_r:bind({}, "[", ext.grid.pushwindow_prevscreen)
ctrl_r:bind({}, "]", ext.grid.pushwindow_nextscreen)
ctrl_r:bind({}, "H", ext.grid.pushwindow_left)
ctrl_r:bind({}, "J", ext.grid.pushwindow_down)
ctrl_r:bind({}, "K", ext.grid.pushwindow_up)
ctrl_r:bind({}, "L", ext.grid.pushwindow_right)
ctrl_r:bind({"shift"}, "H", ext.grid.resizewindow_left)
ctrl_r:bind({"shift"}, "J", ext.grid.resizewindow_down)
ctrl_r:bind({"shift"}, "K", ext.grid.resizewindow_up)
ctrl_r:bind({"shift"}, "L", ext.grid.resizewindow_right)
