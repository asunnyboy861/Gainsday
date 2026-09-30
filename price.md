# Pricing Configuration

## Monetization Model: Subscription (IAP) + One-Time Lifetime (BYO)

Free download with a genuinely usable free tier, a $19.99/year auto-renewable Pro subscription (7-day transparent trial) as the primary tier, a $3.99/month alternative in the same subscription group, and a $49.99 non-consumable lifetime that unlocks non-consumable Pro features only. Iron rule: developer-paid cloud AI is a consumable — it is NEVER bundled into the one-time lifetime purchase; lifetime users must bring their own AI key for cloud AI.

## Subscription Group
- **Group Name**: Gainsday Pro
- **Reference Name**: Gainsday Pro
- **Products in group**: gainsday.pro.yearly, gainsday.pro.monthly

## Subscription Tiers (Auto-Renewable)

### 1. Yearly Subscription (Primary)
- **Reference Name**: Gainsday Pro Annual
- **Product ID**: `gainsday.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $19.99 USD per year ($1.67/mo effective — 58% savings vs monthly)
- **Display Name**: `Gainsday Pro Yearly` (19 chars, ≤35 ✅)
- **Description**: `All Pro features. 7-day free trial included` (43 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Gainsday Pro
- **Restore Purchases**: ✅ Required

### 2. Monthly Subscription
- **Reference Name**: Gainsday Pro Monthly
- **Product ID**: `gainsday.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $3.99 USD per month
- **Display Name**: `Gainsday Pro Monthly` (20 chars, ≤35 ✅)
- **Description**: `All Pro features, billed monthly. Cancel anytime` (48 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Gainsday Pro (same group as yearly)
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Lifetime (BYO)
- **Reference Name**: Gainsday Lifetime BYO
- **Product ID**: `gainsday.lifetime.byo`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $49.99 USD (one-time)
- **Display Name**: `Gainsday Lifetime` (17 chars, ≤35 ✅)
- **Description**: `All Pro features forever. Bring your own AI key` (47 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **⚠️ DIFFERENTIATION NOTE (MANDATORY)**: Lifetime unlocks every non-consumable Pro feature (unlimited plans, photo timeline, advanced stats, custom themes) permanently — but it does NOT include the developer-paid cloud form-check quota. Cloud AI form checks on this tier work ONLY with the user's own API key (BYO, unlimited); on-device AI remains fully available without any key. Users who want the zero-config embedded cloud quota choose the subscription.

## Free Tier (Default)
- **Price**: Free
- **Features**:
  - Unlimited workout logging + unlimited history (no time ceiling)
  - 1 training plan (classic beginner A/B seeds included)
  - 800+ exercise library (bundled, offline)
  - Rest timer, plate calculator, PR detection
  - OverloadEngine "beat last time" suggestions with reasons
  - ALL on-device AI (weekly recap, natural-language logging, suggestion explanations — Apple Foundation Models, iOS 26+)
  - Apple Watch logging, Home Screen/Lock Screen widgets
  - iCloud sync, CSV export
  - Cloud AI form checks: 3/month via embedded backend (transparent quota meter)
- **Conversion hooks**:
  - "Your full history, forever — free."
  - "Photo timeline & advanced stats await in Pro."
  - "Add your own AI key for unlimited cloud form checks — on any tier."

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (Yearly / Monthly) | Lifetime (BYO) |
|---------|:----:|:----------------------:|:--------------:|
| Workout logging, history, editing | ✅ | ✅ | ✅ |
| Unlimited plans | ❌ (1 plan) | ✅ | ✅ |
| 800+ exercise library, rest timer, plate calc, PR | ✅ | ✅ | ✅ |
| OverloadEngine suggestions | ✅ | ✅ | ✅ |
| On-device AI (recap / NL logging / explanations) | ✅ | ✅ | ✅ |
| Watch app + widgets + iCloud sync + CSV export | ✅ | ✅ | ✅ |
| Progress photo timeline (aligned slider compare) | ❌ | ✅ | ✅ |
| Photo AI compare analysis (vision backend) | ❌ | ✅ | ✅ |
| Advanced stats (volume / 1RM / muscle balance) | ❌ | ✅ | ✅ |
| Custom themes | ❌ | ✅ | ✅ |
| Cloud AI form checks — embedded backend quota | 3/month | 60/month | ❌ Not included — BYO key only |
| Cloud AI form checks — user's own key (BYO) | ✅ Unlimited | ✅ Unlimited | ✅ Unlimited |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to $19.99/year)
- **Available for**: gainsday.pro.yearly only (transparent terms shown before start; trial-end local reminder 24 h before)

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page ("cancel in one tap" shortcut in Settings)
- [x] Pricing clearly stated in PaywallView ($19.99/year, $3.99/month, $49.99 once)
- [x] Free trial terms included (7 days, then $19.99/year; 24 h reminder)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO Key model: AI generation unlimited with user's own key on every tier; no `freeGenerationsUsed` / `maxFreeGenerations` dead code; embedded-backend quota meter exists only for the developer-paid cloud quota (3/mo free, 60/mo Pro) and is shown transparently
- [x] Consumable red line: lifetime SKU never includes developer-funded cloud AI usage
