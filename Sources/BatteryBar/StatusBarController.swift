import Cocoa
import SwiftUI

final class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}

public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var panel: CustomPanel!
    private var appState: AppState
    private var globalEventMonitor: Any?
    
    public override init() {
        let initialBattery = BatteryService.shared.getCurrentBatteryInfo()
        let initialWiFi = WiFiService.shared.getCurrentWiFiInfo()
        self.appState = AppState(battery: initialBattery, wifi: initialWiFi)
        super.init()
        
        setupStatusItem()
        setupPanel()
        setupListeners()
    }
    
    deinit {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // 允许参与菜单栏排序并持久化记忆位置（支持按住 Command 键随意拖拽排序）
        statusItem.autosaveName = "BatteryBar"
        
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePanel(_:))
            button.sendAction(on: [.leftMouseUp])
        }
        updateStatusBarIcon()
    }
    
    private func setupPanel() {
        let panelWidth: CGFloat = 320
        let panelHeight: CGFloat = 162
        
        panel = CustomPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow
        
        let contentView = PopoverContentView(
            state: appState,
            onTriggerSpotlight: { [weak self] in
                self?.hidePanel()
                self?.triggerSpotlightSearch()
            },
            onClose: { [weak self] in
                self?.hidePanel()
            }
        )
        
        // 原生透明磨砂玻璃层 (True Frosted Glass)
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow // 对窗口背后的桌面壁纸和窗口进行动态实时模糊混合
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 0.5
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = visualEffectView.bounds
        hostingView.autoresizingMask = [.width, .height]
        
        visualEffectView.addSubview(hostingView)
        panel.contentView = visualEffectView
    }
    
    private func setupListeners() {
        BatteryService.shared.onBatteryInfoChanged = { [weak self] newBattery in
            guard let self = self else { return }
            self.appState.battery = newBattery
            self.updateStatusBarIcon()
        }
        
        WiFiService.shared.onWiFiInfoChanged = { [weak self] newWiFi in
            guard let self = self else { return }
            self.appState.wifi = newWiFi
            self.updateStatusBarIcon()
        }
    }
    
    private func updateStatusBarIcon() {
        let image = UnifiedIconRenderer.render(battery: appState.battery, wifi: appState.wifi)
        statusItem.button?.image = image
    }
    
    @objc private func togglePanel(_ sender: AnyObject?) {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    private func showPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        
        // 1. 获取状态栏按钮在整个屏幕上的绝对物理位置
        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.bounds)
        let panelSize = panel.frame.size
        
        // 2. 严丝合缝定位：紧贴在图标正下方（仅预留 3 像素微隙，防止与菜单栏重叠）
        let targetX = buttonFrameOnScreen.midX - (panelSize.width / 2.0)
        let targetY = buttonFrameOnScreen.minY - 3.0
        
        // 防止弹窗超出屏幕右边缘
        if let screen = buttonWindow.screen {
            let maxX = screen.visibleFrame.maxX - panelSize.width - 8
            let minX = screen.visibleFrame.minX + 8
            let clampedX = max(minX, min(maxX, targetX))
            panel.setFrameTopLeftPoint(NSPoint(x: clampedX, y: targetY))
        } else {
            panel.setFrameTopLeftPoint(NSPoint(x: targetX, y: targetY))
        }
        
        // 3. 显示并置顶
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 4. 监听外部点击自动收起
        if globalEventMonitor == nil {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.hidePanel()
            }
        }
    }
    
    private func hidePanel() {
        panel.orderOut(nil)
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
    
    private func triggerSpotlightSearch() {
        // 0. 无辅助功能权限时主动弹系统授权框（CGEvent 注入无权限会被静默丢弃）
        if !AXIsProcessTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
            return
        }
        
        // 1. 释放焦点让前台系统恢复活跃状态
        NSApp.deactivate()
        
        // 2. 延迟 0.05 秒确保面板彻底收起后触发快捷事件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // 底层 CoreGraphics HID 按键注入（只发一次，重复触发会把 Spotlight 关掉）
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 49, keyDown: true)
            keyDown?.flags = .maskCommand
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 49, keyDown: false)
            keyUp?.flags = .maskCommand
            
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}
