# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Settings-screen contribution rules (driver-goal categories, layout constants, the tests that must stay green) live in `AGENTS.md` — read it before touching the Settings UI. This file covers the build, toolchain and architecture.

## What this is

A fork of [DiPlay](https://github.com/shihabal3amri/DiPlay) (via DiPlay-CN), being customized for **Chery (奇瑞) head-unit adaptation**. DiPlay is a CarPlay receiver that runs on Android head units. Upstream targets BYD DiLink; this fork adapts it to Chery's infotainment.

Naming gotcha: the Gradle root project is `xcertplay` and the source namespace is `com.shilapi.xcertplay`, but the installable main app keeps `applicationId = "com.shihab.diplay.cn"` for continuity with existing DiPlay-CN installs. Don't conflate the two.

## Toolchain (not yet installed on this Mac)

- **JDK 25** — Gradle 9.5 + AGP 9.3 require it (CI uses Temurin 25). `./gradlew` needs a JDK on `PATH`/`JAVA_HOME`; the `foojay-resolver-convention` plugin auto-provisions *toolchain* JDKs for compilation but not the JDK that launches Gradle.
- **Android SDK** — Platform 37 (`platforms;android-37.0`), Build-Tools 36.0.0, Platform-Tools, NDK 28.2.13676358. Point Gradle at it via `ANDROID_HOME` or a `local.properties` with `sdk.dir=...` (keep that file out of git).

## Build & verify

Run from the repo root with the wrapper (`./gradlew`), never a system Gradle.

- Main app (source-only, no CarPlay auth): `./gradlew :mobile:assembleDebug` → `mobile/build/outputs/apk/debug/mobile-debug.apk`
- Quick check: `./gradlew :shared:testDebugUnitTest :common:testDebugUnitTest :mobile:lintDebug :mobile:assembleDebug`
- Full check (mirrors CI, `.github/workflows/android.yml`): `./gradlew :shared:testDebugUnitTest :common:testDebugUnitTest :home:testDebugUnitTest :mobile:lintDebug :home:lintDebug :maphost:lintDebug :mobile:assembleDebug :home:assembleDebug :maphost:assembleDebug`
- Single test: `./gradlew :common:testDebugUnitTest --tests "com.shilapi.xcertplay.SettingsTranslationsTest"`
- Standalone car-test APK (requires a runtime MFi identity): `DIPLAY_AUTH_ASSETS_DIR=/abs/path ./gradlew :mobile:assembleStandaloneDebug`
- Release: `./gradlew :mobile:lintRelease :mobile:assembleRelease` with `DIPLAY_AUTH_ASSETS_DIR`, `ANDROID_KEYSTORE_PATH/PASSWORD`, `ANDROID_KEY_ALIAS/PASSWORD` set. Full details in `docs/BUILD.md`.

## Module layout

| Module | Type | Purpose |
| --- | --- | --- |
| `:shared` | `com.android.library` (Groovy `build.gradle`) | Protocol core, no UI: `iap2/` (wire/session/message), `airplay/`, `mfi/` (auth), `transport/` (USB/Wi-Fi), `media/` (H.264 video + Opus audio via Concentus), `telecom/` (calls/Siri), `orchestration/`, `hud/`, `adb/`, `glance/`, `location/`, `compat/`. namespace `com.shilapi.xcertplay.shared`. |
| `:common` | `com.android.library` | Android UI layer: Compose `DiPlayActivity` + the Settings screen, ExoPlayer (media3) for video, zxing for QR. `api(project(":shared"))`. Robolectric + Mockito unit tests. namespace `com.shilapi.xcertplay.host`. |
| `:mobile` | `com.android.application` | Main installable app. `applicationId com.shihab.diplay.cn`, minSdk 25, targetSdk 37. Signing, credential-rejection and `assembleStandalone*` tasks live here. |
| `:automotive` | `com.android.application` | Android Automotive app, `applicationId com.shilapi.xcertplay`, minSdk 28. |
| `:maphost` (`samples/maphost`) | `com.android.application` | Sample map-display host, `applicationId com.diplay.maphost`, minSdk 30. |
| `:home` (`samples/home`) | `com.android.application` | Optional home launcher, `applicationId com.diplay.home`, minSdk 30. |

`:common` and `:shared` are libraries; the four application modules consume them. Build `:mobile` for the main app.

## Signing & credentials (non-negotiable)

- The CarPlay accessory identity (MFi) is **never in git**. Source/CI builds contain no identity, so they can't start standalone CarPlay — only `assembleStandalone*` with `DIPLAY_AUTH_ASSETS_DIR` (`offline-mfi/identity.pk8` + `certificate.p7b`) can.
- `rejectBundledCredentials` (hooked into `preBuild`) fails if any credential file beyond those two lands in APK assets; `scripts/check_public_tree.py` enforces the same in CI.
- The CN release keystore (`signing/diplay-cn.jks`) is public, retained only for in-place update compatibility — see `SECURITY.md`. It is not a secret.
