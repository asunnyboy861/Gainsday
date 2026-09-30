# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | Gainsday |
| **Git URL** | git@github.com:asunnyboy861/Gainsday.git |
| **Repo URL** | https://github.com/asunnyboy861/Gainsday |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/Gainsday/ | ✅ Active |
| Support | https://asunnyboy861.github.io/Gainsday/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/Gainsday/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/Gainsday/terms.html | ✅ Active |

## Repository Structure

```
Gainsday/
├── Gainsday.xcodeproj/            # Xcode Project (xcodegen source: project.yml)
├── Gainsday/                      # iOS App Source Code
│   ├── AI/                        # AI router, 6-provider BYO config, on-device tier
│   ├── App/                       # App entry, root tabs
│   ├── Assets.xcassets/           # App icon
│   ├── Models/                    # SwiftData models, DayKey
│   ├── Resources/exercises.json   # 876-exercise library (MIT, yuhonas/free-exercise-db)
│   ├── Services/                  # OverloadEngine, HealthKit, Watch sync, quota, CSV
│   ├── Store/                     # PurchaseManager (IAP)
│   └── Views/                     # Today, Progress, Photos, Coach, History, Settings, Paywall
├── GainsdayWatch/                 # watchOS companion (2-tap logging, rest timer, set回传)
├── GainsdayWidgets/               # Home Screen / Lock Screen widgets (App Group snapshot)
├── docs/                          # Policy Pages (GitHub Pages source) — added in PHASE 7
├── .github/workflows/deploy.yml   # Pages deploy workflow — added in PHASE 7
├── project.yml                    # xcodegen project definition (source of truth)
├── us.md                          # Translated English app guide
├── capabilities.md
├── icon.md
├── price.md
├── nowgit.md
├── keytext.md                     # ⚠️ EXCLUDED from repo (.gitignore — confidential ASO strategy)
└── COMPETITOR_REPORT.md           # ⚠️ EXCLUDED from repo (.gitignore — confidential competitor analysis)
```

## Excluded from Repository (gitignore)

- `.env` — credentials
- `Gainsday/GLMSecret.txt` — embedded GLM API key (Keychain-injected at build)
- `keytext*.md`, `COMPETITOR_REPORT.md` — confidential ASO strategy
- `app_review_info.md`, `improvement_plan_*.md` — review/QA internal notes
- `TR-*-操作指南.MD` — original Chinese operation guide
- `icon_1024.png`, `icon_raw.png` — icon generation temp files

## Build Verification (PHASE 6)

| Target | Result |
|--------|--------|
| Gainsday (iPhone 16, iOS 18.4 sim) | ✅ BUILD SUCCEEDED + launch verified |
| GainsdayWatch (watchOS sim) | ✅ BUILD SUCCEEDED |
| GainsdayWidgets (iOS sim) | ✅ BUILD SUCCEEDED |
| iPad Pro 13-inch (M5) sim | ✅ BUILD SUCCEEDED + launch verified |
