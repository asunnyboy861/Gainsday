# Capabilities Configuration

## Analysis
Based on `us.md` + Chinese guide keyword scan (同步/iCloud, 健康/HealthKit, 手表/Watch, Widget, 订阅/StoreKit, 通知/notifications, 相机/照片/camera, Vision, FoundationModels, App Groups for widgets):

## Detected Capabilities
| Capability | Source keyword | Status |
|---|---|---|
| iCloud / CloudKit (SwiftData sync) | "CloudKit 同步", "iCloud" | ✅ entitlements configured |
| HealthKit | "HealthKit", "训练写入" | ✅ entitlements configured |
| App Groups (Widget data sharing) | WidgetKit requirements | ✅ entitlements configured (app + widgets) |
| Apple Watch App | "Apple Watch", "Watch App" | ✅ target created (GainsdayWatch, watchOS 10.0) |
| WidgetKit extension | "Home Screen Widget + 锁屏" | ✅ target created (GainsdayWidgets) |
| Local Notifications | "周报通知", "本地通知" | ✅ no entitlement needed (UNUserNotificationCenter) |
| Camera / Photo Library | "拍照", "PhotosPicker" | ✅ usage strings to be added in PHASE 4+5 Info.plist keys |
| In-App Purchase (StoreKit 2) | "订阅", "买断" | ✅ no entitlement needed (StoreKit framework); SKUs configured in PHASE 4+5 |
| Vision (body pose) | "VNDetectHumanBodyPoseRequest" | ✅ framework only, no entitlement |
| FoundationModels (iOS 26 AI) | "Apple Foundation Models" | ✅ framework only, no entitlement |
| Keychain (BYO AI key storage) | "Keychain (BYO Key 存储)" | ✅ no entitlement needed (Generic Password item) |
| Push Notifications | — | ❌ NOT needed (all notifications are local) |

## Auto-Configured Capabilities
| Capability | Status | Method |
|---|---|---|
| iCloud (CloudKit, container iCloud.com.zzoutuo.Gainsday) | ✅ Entitlements in project | xcodegen + Gainsday.entitlements |
| HealthKit | ✅ Entitlements in project | Gainsday.entitlements |
| App Groups (group.com.zzoutuo.Gainsday) | ✅ Entitlements in project | App + Widgets entitlements |
| Watch App target | ✅ Created | xcodegen (GainsdayWatch, embedded in iOS app) |
| Widgets extension target | ✅ Created | xcodegen (GainsdayWidgets, widgetkit-extension) |
| PrivacyInfo.xcprivacy | ✅ All 3 targets covered | UserDefaults CA92.1 + FileTimestamp C617.1 (app) |

## Manual Configuration Required
| Capability | Status | Steps |
|---|---|---|
| CloudKit container + capability-enabled provisioning profiles | ⏳ Pending user | Xcode → Settings → Accounts → sign in with the Apple ID of team JP4TN5PTS3; open Gainsday.xcodeproj → Signing & Capabilities → Xcode auto-registers the iCloud container + App Group and regenerates profiles with HealthKit/iCloud/App Groups on first device build/archive. (CLI verification blocked: "No Accounts" on this machine — cached wildcard profile lacks the 3 capabilities.) App works fully without sync until then (local-first by design). |
| CloudKit schema deployment (after first sync run) | ⏳ Pending user | Run app once with iCloud signed in → CloudKit Dashboard → deploy schema to Production (see ios-capability-icloud flow in PHASE 8.5 checklist) |

## No Configuration Needed
- Push Notifications (all notifications local)
- Sign in with Apple (no account system by design)
- Location / Siri / Background Modes (not in guide)

## Verification
- Build succeeded after configuration: ✅ (iPhone 16 iOS 26.4 simulator, all 3 targets)
- All entitlements correct: ✅ (CloudKit + HealthKit + App Groups, app-level; App Groups widget-level)
- Signing verification (generic/platform=iOS): ⏳ blocked by "No Accounts" — user must sign into Xcode once; DEVELOPMENT_TEAM=JP4TN5PTS3 is baked at project level for ALL targets
- DEVELOPMENT_TEAM: JP4TN5PTS3 (project level, inherited by all targets)
- PrivacyInfo.xcprivacy: App + GainsdayWatch + GainsdayWidgets ✅
