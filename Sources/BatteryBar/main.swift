import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let statusBar = StatusBarController()
NSLog("[BatteryBar] BatteryBar status bar controller initialized.")

app.run()
