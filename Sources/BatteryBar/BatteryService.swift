import Foundation
import IOKit.ps

public struct BatteryInfo {
    public let level: Int
    public let isCharging: Bool
    public let isFullyCharged: Bool
    public let powerSource: String
    public let timeRemainingMinutes: Int?
    public let maxCapacity: Int
    public let currentCapacity: Int
}

public final class BatteryService {
    public static let shared = BatteryService()
    
    public var onBatteryInfoChanged: ((BatteryInfo) -> Void)?
    
    private var runLoopSource: CFRunLoopSource?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func getCurrentBatteryInfo() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatteryInfo(
                level: 100,
                isCharging: false,
                isFullyCharged: false,
                powerSource: "Unknown",
                timeRemainingMinutes: nil,
                maxCapacity: 100,
                currentCapacity: 100
            )
        }
        
        var currentCap = 100
        var maxCap = 100
        var isCharging = false
        var isCharged = false
        var powerSource = "Battery"
        var timeRemaining: Int? = nil
        
        for source in sources {
            // 注意：IOPSGetPowerSourceDescription 遵循 Get Rule，必须使用 takeUnretainedValue
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            if let cur = desc[kIOPSCurrentCapacityKey] as? Int {
                currentCap = cur
            }
            if let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 {
                maxCap = max
            }
            if let charging = desc[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }
            if let charged = desc[kIOPSIsChargedKey] as? Bool {
                isCharged = charged
            }
            if let sourceState = desc[kIOPSPowerSourceStateKey] as? String {
                powerSource = (sourceState == kIOPSACPowerValue) ? "AC Power" : "Battery"
            }
            if let time = desc[kIOPSTimeToEmptyKey] as? Int, time > 0 {
                timeRemaining = time
            } else if let time = desc[kIOPSTimeToFullChargeKey] as? Int, time > 0 {
                timeRemaining = time
            }
        }
        
        let percent = maxCap > 0 ? Int((Double(currentCap) / Double(maxCap)) * 100.0) : 100
        let clampedPercent = max(0, min(100, percent))
        
        return BatteryInfo(
            level: clampedPercent,
            isCharging: isCharging,
            isFullyCharged: isCharged,
            powerSource: powerSource,
            timeRemainingMinutes: timeRemaining,
            maxCapacity: maxCap,
            currentCapacity: currentCap
        )
    }
    
    private func startMonitoring() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let source = IOPSNotificationCreateRunLoopSource({ info in
            guard let info = info else { return }
            let service = Unmanaged<BatteryService>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async {
                let latestInfo = service.getCurrentBatteryInfo()
                service.onBatteryInfoChanged?(latestInfo)
            }
        }, context).takeRetainedValue()
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        self.runLoopSource = source
    }
    
    private func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
    }
}
