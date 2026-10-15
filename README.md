# 奇瑞互联

> 让奇瑞安卓车机用上 Apple CarPlay 的开源方案，基于 [DiPlay-CN](https://github.com/serein-morii/DiPlay-CN) 二次开发、针对奇瑞车机定制。

## 项目简介

「奇瑞互联」是一款运行在安卓车机上的 CarPlay 接收器。把它安装到车机后，即可通过 USB 有线或 Wi-Fi 无线连接 iPhone，在车机屏幕上使用苹果 CarPlay 界面，无需任何外接转接盒、无需越狱。

原项目 DiPlay 主要面向比亚迪 DiLink 车机。本仓库在其基础上，针对奇瑞车机做了定制与适配。

## 奇瑞定制内容

### 1. 车辆品牌设置

在「设置 → 车辆 → 车辆品牌」中新增品牌选择：

- **比亚迪 DiLink**（默认）：保留原项目全部功能；
- **奇瑞**：自动隐藏比亚迪专属的仪表盘与导航功能。

这样做的原因：奇瑞车机不具备比亚迪的 DiLink 仪表 / HUD 协议，那些比亚迪专属功能在奇瑞车机上没有意义。选择「奇瑞」后，设置界面更干净、更贴合奇瑞车机。该设置已覆盖全部 8 种界面语言，并有单元测试保障。

### 2. 品牌改造

- 应用名：DiPlay CN → **奇瑞互联**；
- 界面标题：DiPlay → **奇瑞互联**；
- 应用图标：蓝色圆角图标 +「奇瑞」文字 + 红色点缀（奇瑞品牌配色）。

## 架构

本项目是 Gradle 多模块工程，共 6 个模块，职责分层清晰：

| 模块 | 类型 | 职责 |
| --- | --- | --- |
| `shared` | 库 | 协议核心，不含界面：iAP2 协议、AirPlay 会话、MFi 认证、USB/Wi-Fi 传输、H.264 视频解码、Opus 音频、通话、会话编排、HUD、adb、定位等 |
| `common` | 库 | Android 界面层：设置界面（Compose）、主界面、ExoPlayer 视频播放、二维码；依赖 `shared` |
| `mobile` | 应用 | 主应用，用户实际安装的就是它 |
| `automotive` | 应用 | 独立的 Android Automotive 应用 |
| `maphost` | 应用 | 地图显示示例应用（`samples/`） |
| `home` | 应用 | 可选的主页启动器（`samples/`） |

### CarPlay 数据流

```
iPhone
  │  有线 USB / 无线 Wi-Fi Direct
  ▼
iAP2 链接握手 + MFi 认证    （shared/iap2、shared/mfi）
  ▼
AirPlay 会话（配对 / 验证）  （shared/airplay）
  ▼
H.264 视频解码 + Opus 音频   （shared/media）
  ▼
渲染到车机屏幕              （common，ExoPlayer）
```

反向链路：车机屏幕触摸 / 方向盘按键 → AirPlay 输入事件 → 回传 iPhone。

### 技术栈

- 语言：Kotlin；界面：View 系统与 Jetpack Compose 混用
- 构建：Gradle 多模块 + 版本目录（Version Catalog）
- 原生：NDK（含 C 代码：I2C、车载热点、Speex 回声消除）
- 车机：androidx.car.app
- 视频：media3 / ExoPlayer；二维码：zxing
- 测试：JUnit + Robolectric + Mockito

## 构建与运行

### 环境要求

- JDK 25
- Android SDK：Platform 37、Build-Tools 36.0.0
- NDK 28.2.13676358
- 可选：Android 模拟器或安卓真机

### 编译主应用

```sh
./gradlew :mobile:assembleDebug
```

产物路径：`mobile/build/outputs/apk/debug/mobile-debug.apk`

### 运行单元测试与 lint

```sh
./gradlew :shared:testDebugUnitTest :common:testDebugUnitTest :mobile:lintDebug :mobile:assembleDebug
```

### 一键启动（模拟器）

```sh
./run.sh
```

自动完成：拉起模拟器 → 等待开机 → 安装 APK → 启动应用。

## 目录结构

```
├── shared/         # 协议核心库
├── common/         # Android 界面库
├── mobile/         # 主应用
├── automotive/     # Android Automotive 应用
├── samples/
│   ├── maphost/    # 地图显示示例
│   └── home/       # 主页启动器示例
├── scripts/        # 构建与检查脚本
├── docs/           # 文档
└── run.sh          # 一键启动脚本
```

## 许可

本项目基于开源项目 DiPlay-CN 二次开发，沿用其 GPL-3.0 开源许可。详见 [LICENSE](LICENSE)。
