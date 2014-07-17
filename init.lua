require "switch"
package.loaded["switch"] = nil   

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
