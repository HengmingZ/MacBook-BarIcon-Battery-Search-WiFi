# BatteryBar: 3-in-1 Unified Status Bar for macOS

> A sleek, zero-overhead, privacy-first macOS menu bar application that fuses **Battery**, **Wi-Fi**, and **Spotlight** into a single micro-indicator with authentic frosted-glass floating popovers.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange?logo=swift)
![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(arm64)-black)
![UI](https://img.shields.io/badge/UI-Frosted%20Glass%20(Translucent)-purple)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Design Philosophy

On modern MacBooks (especially models with camera notches), top menu bar space is precious. The default macOS status bar scatters Battery, Wi-Fi, and Spotlight across multiple slots.

**BatteryBar** consolidates all three core indicators into one dynamic, Retina-crisp vector glyph:

```text
       ╭────────╮  <- Magnifier Rim = Circular Battery Ring Gauge
     ╭─╯ ╱ ⌒ ╲  ╰─╮  (Fills clockwise according to real-time battery level;
    │   │  ⌒  │   │   Glows emerald green when charging, amber-red when low)
    │    \ • /    │  <- Magnifier Lens Center = Real-time Wi-Fi Waves
     ╰─╮        ╭─╯
       ╰──┬─────╯
           \   <- Magnifier Handle = Spotlight Symbol
            \
```

---

## Features

### 1. 3-in-1 Unified Micro-Indicator
- **Magnifier Silhouette (Spotlight)**: A compact, rounded 45-degree handle.
- **Battery Gauge Rim (Battery)**: Dynamic circular gauge filling clockwise from 12 o'clock, adapting automatically to light/dark themes, battery percentage, and AC power status.
- **Inner Wave Emitter (Wi-Fi)**: An RF radiation arc centered inside the lens, reflecting real-time signal strength (RSSI) and network activity.

### 2. Authentic Translucent Frosted Glass Popover
- Built with **`NSVisualEffectView` (`.behindWindow` blending mode)** to achieve the exact translucent, real-time blurred frosted-glass look of native macOS Control Center widgets.
- **Pixel-Perfect Zero-Gap Alignment**: Calculates absolute screen physical coordinates to hug the menu bar icon precisely 3 pixels beneath, bypassing macOS notch margin bugs.
- **Subtle Glass Border**: Features a 0.5px light border and 16px smooth rounded corners.
- **Outside-Click Dismiss**: Smoothly and automatically fades out when clicking anywhere outside.

### 3. Instant Native Spotlight Invocation
- Clicking **`[Spotlight]`** in the popover card instantly closes the panel, releases window focus, and triggers `Cmd + Space` to summon the macOS Spotlight search bar immediately.

### 4. Streamlined Battery & Wi-Fi Cards
- **Battery Card**: Focused cleanly on core metrics—circular progress gauge, charging pulse indicator, exact percentage (e.g. `Battery: 83% (Charging)`), and power source (`AC Power`).
- **Wi-Fi Card**: Displays live connected network name (e.g. `Wi-Fi: YourNetwork`), signal bars, and raw RSSI values in dBm.

### 5. Drag-to-Reorder & Position Memory (Command + Drag)
- Powered by `statusItem.autosaveName = "BatteryBar"`.
- Simply hold down the **`Command`** key and drag the icon anywhere along the menu bar (e.g. to the right of your Input Method / Pinyin icon). macOS permanently remembers its exact placement even after restarts.

### 6. Enlarged Hit Targets & Hover Feedback
- Expanded touch boundaries for `[Battery]`, `[Wi-Fi]`, and `[Spotlight]` pill buttons with `.contentShape(Capsule())` to prevent transparent click misses.
- Embedded 42x42pt clickable targets on the battery ring and Wi-Fi symbol with subtle hover highlights.

---

## How to Remove Native macOS Icons from the Menu Bar (No SIP Disabling Required)

Because macOS protects `ControlCenter.app` via Signed System Volume (SSV), you do not need risky dylib injections or disabling SIP. Removing redundant native icons from your top **Menu Bar** (while keeping them fully functional inside the Control Center panel) is completely native and takes seconds:

### Method 1: Instant Drag-to-Remove (Fastest for Wi-Fi & Battery)
1. Hold down the **`Command (⌘)`** key on your keyboard.
2. Click and hold the native **Wi-Fi** or **Battery** icon on the top Menu Bar.
3. Drag it downwards off the Menu Bar until an `✕` icon appears next to the cursor, then release. The icon will be instantly removed from the Menu Bar!

### Method 2: Via System Settings (Required for Spotlight)
In macOS, configure the top **Menu Bar** (菜单栏) icon display settings:
1. Open **System Settings** -> **Menu Bar** (菜单栏, or run `open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"` in Terminal).
2. **Wi-Fi**: Set to **Don't Show in Menu Bar** (不在菜单栏显示).
3. **Battery**: Set to **Don't Show in Menu Bar** (不在菜单栏显示).
4. **Spotlight**: Set to **Don't Show in Menu Bar** (不在菜单栏显示).

> **Note**: These settings only remove the icons from the top **Menu Bar** to save notch screen space.

---

## Project Architecture

```text
modifyMacUI/
├── BatteryBar.app/                   # Pre-built standalone macOS application bundle
│   └── Contents/
│       ├── Info.plist               # App metadata, LSUIElement (no Dock icon), location usage
│       └── MacOS/BatteryBar         # Compiled arm64 release binary
├── Sources/
│   └── BatteryBar/
│       ├── BatteryService.swift     # Low-overhead IOKit power source & runloop monitoring
│       ├── WiFiService.swift        # CoreWLAN & CoreLocation network monitor
│       ├── BatteryIconRenderer.swift# High-DPI Bezier vector graphics renderer
│       ├── PopoverContentView.swift # Pure SwiftUI frosted-glass card interface
│       ├── StatusBarController.swift# NSStatusItem & CustomPanel floating window controller
│       └── main.swift               # Application lifecycle entry point
├── Package.swift                    # Swift Package Manager manifest
└── README.md                        # Project documentation
```

---

## Build & Run

### Prerequisites
- macOS 13.0 or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac
- Xcode Command Line Tools (`xcode-select --install`)

### Compile Release Binary
```bash
swift build -c release
```

### Bundle into App & Launch
```bash
mkdir -p BatteryBar.app/Contents/MacOS
cp .build/release/BatteryBar BatteryBar.app/Contents/MacOS/BatteryBar
chmod +x BatteryBar.app/Contents/MacOS/BatteryBar

# Run
open BatteryBar.app
```

### One-Click Package into DMG
```bash
./build_dmg.sh
```

---

## Auto-Start on Boot

BatteryBar is configured with dual auto-start mechanisms for reliability:

1. **System Login Items**:
   Registered under macOS **System Settings** -> **General** -> **Login Items & Extensions**.
2. **LaunchAgent Daemon**:
   Configured at `~/Library/LaunchAgents/com.custom.batterybar.plist` with `RunAtLoad = true`.

Manage via terminal:
```bash
# Re-register login item
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Users/ming-mac/Documents/sProject/modifyMacUI/BatteryBar.app", hidden:false, name:"BatteryBar"}'

# Remove login item
osascript -e 'tell application "System Events" to delete (every login item whose name is "BatteryBar")'
```

---

## Permissions & Privacy

- **100% User Space**: Operates with standard user permissions without disabling System Integrity Protection (SIP).
- **Wi-Fi SSID Display**: macOS requires location permission to display unredacted Wi-Fi network names (to prevent unauthorized geolocation fingerprinting). If not yet authorized, clicking the `Show SSID` button on the Wi-Fi card will prompt the native system permission dialog once.

---

## License

MIT License. Designed with care for macOS power users.
