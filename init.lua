hydra.alert("Hydra config loaded.", 1)

pathwatcher.new(os.getenv("HOME") .. "/.hydra/", hydra.reload):start()

hotkey.bind({"cmd", "ctrl", "shift"}, "R", repl.open)

menu.show(function()
    return {
      {title = "Reload", fn = hydra.reload},
      {title = "-"},
      {title = "About", fn = hydra.showabout},
      {title = "Quit", fn = os.exit},
    }
end)

-- Set modal keys.
local function set_modal_key(char, message)
    key = modalkey.new({"ctrl"}, char)
    key:bind({}, "ESCAPE", function() key:exit() end)
    key:bind({"ctrl"}, char, function() key:exit() end)
    return key
end
ctrl_e = set_modal_key("E")
ctrl_r = set_modal_key("R")

require "switch"
package.loaded["switch"] = nil   

-- Resize
require "grid"
package.loaded["grid"] = nil

local function wrap(fn, str)
    return function()
        hydra.alert(str, 1); fn()
    end
end

ctrl_r:bind({}, "[", ext.grid.pushwindow_prevscreen)
ctrl_r:bind({}, "]", ext.grid.pushwindow_nextscreen)
ctrl_r:bind({}, "H", wrap(ext.grid.pushwindow_left, "←"))
ctrl_r:bind({}, "J", wrap(ext.grid.pushwindow_down, "↓"))
ctrl_r:bind({}, "K", wrap(ext.grid.pushwindow_up, "↑"))
ctrl_r:bind({}, "L", wrap(ext.grid.pushwindow_right, "→"))
ctrl_r:bind({"shift"}, "L", ext.grid.resizewindow_wider)
ctrl_r:bind({"shift"}, "H", ext.grid.resizewindow_thinner)
ctrl_r:bind({"shift"}, "K", ext.grid.resizewindow_shorter)
ctrl_r:bind({"shift"}, "J", ext.grid.resizewindow_taller)
