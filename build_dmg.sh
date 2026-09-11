#!/bin/bash
set -e

echo "🔨 正在编译 Release 版本..."
swift build -c release

echo "📦 组装 BatteryBar.app..."
mkdir -p BatteryBar.app/Contents/MacOS
cp .build/release/BatteryBar BatteryBar.app/Contents/MacOS/BatteryBar
chmod +x BatteryBar.app/Contents/MacOS/BatteryBar

echo "🔏 刷新代码签名..."
codesign --force --deep --sign - BatteryBar.app

echo "💿 打包 BatteryBar.dmg..."
rm -rf /tmp/dmg_staging BatteryBar.dmg
mkdir -p /tmp/dmg_staging
cp -R BatteryBar.app /tmp/dmg_staging/
ln -s /Applications /tmp/dmg_staging/Applications

hdiutil create -volname "BatteryBar" -srcfolder /tmp/dmg_staging -ov -format UDZO BatteryBar.dmg > /dev/null
rm -rf /tmp/dmg_staging

echo "✅ 打包完成！生成文件: BatteryBar.dmg ($(ls -lh BatteryBar.dmg | awk '{print $5}'))"
