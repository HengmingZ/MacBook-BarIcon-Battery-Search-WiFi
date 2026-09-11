import SwiftUI

public final class AppState: ObservableObject {
    @Published public var battery: BatteryInfo
    @Published public var wifi: WiFiInfo
    
    public init(battery: BatteryInfo, wifi: WiFiInfo) {
        self.battery = battery
        self.wifi = wifi
    }
}

public struct PopoverContentView: View {
    @ObservedObject var state: AppState
    var onTriggerSpotlight: () -> Void
    var onClose: () -> Void
    
    @State private var selectedTab: Int = 0
    
    public init(state: AppState, onTriggerSpotlight: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.state = state
        self.onTriggerSpotlight = onTriggerSpotlight
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // MARK: - Top 3-in-1 Capsule Selector
            HStack(spacing: 6) {
                TabButton(title: "Battery", icon: "battery.100.bolt", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Wi-Fi", icon: "wifi", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                // Spotlight button: Click to invoke native macOS Spotlight search bar
                Button(action: {
                    onClose()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onTriggerSpotlight()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Spotlight")
                            .font(.system(size: 11.5, weight: .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .contentShape(Capsule())
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // MARK: - Tab Content
            if selectedTab == 0 {
                BatteryDetailCard(battery: state.battery)
            } else if selectedTab == 1 {
                WiFiDetailCard(wifi: state.wifi)
            }
            
            Divider()
            
            // MARK: - Bottom Actions
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    if selectedTab == 0 {
                        openURL("x-apple.systempreferences:com.apple.Battery-Settings.extension")
                    } else {
                        openURL("x-apple.systempreferences:com.apple.wifi-settings-extension")
                    }
                }) {
                    HStack(spacing: 2) {
                        Text("Settings...")
                            .font(.system(size: 11))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 320)
        .background(Color.clear)
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Capsule Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? Color.primary.opacity(0.14)
                    : (isHovered ? Color.primary.opacity(0.08) : Color.white.opacity(0.001))
            )
            .foregroundColor(isSelected ? .primary : (isHovered ? .primary : .secondary))
            .contentShape(Capsule())
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Battery Detail Card
struct BatteryDetailCard: View {
    let battery: BatteryInfo
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Clickable Ring Gauge (42x42 hit area)
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.15), lineWidth: 4)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(battery.level) / 100.0)
                            .stroke(
                                battery.isCharging ? Color.green : (battery.level <= 20 ? Color.red : Color.primary),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        if battery.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("\(battery.level)%")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Battery: \(battery.level)%")
                            .font(.system(size: 13, weight: .semibold))
                        if battery.isCharging {
                            Text("(Charging)")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("Power Source: \(battery.powerSource)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Wi-Fi Detail Card
struct WiFiDetailCard: View {
    let wifi: WiFiInfo
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Clickable Wi-Fi Icon (42x42 hit area)
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: "wifi")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(wifi.isConnected ? .accentColor : .secondary)
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let ssid = wifi.ssid, !ssid.isEmpty {
                        Text("Wi-Fi: \(ssid)")
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    } else {
                        HStack(spacing: 6) {
                            Text(wifi.isConnected ? "Wi-Fi: Connected" : "Wi-Fi: Disconnected")
                                .font(.system(size: 13, weight: .semibold))
                            
                            if wifi.isConnected {
                                Button("Show SSID") {
                                    WiFiService.shared.requestLocationPermission()
                                }
                                .buttonStyle(.borderless)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    if wifi.isConnected {
                        Text("Signal: \(wifi.signalBars) Bars (RSSI: \(wifi.rssi) dBm)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Interface: Active")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if wifi.isConnected && wifi.ssid == nil {
                WiFiService.shared.requestLocationPermission()
            }
        }
    }
}
