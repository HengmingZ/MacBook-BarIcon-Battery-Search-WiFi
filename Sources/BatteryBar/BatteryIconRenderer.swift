import Cocoa

public final class UnifiedIconRenderer {
    
    public static func render(battery: BatteryInfo, wifi: WiFiInfo) -> NSImage {
        let canvasWidth: CGFloat = 26.0
        let canvasHeight: CGFloat = 22.0
        
        let image = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight), flipped: false) { rect in
            // MARK: - 几何尺寸定义
            // 放大镜圆心与半径（微调放大圆框，为 WiFi 腾出更大内部空间）
            let center = CGPoint(x: 9.8, y: 11.8)
            let ringRadius: CGFloat = 7.6
            let ringLineWidth: CGFloat = 1.8
            
            // 1. 绘制小巧手柄 (Handle: 缩小长度与线宽)
            let handleStart = CGPoint(x: center.x + 5.1, y: center.y - 5.1)
            let handleEnd = CGPoint(x: center.x + 8.6, y: center.y - 8.6)
            
            let handlePath = NSBezierPath()
            handlePath.move(to: handleStart)
            handlePath.line(to: handleEnd)
            handlePath.lineWidth = 1.8
            handlePath.lineCapStyle = .round
            
            let strokeColor = NSColor.labelColor.withAlphaComponent(0.85)
            strokeColor.setStroke()
            handlePath.stroke()
            
            // 2. 绘制放大镜圆框 = 电池电量环 (Battery Ring Gauge)
            // 2.1 底层背景轨道 (淡色槽)
            let trackPath = NSBezierPath()
            trackPath.appendArc(withCenter: center, radius: ringRadius, startAngle: 0, endAngle: 360)
            trackPath.lineWidth = ringLineWidth
            NSColor.labelColor.withAlphaComponent(0.2).setStroke()
            trackPath.stroke()
            
            // 2.2 前景电量弧线
            let pct = max(0.02, min(1.0, CGFloat(battery.level) / 100.0))
            let startAngle: CGFloat = 90.0 // 12 点钟位置起步
            let sweepAngle = 360.0 * pct
            let endAngle = startAngle - sweepAngle // 顺时针递减
            
            let batteryArcPath = NSBezierPath()
            batteryArcPath.appendArc(withCenter: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            batteryArcPath.lineWidth = ringLineWidth
            batteryArcPath.lineCapStyle = .round
            
            // 电量状态配色
            let batteryColor: NSColor
            if battery.isCharging {
                batteryColor = NSColor.systemGreen // 充电荧光翠绿
            } else if battery.level <= 20 {
                batteryColor = NSColor.systemRed   // 低电量警示红
            } else {
                batteryColor = NSColor.labelColor  // 正常深浅自适应
            }
            batteryColor.setStroke()
            batteryArcPath.stroke()
            
            // 3. 绘制镜面内部 = 放大的 WiFi 信号扇面 (WiFi Waves: 尺寸全面提升)
            let wifiOrigin = CGPoint(x: center.x, y: center.y - 3.4)
            let activeWiFiColor = wifi.isConnected ? NSColor.labelColor : NSColor.labelColor.withAlphaComponent(0.3)
            let inactiveWiFiColor = NSColor.labelColor.withAlphaComponent(0.2)
            
            // 3.1 信号基点 (Dot: 直径增至 2.5pt)
            let dotRadius: CGFloat = 1.25
            let dotRect = NSRect(x: wifiOrigin.x - dotRadius, y: wifiOrigin.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            let dotPath = NSBezierPath(ovalIn: dotRect)
            if wifi.isConnected && wifi.signalBars >= 1 {
                activeWiFiColor.setFill()
            } else {
                inactiveWiFiColor.setFill()
            }
            dotPath.fill()
            
            // 3.2 中层信号弧 (Mid Wave: 半径增至 3.6pt，弧线更饱满)
            let midRadius: CGFloat = 3.6
            let midWavePath = NSBezierPath()
            midWavePath.appendArc(withCenter: wifiOrigin, radius: midRadius, startAngle: 38, endAngle: 142, clockwise: false)
            midWavePath.lineWidth = 1.3
            midWavePath.lineCapStyle = .round
            if wifi.isConnected && wifi.signalBars >= 2 {
                activeWiFiColor.setStroke()
            } else {
                inactiveWiFiColor.setStroke()
            }
            midWavePath.stroke()
            
            // 3.3 外层信号弧 (Outer Wave: 半径增至 5.8pt)
            let outerRadius: CGFloat = 5.8
            let outerWavePath = NSBezierPath()
            outerWavePath.appendArc(withCenter: wifiOrigin, radius: outerRadius, startAngle: 36, endAngle: 144, clockwise: false)
            outerWavePath.lineWidth = 1.3
            outerWavePath.lineCapStyle = .round
            if wifi.isConnected && wifi.signalBars >= 3 {
                activeWiFiColor.setStroke()
            } else {
                inactiveWiFiColor.setStroke()
            }
            outerWavePath.stroke()
            
            return true
        }
        
        image.isTemplate = false // 保证绿/红色电量能够原色呈现
        return image
    }
}
