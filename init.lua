hydra.alert("Hydra config loaded.", 1)

-- Reload config on hotkey or config write.
pathwatcher.new(os.getenv("HOME") .. "/.hydra/", hydra.reload):start()
hotkey.bind({"cmd", "ctrl"}, "R", hydra.reload)

-- Configure menu.
hydra.menu.show(function() return {
    {title = "Reload", fn = hydra.reload},
    {title = "Quit", fn = os.exit},
} end)

-- Default configuration for all modal keys.
local function create_modal_key(char, message)
    key = hotkey.modal.new({"ctrl"}, char)
    key.entered = hydra.menu.highlight
    key.exited = hydra.menu.unhighlight
    hotkey.bind({"cmd", "ctrl"}, "W", hydra.menu.unhighlight)
    key:bind({}, "ESCAPE", function() key:exit() end)
    key:bind({"ctrl"}, char, function() key:exit() end)
    return key
end
ctrl_e = create_modal_key("E")
ctrl_r = create_modal_key("R")

require "switch"
package.loaded["switch"] = nil   

require "grid"
package.loaded["grid"] = nil
