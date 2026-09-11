import Foundation
import CoreWLAN
import CoreLocation

public struct WiFiInfo {
    public let isPoweredOn: Bool
    public let isConnected: Bool
    public let rssi: Int
    public let signalBars: Int
    public let ssid: String?
}

public final class WiFiService: NSObject, CLLocationManagerDelegate {
    public static let shared = WiFiService()
    
    public var onWiFiInfoChanged: ((WiFiInfo) -> Void)?
    private var timer: Timer?
    private var locationManager: CLLocationManager?
    
    public override init() {
        super.init()
        setupLocationManager()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func setupLocationManager() {
        let manager = CLLocationManager()
        manager.delegate = self
        self.locationManager = manager
    }
    
    public func requestLocationPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let info = getCurrentWiFiInfo()
        onWiFiInfoChanged?(info)
    }
    
    public func getCurrentWiFiInfo() -> WiFiInfo {
        guard let iface = CWWiFiClient.shared().interface() else {
            return WiFiInfo(isPoweredOn: false, isConnected: false, rssi: -100, signalBars: 0, ssid: nil)
        }
        
        let powerOn = iface.powerOn()
        let rssi = iface.rssiValue()
        var ssid = iface.ssid()
        if ssid == nil || ssid?.isEmpty == true || ssid == "<redacted>" {
            ssid = nil
        }
        
        let isConnected = powerOn && rssi > -95
        
        let bars: Int
        if !powerOn || !isConnected {
            bars = 0
        } else if rssi >= -60 {
            bars = 3
        } else if rssi >= -75 {
            bars = 2
        } else {
            bars = 1
        }
        
        return WiFiInfo(
            isPoweredOn: powerOn,
            isConnected: isConnected,
            rssi: rssi,
            signalBars: bars,
            ssid: ssid
        )
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let info = self.getCurrentWiFiInfo()
            self.onWiFiInfoChanged?(info)
        }
    }
}
