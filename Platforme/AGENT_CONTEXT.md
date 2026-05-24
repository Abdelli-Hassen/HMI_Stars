# 專案上下文 (Agent Context)：Platforme

> **最後更新時間**：2026-05-22 21:21
> **自動生成**：由 `prepare_context.py` 產生，供 AI Agent 快速掌握專案全局

---

## 🎯 1. 專案目標 (Project Goal)
* **核心目的**：Enterprise management system mobile application for HMI Stars Consulting.
* _完整說明見 [README.md](README.md)_

## 🛠️ 2. 技術棧與環境 (Tech Stack & Environment)
* _（未偵測到 package.json / pyproject.toml / requirements.txt）_

## 📂 3. 核心目錄結構 (Core Structure)
_(💡 AI 讀取守則：請依據此結構尋找對應檔案，勿盲目猜測路徑)_
```text
Platforme/
├── AGENT_CONTEXT.md
├── README.md
├── analysis_options.yaml
├── android
│   ├── app
│   │   └── src
│   ├── gradle
│   │   └── wrapper
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── hmi_stars_android.iml
│   ├── local.properties
│   └── settings.gradle.kts
├── assets
│   └── images
│       └── logo.jpeg
├── diary
│   └── 2026
│       └── 05
├── hmi_stars.iml
├── ios
│   ├── Flutter
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   ├── Generated.xcconfig
│   │   ├── Release.xcconfig
│   │   ├── ephemeral
│   │   └── flutter_export_environment.sh
│   ├── Runner
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets
│   │   ├── Base.lproj
│   │   ├── GeneratedPluginRegistrant.h
│   │   ├── GeneratedPluginRegistrant.m
│   │   ├── Info.plist
│   │   ├── Runner-Bridging-Header.h
│   │   └── SceneDelegate.swift
│   ├── Runner.xcodeproj
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace
│   │   └── xcshareddata
│   ├── Runner.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata
│   └── RunnerTests
│       └── RunnerTests.swift
├── lib
│   ├── core
│   │   ├── providers
│   │   ├── router
│   │   ├── services
│   │   ├── supabase_config.dart
│   │   ├── supabase_config.dart.example
│   │   ├── theme
│   │   └── widgets
│   ├── features
│   │   ├── auth
│   │   ├── dashboard
│   │   ├── entreprise_details
│   │   ├── entreprises
│   │   ├── messagerie
│   │   ├── settings
│   │   └── urgents
│   └── main.dart
├── linux
│   ├── CMakeLists.txt
│   ├── flutter
│   │   ├── CMakeLists.txt
│   │   ├── ephemeral
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   └── runner
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
├── macos
│   ├── Flutter
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   ├── GeneratedPluginRegistrant.swift
│   │   └── ephemeral
│   ├── Runner
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets
│   │   ├── Base.lproj
│   │   ├── Configs
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   └── Release.entitlements
│   ├── Runner.xcodeproj
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace
│   │   └── xcshareddata
│   ├── Runner.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata
│   └── RunnerTests
│       └── RunnerTests.swift
├── pubspec.lock
├── pubspec.yaml
├── test
│   └── widget_test.dart
├── web
│   ├── favicon.png
│   ├── icons
│   │   ├── Icon-192.png
│   │   ├── Icon-512.png
│   │   ├── Icon-maskable-192.png
│   │   └── Icon-maskable-512.png
│   ├── index.html
│   └── manifest.json
└── windows
    ├── CMakeLists.txt
    ├── flutter
    │   ├── CMakeLists.txt
    │   ├── ephemeral
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    └── runner
        ├── CMakeLists.txt
        ├── Runner.rc
        ├── flutter_window.cpp
        ├── flutter_window.h
        ├── main.cpp
        ├── resource.h
        ├── resources
        ├── runner.exe.manifest
        ├── utils.cpp
        ├── utils.h
        ├── win32_window.cpp
        └── win32_window.h
```

## 🏛️ 4. 架構與設計約定 (Architecture & Conventions)
* _（尚無 `.auto-skill-local.md`，專案踩坑經驗將在開發過程中自動累積）_

## 🚦 5. 目前進度與待辦 (Current Status & TODO)
_(自動提取自最近日記 2026-05-22)_

### 🚧 待辦事項
- [ ] Add explicit formatting validation regex to phone and APE code input fields in enterprise dialogs.
- [ ] Test real-time logo updates under multiple edge-cases of database connections.

