#!/usr/bin/env bash
# 一键启动 DiPlay：拉起模拟器（如未运行）→ 等待开机 → 安装 APK → 启动应用
# 用法：在项目根目录执行  ./run.sh
set -e
cd "$(dirname "$0")"

SDK="$HOME/Library/Android/sdk"
ADB="$SDK/platform-tools/adb"
EMU="$SDK/emulator/emulator"
APK="mobile/build/outputs/apk/debug/mobile-debug.apk"
PKG="com.shihab.diplay.cn"
ACT="com.shilapi.xcertplay.DiPlayActivity"

# 1. 模拟器没在跑就启动（detached，避免被终端回收）
if ! "$ADB" devices 2>/dev/null | grep -q 'emulator-5554'; then
  echo "▶ 启动模拟器 diplay ..."
  nohup "$EMU" -avd diplay -no-snapshot -no-boot-anim > /tmp/emulator.log 2>&1 &
fi

# 2. 等待开机完成（最多 3 分钟）
echo "▶ 等待模拟器开机 ..."
for i in $(seq 1 60); do
  boot=$("$ADB" -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  [ "$boot" = "1" ] && { echo "   已开机"; break; }
  sleep 3
done

# 3. 安装 APK（若已编译）
if [ -f "$APK" ]; then
  echo "▶ 安装 APK ..."
  "$ADB" -s emulator-5554 install -r "$APK" >/dev/null 2>&1 || echo "   （安装跳过或失败，可能已安装同版本）"
fi

# 4. 启动应用
echo "▶ 启动 DiPlay ..."
"$ADB" -s emulator-5554 shell am start -n "$PKG/$ACT"

echo "✅ 完成。模拟器窗口应已打开并显示 DiPlay。"
