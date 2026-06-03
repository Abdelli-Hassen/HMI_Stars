# 專案上下文 (Agent Context)：hmi_stars

> **最後更新時間**：2026-05-14 07:08
> **自動生成**：由 `prepare_context.py` 產生，供 AI Agent 快速掌握專案全局

---

## 🎯 1. 專案目標 (Project Goal)
* **核心目的**：_（請手動補充，或建立 README.md）_

## 🛠️ 2. 技術棧與環境 (Tech Stack & Environment)
* _（未偵測到 package.json / pyproject.toml / requirements.txt）_

## 📂 3. 核心目錄結構 (Core Structure)
_(💡 AI 讀取守則：請依據此結構尋找對應檔案，勿盲目猜測路徑)_
```text
hmi_stars/
├── AGENT_CONTEXT.md
├── Platforme
│   ├── README.md
│   ├── add_stage_enum.sql
│   ├── analysis_options.yaml
│   ├── android
│   │   ├── app
│   │   ├── gradle
│   │   ├── gradle.properties
│   │   ├── gradlew
│   │   ├── gradlew.bat
│   │   ├── hmi_stars_android.iml
│   │   ├── local.properties
│   │   └── settings.gradle.kts
│   ├── assets
│   │   └── images
│   ├── database_schema.sql
│   ├── design prototype
│   │   ├── collaborateurs_unified_v2
│   │   ├── confirmation_paie_unified_v2
│   │   ├── d_tails_des_calculs_hashemi_stars
│   │   ├── demander_un_cong_hashemi_stars
│   │   ├── fiche_employ_cong_s_hashemi_stars
│   │   ├── fiche_employ_documents_hashemi_stars
│   │   ├── fiche_employ_unified_v2
│   │   ├── fiche_employ_valuations_hashemi_stars
│   │   ├── forgot_password_hashemi_stars
│   │   ├── gestion_rh_paie_unified_v2
│   │   ├── login_hashemi_stars
│   │   ├── messagerie_unified_v2
│   │   ├── nouvelle_fiche_de_paie_unified_v2
│   │   ├── reset_password_hashemi_stars
│   │   ├── settings_hashemi_stars
│   │   ├── sign_up_hashemi_stars
│   │   ├── stellar_ledger
│   │   └── tableau_de_bord_unified_v2
│   ├── flutter_01.png
│   ├── hmi_stars.iml
│   ├── ios
│   │   ├── Flutter
│   │   ├── Runner
│   │   ├── Runner.xcodeproj
│   │   ├── Runner.xcworkspace
│   │   └── RunnerTests
│   ├── lib
│   │   ├── core
│   │   ├── features
│   │   └── main.dart
│   ├── linux
│   │   ├── CMakeLists.txt
│   │   ├── flutter
│   │   └── runner
│   ├── macos
│   │   ├── Flutter
│   │   ├── Runner
│   │   ├── Runner.xcodeproj
│   │   ├── Runner.xcworkspace
│   │   └── RunnerTests
│   ├── platform_migration.sql
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── rebuild_database.sql
│   ├── test
│   │   └── widget_test.dart
│   ├── web
│   │   ├── favicon.png
│   │   ├── icons
│   │   ├── index.html
│   │   └── manifest.json
│   └── windows
│       ├── CMakeLists.txt
│       ├── flutter
│       └── runner
├── daily_log.md
├── diary
│   └── 2026
│       └── 05
├── hmistarslogo.jpeg
└── hmistarsmobile
    ├── README.md
    ├── analysis_options.yaml
    ├── android
    │   ├── app
    │   ├── gradle
    │   ├── gradle.properties
    │   ├── gradlew
    │   ├── gradlew.bat
    │   ├── hmistarsmobile_android.iml
    │   ├── local.properties
    │   └── settings.gradle.kts
    ├── assets
    │   └── images
    ├── fix_consts.dart
    ├── fix_consts2.dart
    ├── flutter_01.png
    ├── hmistarsmobile.iml
    ├── ios
    │   ├── Flutter
    │   ├── Runner
    │   ├── Runner.xcodeproj
    │   ├── Runner.xcworkspace
    │   └── RunnerTests
    ├── lib
    │   ├── core
    │   ├── features
    │   └── main.dart
    ├── linux
    │   ├── CMakeLists.txt
    │   ├── flutter
    │   └── runner
    ├── macos
    │   ├── Flutter
    │   ├── Runner
    │   ├── Runner.xcodeproj
    │   ├── Runner.xcworkspace
    │   └── RunnerTests
    ├── pubspec.lock
    ├── pubspec.yaml
    ├── replace_colors.dart
    ├── test
    │   └── widget_test.dart
    ├── web
    │   ├── favicon.png
    │   ├── icons
    │   ├── index.html
    │   └── manifest.json
    └── windows
        ├── CMakeLists.txt
        ├── flutter
        └── runner
```

## 🏛️ 4. 架構與設計約定 (Architecture & Conventions)
* _（尚無 `.auto-skill-local.md`，專案踩坑經驗將在開發過程中自動累積）_

## 🚦 5. 目前進度與待辦 (Current Status & TODO)
_(自動提取自最近日記 2026-05-14)_

### 🚧 待辦事項
- [ ] Test the messaging system with multiple concurrent enterprises.
- [ ] Verify the release build of the mobile app to confirm icon integrity.
- [ ] Implement push notifications (FCM) for background messaging.

