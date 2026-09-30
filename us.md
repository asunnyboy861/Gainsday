# Gainsday - iOS Development Guide

> Translated and adapted from: `TR-20260917-Gainsday健身追踪-操作指南.MD` (2026-09-17)
> Tagline: **"Every day is Gainsday."** — Never skip Gainsday.

## Executive Summary

Gainsday is a native SwiftUI strength-training logger for iPhone (with Apple Watch companion, Home Screen/Lock Screen widgets, and iCloud sync). Its promise: **log a set in 2 taps, and the app tells you exactly how to beat it next time.**

- **Target audience**: US gym beginners and returning lifters (r/beginnerfitness crowd) burned by over-complicated trackers, plus intermediate lifters who want a fast logger with real coaching.
- **Positioning**: Hevy/Strong are notebooks ("the notebook was never the problem"); Fitbod charges $95.99/year for opaque AI. Gainsday fills the category's unsolved triangle: **Simple (2-tap logging) + Decides-for-you (explainable OverloadEngine) + Price-friendly (real free tier, $19.99/year)**.
- **Key differentiators**:
  1. **2-tap logging** — cells are buttons; last performance pre-filled on open.
  2. **"Beat last time" decision engine** — free, explainable rule engine (never a black box).
  3. **AI Form Coach** — photo → on-device Vision skeleton check → cloud vision AI feedback (embedded GLM via proxy default + multi-provider BYO key), with on-device rule fallback. Nothing in the category has camera posture feedback (Fitbod doesn't either).
  4. **Progress photo timeline** — auto-aligned slider comparison (Glowly's paid core, free here).
  5. **Editable history + free iCloud sync + free CSV export** — fixes the category's #1 complaint.
  6. **Transparent pricing** — real free tier forever; $19.99/year (7-day trial); $49.99 lifetime that **only buys features, never cloud AI consumption**.

## App Identity

| Item | Value |
|---|---|
| APP_NAME | **Gainsday** |
| BUNDLE_ID | `com.zzoutuo.Gainsday` |
| MIN_IOS | 17.0 |
| Subtitle | Log. Lift. Beat Last Time. |
| Promo line | Every day is Gainsday. Log a set in 2 taps, and we'll tell you exactly how to beat it next time. |
| Keywords field | `workout tracker,gym log,sets reps,progressive overload,PR,plate calc,rest timer,lift,strength,gains` |
| Backup names (if taken on Connect) | PRday ("Today might be PRday."), Twotap |
| Copyright | Copyright © 2026 he zhou |

## Competitive Analysis (research dated 2026-09, US store)

| App | Price | Free tier | Strengths | Fatal flaw (= our angle) |
|---|---|---|---|---|
| Hevy | $23.99/yr, $74.99 lifetime | Unlimited logging but only 4 programs, 3-month history, 7 custom exercises | Community + Watch + balance | Free-tier ceilings; just a notebook, doesn't decide for you |
| Strong | $29.99/yr, $99.99 lifetime | Logging free | Fastest logging | "For people who already know what they're doing" — zero beginner guidance |
| Fitbod | $79.99–95.99/yr | **No permanent free tier** (7-day trial + 3 workouts) | AI plans + 1600 exercise videos | 4× the price; AI plans rated inaccurate ("constantly had to edit them"); no free tier |
| Jefit | $39.99/yr | Yes | Big exercise DB | Ads + bloated UI + aggressive upsells |
| Boostcamp | Free + programs | Free | Free programs | Weak logging, no photo timeline, no AI |
| Apple Workout/Notes | Free | — | Zero friction | No structured logging, no history compare, no progress narrative |

Category review quotes (marketing ammunition):
> "Most of them are notebooks, and the notebook was never the problem." — pocket-fit.app
> "Fitbod could feel like an expensive workout journal." — Lifehacker
> "Both punish an off-script session." — Gym Note Plus review (Hevy & Fitbod)

**Category unsolved triangle**: Simple ✚ Decides-for-you ✚ Price-friendly — every competitor maxes out at two. Gainsday takes all three.

## Apple Design Guidelines Compliance

- **Human Interface Guidelines — Fitness apps**: single-column large touch targets, all high-frequency controls in the bottom 60% thumb zone (gym gloves/sweat scenario), no nested side menus.
- **SF Pro Rounded** for numerals and headings (friendly, non-intimidating); SF Pro for body text.
- **Dynamic Type & accessibility**: stepper cells scale with text size; VoiceOver labels on every cell ("Weight, 140 pounds, tap to add five").
- **Haptics**: `.success` sensory feedback on set completion and PR; no disruptive alerts.
- **Dark-first with light adaptation**: deep charcoal `#0E0F12` base + electric orange primary + gold reserved exclusively for PR/celebration moments.
- **Anti-anxiety design**: no red badges, no feeds, no infinite scroll; the only proactive notification is the Monday 8 AM weekly recap (opt-out).
- **Privacy**: no forced account (Guideline 5.1.1 avoided); photos processed on-device first; cloud requests carry no user identity; privacy label "Data Not Collected" for form-check photos.

## Technical Architecture

- **Language**: Swift 5.9+, strict concurrency-ready
- **UI**: SwiftUI (iPhone + Watch), WidgetKit (Home Screen + Lock Screen accessories)
- **Data**: **SwiftData `@Model`** (single source of truth, local-first) + **CloudKit sync** (`CKSyncEngine`, free, automatic) — no custom backend
- **Health**: HealthKit (workouts + volume samples, write-only mirror, local wins on conflict)
- **Vision**: `VNDetectHumanBodyPoseRequest` (17 joints) for form-check preprocessing & offline fallback
- **AI (two-layer router — see AI section below)**:
  - **Apple Foundation Models** (iOS 26 on-device, free & unlimited): natural-language logging, weekly recap copy, suggestion explanations
  - **Cloud vision AI** (form check / photo compare): embedded default backend via GLM proxy (`glm-api-config` managed) **plus multi-provider BYO Key** (GLM api.z.ai, OpenAI, Gemini, DeepSeek, Claude, or any OpenAI-compatible endpoint)
- **IAP**: StoreKit 2 (auto-renewable subscriptions + non-consumable lifetime)
- **Bundled data**: `yuhonas/free-exercise-db` (800+ exercises, Unlicense — commercial OK; keep README attribution in About page)
- **Notifications**: local only (weekly recap, trial-end reminder)

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | 2-tap set logging (Today) | Open app → last workout auto-restored → tap weight cell (+5 lb; long-press −2.5) → tap reps cell (+1; long-press −1) → tap ✓ | Taps only, zero keyboard | `SetDraft` pre-filled from last performance via `LastPerformanceProvider`; on complete: compare vs last, trigger celebration, start rest timer, write HealthKit | Cell UI + celebration banner ("+5 lb vs last time 🔥" / "NEW PR 🏆") | `WorkoutSession` + `SetEntry` in SwiftData immediately | Open → set logged ≤10 s; works fully offline |
| 2 | OverloadEngine "beat last time" | Automatic after each set; suggestion shown during rest | Last N sets of same exercise | Rules: all target reps hit → +5 lb upper / +10 lb lower; 1–2 reps short → same weight, +1 rep; clear failure (2 sets missed) → −10% weight; 4-week double-progression rotation | Suggestion card **with reason** ("Last time you hit 8/8 — time to add 5 lb.") | Suggestion is computed, never persisted as truth | Unit tests ≥90% coverage; every suggestion carries a reason |
| 3 | Editable history | History tab → pick session → edit any set (weight/reps/RPE) → save; swipe to delete (soft) | Edited fields | `editedAt` stamp + deviceID; soft delete via `deletedAt` (never physical delete); CSV export always available | Updated lists/charts | SwiftData (edits are first-class) | Yesterday's sets editable; edit trail visible; CSV export works |
| 4 | Progress photo timeline | Photos tab → add photo (front/side/back, optional body weight) → timeline by month → drag slider for aligned comparison | Photo via PhotosPicker/camera, pose tag, optional weight | `PhotoAligner`: Vision face landmark alignment + body-width normalization; Pro: cloud AI compare analysis | Aligned before/after slider (Pro), month grid (free) | `ProgressPhoto` SwiftData (photoData local by default, not uploaded) | Two photos align on slider drag; compare analysis only via AI router with quota |
| 5 | Exercise library (800+) | Exercises tab → search/filter (muscle, equipment) → view instructions + dual-angle images → add to workout | Search text, filters | Bundled `free-exercise-db` JSON parsed at first launch into `Exercise` store; custom exercises addable | Detail view with images, muscle tags | `Exercise` SwiftData (isCustom flag) | 800+ exercises listed offline; images render; custom add works |
| 6 | Plate calculator | Long-press weight cell → sheet shows per-side plates | Target weight | Greedy algorithm over [45, 35, 25, 10, 5, 2.5], standard 45 lb bar | "140 lb → per side: 45 + 10 + 5" | None (pure function) | Correct greedy output; instant, offline |
| 7 | Rest timer | Auto-starts 120 s after ✓; countdown in app + Watch complication + Live Activity-style widget; +30 s / skip | Automatic | Timer state machine; auto-cancels on next set start | Countdown ring; suggestion card visible during rest | None | Timer starts within 1 s of set completion; syncs to Watch |
| 8 | PR detection & celebration | Automatic on ✓ | SetEntry vs history | Epley 1RM = w×(1+r/30); PR if exceeds best | Gold particle burst + haptic + "NEW PR 🏆" | None (computed) | PR fires only on genuine 1RM-beating sets |
| 9 | Weekly recap | Monday 8 AM local notification → tap → 3-screen narrative: strength curve ↑ + photo slider + one-line summary | Volume delta, PR count | On-device AI writes recap sentence (fallback static copy); all date math via `DayKey` (UTC anchor, local render) | Notification + recap page | None (computed) | Notification fires Mondays; copy reflects real numbers |
| 10 | Progress stats | Progress tab → strength curve (one line, "only goes up" framing), weekly volume, muscle balance (Pro advanced stats) | Historical SetEntries | Aggregation via DayKey weeks; volume = w×r summed; 1RM estimates | Charts (Swift Charts) | Computed | Numbers match history exactly; no negative-framing percentile |
| 11 | AI Form Coach | Coach tab → take/select lift photo → on-device pose validation → feedback card | Photo (side view of a lift) | Vision 17-joint check (reject unusable frames without spending quota) → cloud vision AI (GLM via proxy default, or user BYO key) → JSON `{good[], fix[], cue, risk}` → render 3-section card; failure → on-device skeleton rule feedback labeled "Offline mode"; never invents | Feedback card: Did right / Fix next / One cue | Photo NOT stored by default (user may opt to save to timeline) | Unusable photo → re-take guidance, zero quota spent; offline → rule feedback shown honestly |
| 12 | Natural-language logging | Tap mic/text on Today → "bench 3 sets of 8 at 135" → draft pre-filled → confirm | Free text | Apple FM on-device parse into `{exercise, sets, reps, weight}` draft; user must confirm (AI never writes data directly) | Pre-filled SetDraft | Only after user confirm | Parse works on iOS 26+; iOS <26 hides entry or routes to BYO/cloud |
| 13 | Onboarding (45 s, 0 forms) | Splash "Every day is Gainsday." → choose: "I have a plan" (pick 3 exercises) / "Guide me" (classic beginner plan A/B) → immediately log first set with one-time coach bubble | 2 card taps | Seeds default plan; no questionnaire (no height/weight/goals) | First logging screen | Plan + settings flags | Download → first set logged ≤60 s; zero keyboard; zero permission prompts upfront |
| 14 | Detraining welcome-back | Absent ≥14 days → open shows "Welcome back 💪 You only lost 3%..." with −10% prefill | Automatic | DayKey gap computation; prefill = last weight × 0.9 | Welcome card | None | Never shames; prefill correct |
| 15 | Watch app | Raise wrist → current workout present → +5 → ✓ → logged; rest timer complication | Taps | Mirror of phone logging; WCSession sync of active session | Logging UI + timer | Synced via WCSession → SwiftData on phone | Log a set on Watch ≤2 taps; works phone-locked |
| 16 | Widgets | Home Screen widget + Lock Screen accessory: gold calendar grid (days trained) / rest timer | — | Timeline provider reads SwiftData snapshot (app group if needed) | Widget gallery + rendered widgets | Read-only | Calendar grid shows correct gold days; timer counts down |
| 17 | HealthKit mirror | Automatic on set completion | SetEntry aggregates | Write HKWorkout + quantity samples; append-only (never delete); local wins | Health app shows workouts | HealthKit store | Permission requested only at first use; data appears in Health |
| 18 | iCloud sync (CloudKit) | Automatic | All SwiftData models | CKSyncEngine; offline queue; conflict = latest `editedAt` wins; soft-deletes sync | Seamless multi-device | CloudKit (private DB) | Airplane-mode logging merges correctly after reconnect |
| 19 | Share card | End-workout page → Share → gold calendar-grid card ("It's a Gainsday 🏆 — Bench +20 lb in 30 days") | Session summary | Render golden card image via `ImageRenderer` | ShareSheet (TikTok/IG-ready) | None | Card renders with real numbers |
| 20 | Paywall / IAP | Paywall from Pro features or Settings → 3 SKUs → purchase/restore | Purchase taps | StoreKit 2; entitlements: any `gainsday.*` active = Pro; lifetime = non-consumable | Paywall with full price + trial terms + legal links + restore | StoreKit | All 3 SKUs purchasable in sandbox; restore works; legal links present |
| 21 | Settings & quota transparency | Settings → see cloud AI quota meter ("Form checks 12/60 this month"), manage BYO key, export CSV, cancel-subscription shortcut, About/legal | Taps | `QuotaStore` local counter (CloudKit-synced); gate cloud calls per tier | Settings UI | UserDefaults for non-business prefs; Keychain for BYO key | Quota counts accurately; BYO key editable & validated; CSV export works |
| 22 | Plans | 1 plan free (classic A/B seeds); Pro: unlimited plans; edit exercises per day | Plan edits | Plan model referencing Exercises | Plan screens | `Plan`/`PlanDay` SwiftData | Free tier enforces 1-plan limit gracefully; Pro unlocks |
| 23 | Calendar grid | Progress tab → year/month view; achieved days turn gold | — | DayKey aggregation of sessions | Gold-grid view | Computed | Gold cells match session days exactly (timezone-safe) |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 1.1 | 2-tap logging | Weight cell | Tap +5 lb, long-press −2.5 lb; number bounce spring(0.4) | Tap / long-press |
| 1.2 | 2-tap logging | Reps cell | Tap +1, long-press −1 (min 1) | Tap / long-press |
| 1.3 | 2-tap logging | Last-performance prefill | First screen always shows last numbers ("Bench · last: 135 lb × 8") | Automatic |
| 1.4 | 2-tap logging | Celebration | "+5 lb vs last time 🔥" / "NEW PR 🏆" / "Same weight, clean reps." with haptic | Automatic on ✓ |
| 2.1 | OverloadEngine | "Why?" explanation | Pro users tap "Why?" → Apple FM explains the rule result in plain words (free) | Tap |
| 3.1 | History | Edit trail | editedAt shown subtly; never hidden | Automatic |
| 4.1 | Photo timeline | Pose tagging | front / side / back | Segmented picker |
| 4.2 | Photo timeline | Alignment | Face-landmark + body-width normalization | Automatic |
| 11.1 | Form Coach | Frame validation | Rejects photos with <8 confident joints → "Try a wider side view" (no quota spent) | Automatic |
| 11.2 | Form Coach | Risk badge | low / medium / high | Card display |
| 11.3 | Form Coach | Offline mode | On-device skeleton-rule feedback clearly labeled "Offline mode" | Fallback |
| 20.1 | Paywall | Trial transparency | "7 days free, then $19.99/year. Cancel in one tap." + trial-end local reminder 24 h before | Copy + notification |
| 21.1 | Settings | Cancel shortcut | Deep-link to system subscription management | Tap |
| 13.1 | Onboarding | Coach bubble | One-time: "Tap the numbers to change weight, ✓ to log. That's it." | Once flag |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|---|---|---|---|---|
| Set logged → celebration + suggestion | Feature 1 | Features 2/7/8/17 | SetEntry | On ✓ |
| Last performance → prefill | Features 3/18 | Feature 1 | Latest SetEntry per exercise | App open / exercise selected |
| History edits → stats/PR recompute | Feature 3 | Features 8/10/23 | Updated SetEntries | On save |
| Photo add → timeline/compare | Feature 4 | Features 9/11 | ProgressPhoto | On save |
| Exercise DB → plans/logging | Feature 5 | Features 1/22 | Exercise reference | On selection |
| Session end → share card | Feature 1 | Feature 19 | Volume/delta summary | On finish workout |
| Entitlement → feature gating | Feature 20 | Features 4 (compare), 10 (advanced), 11 (quota 60/mo), 22 (unlimited plans) | isPro | On transaction change |
| BYO key → unlimited cloud AI | Feature 21 | Feature 11 | Keychain key presence | On key save |
| Weekly aggregation → recap notification | Features 10/23 | Feature 9 | Volume delta + PR count | Monday 8 AM |
| Detrain gap → welcome prefill | Feature 3 | Feature 1 | Last date + weight | App open |

**VERIFICATION**: The Chinese guide's core loop (§3.1), user flows (§5), data flows (§6), pricing (§8) and milestones (§4.3) map to features 1–23 above — all guide features are covered. ✅

## ⚠️ AI Architecture — Multi-Backend Router (CRITICAL COMPLIANCE POINT)

**Iron rule from the product owner: the BYO configuration must NEVER be hardcoded to a single provider.** The AI layer follows the standard multi-provider architecture:

```
AIRouter (single facade)
├── Tier 0 — Apple Foundation Models (iOS 26 on-device, FREE unlimited)
│    └── Natural-language logging, weekly recap, "Why?" explanations
├── Tier 1 — Embedded cloud backend (default): GLM vision via PROXY
│    └── Proxy base URL injected via glm-api-config (key lives server-side;
│         client holds proxy URL only). Serves: free tier 3 form checks/month,
│         Pro 60/month (transparent QuotaStore meter).
│    └── ⚠️ NEVER serves lifetime-BYO purchasers who haven't bound their own key.
├── Tier 2 — BYO Key (multi-provider, user's own key in Keychain)
│    └── Providers selectable in Settings: GLM (api.z.ai), OpenAI, Google Gemini,
│         DeepSeek, Anthropic Claude, and ANY OpenAI-compatible endpoint
│         (custom base URL + model name + key).
│    └── BYO = UNLIMITED cloud AI, skips quota gates.
└── Tier 3 — On-device rule fallback (Vision skeleton heuristics), labeled "Offline mode"
```

- Vision (form check) requires a vision-capable provider: GLM vision / GPT-4o-class / Gemini / Claude vision. `ProviderProfile` declares `supportsVision`; the router picks the highest-priority available vision-capable backend.
- Language tasks (recap, explanations, NL logging) prefer Tier 0; unavailable (<iOS 26) → Tier 2 → Tier 1 → Tier 3.
- All cloud calls: 8–12 s timeout, 1 retry, JSON-mode constrained prompts, ≤512 KB compressed frames.
- **AI output NEVER writes data directly** — suggestions/drafts require explicit user confirmation.
- Embedded-backend consumption is a consumable: subscription-only with hard quota caps; lifetime SKU never includes developer-paid cloud usage.

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
On-device Foundation Models power language AI on supported devices (iOS 26+), zero configuration.
- **iOS 26+**: works out of the box.
- **iOS < 26**: language AI routes to BYO key → embedded proxy → rule fallback; UI never shows dead buttons (`canUseAI = appleIntelAvailable || hasBYOKey || embeddedQuotaAvailable`).
- **Simulator**: Apple Intelligence unavailable — test with BYO key config.

### BYO API Key (Multi-Provider — REQUIRED)
Settings → AI Backend: choose provider (GLM / OpenAI / Gemini / DeepSeek / Claude / Custom OpenAI-compatible), paste key, optional custom base URL + model. Stored in Keychain. BYO users get unlimited cloud AI.

### Guideline 2.1(a) — Completeness
1. Create `app_review_info.md` with demo configuration instructions.
2. No clickable AI button may lead to an error without an available backend — the fallback chain guarantees a response.
3. No free-generation counters for on-device AI; quota meters exist ONLY for the embedded cloud backend and are shown transparently.

### Dead Code Prevention
- ❌ NEVER add: `freeGenerationsUsed`, `maxFreeGenerations` for on-device features, `canGenerateFree` gating on-device AI, `incrementGenerationCount()` except the transparent embedded-proxy QuotaStore.
- ❌ NEVER serve the embedded proxy to lifetime purchasers without their own key bound.

## ⚠️ App Store Compliance — Subscriptions

Paywall MUST include (Guideline 3.1.2(c)):
- Functional Privacy Policy link + Terms of Use (EULA) link
- Title, length, price of each plan; auto-renewal disclosure
- Restore purchases button; "Cancel in one tap" shortcut

**BYO + subscription framing**: subscription value = "Unlock Premium Features" (photo timeline compare, advanced stats, unlimited plans, cloud form-check quota) — never "unlimited AI generations" (that's what BYO keys provide). AI generation is ALWAYS unlimited for users with their own key.

**Pricing structure** (§8 of source guide, binding):

| Tier | Price | Includes | Cloud AI rule |
|---|---|---|---|
| Free (forever) | $0 | Unlimited logging + unlimited history, 1 plan, 800+ exercises, rest timer, plate calc, PR detection, OverloadEngine suggestions, all on-device AI, Watch, CSV export, iCloud sync | 3 form checks/month via embedded backend (体验 quota, transparent) |
| Pro subscription | **$19.99/yr** (7-day transparent trial) or $3.99/mo | Everything free + unlimited plans + photo timeline & AI compare + cloud form checks 60/month + advanced stats + custom themes | Embedded backend within quota |
| Lifetime BYO | **$49.99** one-time | All Pro **non-consumable** features for life | **Must bind own key** for cloud AI; no key → cloud AI locked with onboarding guide; embedded backend NEVER serves this tier |

🔴 **Consumable red line**: GLM cloud tokens are developer-paid consumables — any developer-funded cloud AI feature may ONLY be sold via subscription with quotas. Lifetime = features only, BYO key for AI.

## Data Reliability Iron Rules (write into code review checklist)

1. **Local-first, never lose**: a set counts only after SwiftData save succeeds; CloudKit is replication, not dependency; full offline functionality.
2. **Suggestions must be explainable**: every `OverloadSuggestion` carries `reason`; forbidden to show reason-free "AI says +10 lb".
3. **AI never writes data**: model output lands only in suggestion/copy layers until user confirms.
4. **Quota transparency**: embedded-backend usage visible in Settings ("12/60 this month"); gentle reminder 3 days before exhaustion; never silent downgrade or upsell popups.
5. **Time math is local & safe**: all "yesterday/this week/streak" via `DayKey` (calendar-day UTC anchor) — never raw `timeIntervalSince` comparisons (fixes the category's classic timezone bug).
6. **Soft delete + edit trail**: history is editable (category's #1 pain point), edits visible via `editedAt`, CSV export always free — data sovereignty = trust.

## Module Structure

```
Gainsday/
├── App/
│   ├── GainsdayApp.swift
│   └── RootTabView.swift
├── Models/                      # SwiftData @Model — single source of truth
│   ├── Exercise.swift
│   ├── WorkoutSession.swift
│   ├── SetEntry.swift
│   ├── ProgressPhoto.swift
│   ├── Plan.swift               # Plan / PlanDay
│   └── DayKey.swift             # timezone-safe day/week keys
├── Services/                    # pure Swift, unit-testable
│   ├── OverloadEngine.swift     # rules + Epley 1RM + PR detect
│   ├── PlateCalculator.swift
│   ├── PhotoAligner.swift       # Vision alignment
│   ├── FormCheckPreprocessor.swift  # Vision pose validation
│   ├── LastPerformanceProvider.swift
│   ├── QuotaStore.swift         # embedded-backend quota meter
│   ├── KeychainStore.swift
│   ├── HealthKitService.swift
│   └── CSVExporter.swift
├── AI/
│   ├── AIConfiguration.swift    # multi-provider profiles & selection
│   ├── AIServiceProtocol.swift  # unified AI facade
│   ├── AppleIntelligenceService.swift  # Tier 0 (iOS 26 FM)
│   ├── CloudAIService.swift     # Tier 1/2 executor (vision + language)
│   ├── ProviderProfile.swift    # GLM / OpenAI / Gemini / DeepSeek / Claude / custom
│   ├── AIRouter.swift           # tiered fallback chain
│   └── AIProfileManager.swift   # BYO key storage (Keychain), provider pick
├── Store/
│   └── PaywallModel.swift       # StoreKit 2
├── Views/
│   ├── Today/                   # 2-tap logging
│   ├── History/
│   ├── Progress/                # stats + calendar grid + recap
│   ├── Photos/                  # timeline + slider compare
│   ├── Exercises/
│   ├── Coach/                   # AI form check
│   ├── Plans/
│   ├── Onboarding/
│   ├── Paywall/
│   └── Settings/
├── WatchApp/                    # 2-tap logging + rest timer
├── Widgets/                     # calendar grid + rest timer widgets
└── Resources/
    └── ExerciseDB/              # free-exercise-db JSON + images (Unlicense)
```

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

```
Feature: 2-tap logging (core loop)
┌────────────────────────────────────────────────────────────┐
│ User Input: tap weight cell (+5/−2.5), tap reps (+1/−1), ✓ │
│      │                                                     │
│ ViewModel: SetDraftViewModel                               │
│  └ prefill from LastPerformanceProvider (SwiftData fetch)  │
│  └ on ✓: OverloadEngine.compare() → celebration message    │
│  └ start RestTimer(120s); HealthKitService.write(workout)  │
│      │                                                     │
│ Persistence: SwiftData SetEntry (UUID, editedAt, deviceID) │
│  ├ UI refresh via @Query (no network wait)                 │
│  ├ CKSyncEngine background sync (offline queue → merge,    │
│  │   conflict = latest editedAt wins)                      │
│  └ HealthKit append-only mirror                            │
│      │                                                     │
│ Display: cells, celebration overlay, rest countdown,       │
│          suggestion card with reason                       │
└────────────────────────────────────────────────────────────┘

Feature: AI Form Coach
┌────────────────────────────────────────────────────────────┐
│ User Input: photo (camera/PhotosPicker)                    │
│      │                                                     │
│ On-device: FormCheckPreprocessor                           │
│  └ VNDetectHumanBodyPoseRequest → 17 joints                │
│  └ reject if <8 confident joints → "re-take" (0 quota)     │
│  └ skeleton overlay render → JPEG ≤512KB                   │
│      │                                                     │
│ AIRouter: BYO vision provider (unlimited) → embedded proxy │
│  (quota-checked via QuotaStore) → on-device rule feedback  │
│      │                                                     │
│ Output: {good[], fix[], cue, risk} card; "Offline mode"    │
│         label when falling back; photo not stored unless   │
│         user opts in                                       │
└────────────────────────────────────────────────────────────┘

Feature: Weekly recap
┌────────────────────────────────────────────────────────────┐
│ Trigger: local notification Monday 08:00 (DayKey week agg) │
│ Input: volume delta, PR count, latest photos               │
│ Processing: Apple FM recap sentence (Tier 0) → fallback    │
│   static template; strength curve + photo slider data      │
│ Output: 3-screen narrative page; no data mutation          │
└────────────────────────────────────────────────────────────┘

Feature: Photo timeline compare
┌────────────────────────────────────────────────────────────┐
│ Input: PhotosPicker photo + pose tag (+optional weight)    │
│ Processing: PhotoAligner (face landmarks, body-width norm) │
│ Persistence: ProgressPhoto.photoData LOCAL (not uploaded)  │
│ Output: month timeline; drag-slider wipe compare (Pro: AI  │
│   compare via vision backend with quota)                   │
└────────────────────────────────────────────────────────────┘
```

**VERIFICATION**: every feature's data path ends in either SwiftData persistence or a pure computed view — no orphan data. ✅

## Implementation Flow

1. Xcode project via xcodegen (App + Watch App + Widgets targets, entitlements: CloudKit, HealthKit, App Groups for widgets).
2. SwiftData models + DayKey; seed free-exercise-db into `Exercise` store on first launch.
3. Today 2-tap logging (cells, prefill, celebration, rest timer).
4. OverloadEngine + PRDetector + PlateCalculator with unit tests (≥90% rule coverage).
5. History editing (soft delete, edit trail) + CSV export.
6. Exercise library browser.
7. Progress tab: strength curve, calendar grid, weekly recap notification + page.
8. Photo timeline + Vision alignment + slider compare.
9. CloudKit sync (CKSyncEngine) + conflict rules; HealthKit mirror.
10. AI layer: AIConfiguration/ProviderProfile/AIRouter/AppleIntelligenceService/CloudAIService/AIProfileManager — multi-provider BYO + embedded proxy + quota store; Form Coach flow with fallbacks.
11. Watch app (WCSession mirror logging + timer complication) + Widgets.
12. StoreKit 2 paywall (3 SKUs, legal links, restore, cancel shortcut) + quota settings UI.
13. Onboarding (3 screens, 0 forms) + detraining welcome-back.
14. Polish: haptics, spring animations, share card, dark/light, Dynamic Type; full simulator verification.

## UI/UX Design Specifications

- **Color**: charcoal `#0E0F12` base; electric orange primary (strength); gold exclusively for PR/celebration; light mode mirrors with same semantics.
- **Typography**: SF Pro Rounded for numerals/headings; SF Pro body; Dynamic Type everywhere.
- **Layout**: single column, large cells; bottom-60% thumb zone holds all high-frequency actions; no nested navigation for core loops.
- **Motion**: number bounce `spring(0.4)`; gold particle burst on PR; drag-slider wipe for photos; all <300 ms.
- **Copy** (US gym-culture voice, user-facing examples):
  - Splash: "Every day is Gainsday."
  - After set: "+5 lb vs last time 🔥" / "NEW PR 🏆" / "Same weight, clean reps. Strength is coming."
  - Workout end: "6,240 lb moved today. +4.2% vs last Push day."
  - Weekly push: "You lifted 380 lb more than last week's you 💪"
  - Welcome back: "Welcome back. You only lost 3%. Let's get it back in 2 weeks."
  - Paywall: "Pro: $19.99/year. 7 days free. Cancel in one tap."
- **AI disclaimer footer** (Form Coach): "AI feedback is a general guide — consult a professional for injuries." 1RM estimates labeled "estimates, not medical advice". No medical/treatment claims anywhere.
- **Attribution**: free-exercise-db (Unlicense) credit in About page.

## Code Generation Rules

- SwiftUI declarative; MV separation — Views render, Domain Services compute; no algorithms in Views.
- SwiftData `@Model` is the ONLY persistence for business data; no UserDefaults business data; AI responses and training data strictly layered.
- Number input = steppers/cells, NEVER a keyboard in core loops.
- AI calls in 3-layer wrapper: `AIRouter → on-device first → cloud (BYO or embedded+quota) → rule fallback`; cloud calls have timeouts (8–12 s), 1 retry, quota gate.
- Localization-ready: all user-visible strings via String Catalog (en first, zero hardcoded strings).
- Privacy by architecture: cloud requests minimal (image/text only, no device fingerprint, no user ID); form-check photos not persisted by default.
- Version read dynamically from `Bundle.main.infoDictionary` — never hardcoded.

## Build & Deployment Checklist

1. xcodegen targets: Gainsday (iOS), GainsdayWatch (watchOS), GainsdayWidgets (WidgetKit); DEVELOPMENT_TEAM_ID baked in.
2. Entitlements: CloudKit (iCloud services), HealthKit, App Groups (widget data), Keychain sharing (BYO key).
3. Bundled assets: free-exercise-db JSON + images; keep attribution.
4. StoreKit configuration file with 3 SKUs: `gainsday.pro.yearly` ($19.99/yr, 7-day trial), `gainsday.pro.monthly` ($3.99/mo), `gainsday.lifetime.byo` ($49.99 non-consumable).
5. Embedded cloud backend: proxy base URL configured via `glm-api-config` (server-side key; client holds URL only) — see `app_review_info.md` for reviewer demo path.
6. Privacy labels: form-check photos "Not Collected"; HealthKit data never used for ads; no account required.
7. Verify: iPhone + iPad simulator builds green; Watch app logs a set in ≤2 taps; widgets render; offline mode complete; sandbox IAP purchase/restore; quota meter accurate.
