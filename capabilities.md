# Gainsday — 配置文档

生成时间：2026-09-30

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能或商店上架前置项**。不配置这些项，App 仍可正常使用所有核心功能（本地优先设计：训练记录、进度曲线、照片、Watch、小组件全部离线可用）。配置后可获得跨设备同步、订阅购买、审核通过等能力。

### 🟡 Capabilities 增强配置

#### 1. iCloud/CloudKit 签名与容器注册

**增强功能**：数据通过用户自己的 iCloud（CloudKit）跨 iPhone / Apple Watch 同步
**不配置的影响**：App 完全正常运行，数据保存在本地；仅无法跨设备同步
**当前状态**：App 已使用本地 SwiftData 作为默认方案，无需配置即可正常使用

**已自动配置部分**：
- ✅ `Gainsday.entitlements` 已包含 iCloud (CloudKit) + 容器 `iCloud.com.zzoutuo.Gainsday`
- ✅ HealthKit、App Groups entitlement 已写入
- ✅ 代码已实现优雅降级（未登录 iCloud 时纯本地运行）
- ✅ `DEVELOPMENT_TEAM=JP4TN5PTS3` 已配置在 project.yml（全部 3 个 target 继承）

**如需启用增强功能，请手动配置**：
1. 打开 Xcode → **Settings（⌘,）→ Accounts** → 用团队 JP4TN5PTS3 所属的 Apple ID 登录（本机当前 "No Accounts"，CLI 无法代登录）
2. 打开 `Gainsday.xcodeproj` → 选中 Gainsday target → **Signing & Capabilities**
3. Xcode 会自动注册 iCloud 容器 + App Group，并在首次真机构建/归档时重新生成带 HealthKit/iCloud/App Groups 的描述文件
4. 对 GainsdayWatch、GainsdayWidgets 两个 target 确认签名team一致（App Group 需同时勾选）
5. ⚠️ 配置完成后重新 Build 验证

#### 2. CloudKit Schema 上线（首次同步运行后）

**增强功能**：同步功能在生产环境稳定可用
**不配置的影响**：Development 环境同步正常，Production 环境（TestFlight/App Store 用户）无法同步
**当前状态**：本地运行正常

**操作步骤**（在完成上面第 1 步并真机跑过一次同步后）：
1. 打开 [CloudKit Console](https://icloud.developer.apple.com) → 选择容器 `iCloud.com.zzoutuo.Gainsday`
2. **Deploy Schema Changes to Production** → 确认部署
3. ⚠️ 部署后 Production 立即可用，无需等待

---

### 🔵 IAP StoreKit 配置（App Store Connect 内创建产品）

**影响功能**：不创建 IAP 产品则用户无法完成订阅/买断购买（付费功能无法解锁）
**代码侧已自动完成**：StoreKit 2 代码（`PurchaseManager.swift`，`Transaction.currentEntitlement(for:)` 响应式监听）、Paywall 合规 UI（法律链接+自动续订披露+Restore Purchases）均已完成

**配置步骤**：
1. 在 App Store Connect → 你的 App → **Features → In-App Purchases → Manage**
2. 创建订阅组 **Gainsday Pro**，然后在组内创建两个自动续订订阅：

| 产品 | Reference Name | Product ID | 价格 | 免费试用 |
|------|---------------|-----------|------|---------|
| 年付 | Gainsday Pro Annual | `gainsday.pro.yearly` | $19.99/年 | 7 天 |
| 月付 | Gainsday Pro Monthly | `gainsday.pro.monthly` | $3.99/月 | 无 |

3. 另创建一个**非消耗型（Non-Consumable）**产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 买断 | Gainsday Lifetime BYO | `gainsday.lifetime.byo` | $49.99 |

4. Display Name / Description 从 `price.md` 复制（已按 ≤35/≤55 字符校验）
5. 本地测试：Xcode 中新建 StoreKit Configuration File 并填入以上 3 个产品 ID（File → New → File → StoreKit Configuration File），运行即可模拟购买
6. ⚠️ 产品创建后需等 Apple 处理（通常 1-2 小时）才能在沙盒中购买
7. 在 App 的 Paywall 点击 **Restore Purchases** 验证流程

---

### 🟢 App Store Connect 审核信息配置

**影响功能**：不配置则 Apple 审核员无法测试 AI/订阅，存在 Guideline 2.1(a) 拒审风险

**配置步骤**：
1. 在 App Store Connect → 你的 App → **App Review Information**
2. 将项目根目录 `app_review_info.md` 中的内容粘贴到 **Notes** 字段（已包含：核心功能测试步骤、BYO Key 说明、内嵌配额披露、HealthKit 五要素说明、订阅产品清单、中国区合规声明、政策页链接）
3. **Privacy Policy URL**：`https://asunnyboy861.github.io/Gainsday/privacy.html`
4. **Terms of Use (EULA) URL**：`https://asunnyboy861.github.io/Gainsday/terms.html`（订阅类必填）
5. **Support URL**：`https://asunnyboy861.github.io/Gainsday/support.html`
6. 审核联系信息：iocompile67692@gmail.com
7. ⚠️ `app_review_info.md` 属敏感文件，已在 .gitignore 中排除，不要提交到 GitHub

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| iCloud (CloudKit) | entitlements + 容器声明，代码 SwiftData cloudKitDatabase | ✅ 已配置（签名激活见手动步骤） |
| HealthKit | entitlements + NSHealthShare/NSHealthUpdate 用途描述 + UI 五要素识别 | ✅ 已配置 |
| App Groups | group.com.zzoutuo.Gainsday（App + Widgets 双端） | ✅ 已配置 |
| Watch App | GainsdayWatch target（watchOS 10，WKCompanionAppBundleIdentifier） | ✅ 已配置 |
| WidgetKit 扩展 | GainsdayWidgets target（主屏 + 锁屏，App Group 快照） | ✅ 已配置 |
| 本地通知 | UNUserNotificationCenter（周报提醒），无需 entitlement | ✅ 已配置 |
| 相机/相册 | NSCameraUsageDescription + PhotosPicker | ✅ 已配置 |
| 内购 (StoreKit 2) | PurchaseManager + 3 产品代码 + Paywall 合规 | ✅ 代码完成（产品创建见手动步骤） |
| Vision / FoundationModels | 框架引用，weak-linked，#if canImport 防旧 SDK | ✅ 已配置 |
| Keychain (BYO Key) | Generic Password 存储，无 entitlement 需要 | ✅ 已配置 |
| PrivacyInfo.xcprivacy | 3 个 target 全覆盖（CA92.1 + C617.1） | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers，地址已硬编码 `https://msg.calcs.top` | ✅ 已部署 |
| 网络权限 | HTTPS 出站连接（ATS 默认允许） | ✅ 已配置 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 功能（BYO Key）**：AI 支持 4 层路由——Apple Intelligence 设备端（iOS 26+，免费无限）→ 用户自带 Key（Settings → AI Coach & API Keys，6 种供应商预设 + 自定义端点）→ 开发者内嵌配额（免费 3 次/月，订阅 60 次/月）→ 离线建议引擎。BYO Key 是用户在 App 内自行输入的操作，不是开发者配置步骤。内置 GLM Key 存放在 `Gainsday/GLMSecret.txt`（已 gitignore，绝不入库）。

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | asunnyboy861/Gainsday 已推送 | ✅ 已完成 |
| GitHub Pages | 政策页 4 页已上线（200 OK） | ✅ 已完成 |
| Landing Page | 已部署（App Store ID 为占位符，ASC 建档后替换） | ✅ 已完成 |
| App Store 元数据 | keytext.md 已生成并通过 20 项验证 | ✅ 已完成 |
| 定价配置 | price.md 已生成 | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据。"Auto-Configured" 与 "Manual Configuration Required" 的内容已重组到上方 Section 一 和 Section 二。

### Analysis

Based on `us.md` + Chinese guide keyword scan (同步/iCloud, 健康/HealthKit, 手表/Watch, Widget, 订阅/StoreKit, 通知/notifications, 相机/照片/camera, Vision, FoundationModels, App Groups for widgets):

### Detected Capabilities

| Capability | Source keyword | Status |
|---|---|---|
| iCloud / CloudKit (SwiftData sync) | "CloudKit 同步", "iCloud" | ✅ entitlements configured |
| HealthKit | "HealthKit", "训练写入" | ✅ entitlements configured |
| App Groups (Widget data sharing) | WidgetKit requirements | ✅ entitlements configured (app + widgets) |
| Apple Watch App | "Apple Watch", "Watch App" | ✅ target created (GainsdayWatch, watchOS 10.0) |
| WidgetKit extension | "Home Screen Widget + 锁屏" | ✅ target created (GainsdayWidgets) |
| Local Notifications | "周报通知", "本地通知" | ✅ no entitlement needed (UNUserNotificationCenter) |
| Camera / Photo Library | "拍照", "PhotosPicker" | ✅ usage strings added in PHASE 4+5 |
| In-App Purchase (StoreKit 2) | "订阅", "买断" | ✅ no entitlement needed; SKUs configured |
| Vision (body pose) | "VNDetectHumanBodyPoseRequest" | ✅ framework only |
| FoundationModels (iOS 26 AI) | "Apple Foundation Models" | ✅ framework only |
| Keychain (BYO AI key storage) | "Keychain (BYO Key 存储)" | ✅ no entitlement needed |
| Push Notifications | — | ❌ NOT needed (all notifications are local) |

### No Configuration Needed

- Push Notifications (all notifications local)
- Sign in with Apple (no account system by design)
- Location / Siri / Background Modes (not in guide)

### Verification

- Build succeeded after configuration: ✅ (all 3 targets, iPhone 16 + iPad Pro 13-inch simulators)
- All entitlements correct: ✅ (CloudKit + HealthKit + App Groups, app-level; App Groups widget-level)
- Signing verification (generic/platform=iOS): ⏳ blocked by "No Accounts" — user must sign into Xcode once; DEVELOPMENT_TEAM=JP4TN5PTS3 is baked at project level for ALL targets
- Runtime: launched on iPhone 16 & iPad Pro 13-inch (M5) simulators, onboarding renders, notification permission prompt fires
