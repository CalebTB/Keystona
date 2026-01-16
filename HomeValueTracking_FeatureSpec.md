# Home Value Tracking
## Complete Feature Specification

**Keystona MVP — Core Feature #5**  
*Version 1.0 | January 2026*

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Home Valuation](#2-home-valuation)
3. [Value History](#3-value-history)
4. [Mortgage Tracking](#4-mortgage-tracking)
5. [Equity Calculator](#5-equity-calculator)
6. [Accuracy & Disclaimers](#6-accuracy--disclaimers)
7. [User Flows](#7-user-flows)
8. [UI/UX Specifications](#8-uiux-specifications)
9. [API Integration](#9-api-integration)
10. [Data Model](#10-data-model)
11. [Success Metrics](#11-success-metrics)
12. [Implementation Phases](#12-implementation-phases)
13. [Version 1.5: Plaid Integration](#13-version-15-plaid-integration)

---

## 1. Feature Overview

### 1.1 Purpose

Home Value Tracking provides homeowners with a clear, ongoing picture of their home's estimated value and equity position. For most Americans, their home is their largest asset—yet most homeowners have no idea what it's worth until they decide to sell. This feature demystifies home equity and empowers better financial decisions.

### 1.2 Problem Statement

| Problem | Current Reality | Impact |
|---------|-----------------|--------|
| Don't know home's value | Check Zillow occasionally, forget about it | No ongoing awareness of largest asset |
| No equity visibility | Mental math, guessing | Can't make informed financial decisions |
| Value changes invisible | Only discover at sale or refinance | Miss refinance opportunities |
| Multiple data sources | Zillow says X, Redfin says Y | Confusion, distrust |
| Mortgage balance unknown | Dig through statements | No quick equity calculation |

### 1.3 Solution

A simple, honest home value dashboard that:

- **Shows estimated value** from a reputable Automated Valuation Model (AVM)
- **Tracks value over time** with monthly snapshots
- **Calculates equity** using mortgage balance (manual entry, Plaid in v1.5)
- **Communicates accuracy honestly** — AVMs have limitations
- **Enables better decisions** — know when to refinance, tap equity, or sell

### 1.4 Design Philosophy

```
┌────────────────────────────────────────────────────────────────┐
│              HOME VALUE TRACKING PHILOSOPHY                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  1. SIMPLICITY OVER COMPLEXITY                                 │
│     • One clear value estimate (not 5 different numbers)       │
│     • Simple equity calculation anyone understands             │
│     • No confusing financial jargon                            │
│                                                                │
│  2. HONESTY OVER HYPE                                          │
│     • Always show confidence range, not just point estimate    │
│     • Clear disclaimer that AVMs have 7-8% error margin        │
│     • Never overstate accuracy to drive engagement             │
│                                                                │
│  3. EMPOWERMENT OVER ANXIETY                                   │
│     • Focus on long-term trends, not daily fluctuations        │
│     • Frame equity as progress, not pressure                   │
│     • Don't create "Zillow anxiety" with constant updates      │
│                                                                │
│  4. ACTIONABLE OVER ACADEMIC                                   │
│     • Connect value to decisions (refinance, HELOC, PMI)       │
│     • Surface opportunities, not just data                     │
│     • v1.5+: Proactive refinance and equity alerts             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 1.5 Scope: MVP vs. Future

| Capability | MVP (v1.0) | v1.5 | v2.0+ |
|------------|------------|------|-------|
| Estimated home value | ✅ | ✅ | ✅ |
| Value confidence range | ✅ | ✅ | ✅ |
| Value history chart | ✅ | ✅ | ✅ |
| Manual mortgage entry | ✅ | ✅ | ✅ |
| Equity calculation | ✅ | ✅ | ✅ |
| Accuracy disclaimers | ✅ | ✅ | ✅ |
| Plaid mortgage sync | ❌ | ✅ | ✅ |
| Refinance alerts | ❌ | ✅ | ✅ |
| PMI removal alert | ❌ | ✅ | ✅ |
| HELOC opportunity alert | ❌ | ✅ | ✅ |
| Comparable sales | ❌ | ❌ | ✅ |
| Neighborhood trends | ❌ | ❌ | ✅ |
| Investment analysis | ❌ | ❌ | ✅ |

### 1.6 Success Metrics

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Feature adoption | 60%+ of Premium users | Core Premium value |
| Mortgage balance entered | 50%+ of adopters | Equity calculation enabled |
| Monthly value check | 2+ views/month | Ongoing engagement |
| Premium conversion (cites value tracking) | 20%+ | Monetization driver |
| Time on feature | 45+ seconds | Meaningful engagement |
| Accuracy rating (user survey) | 70%+ "seems right" | Trust in data |

---

## 2. Home Valuation

### 2.1 Overview

The home valuation displays an Automated Valuation Model (AVM) estimate for the user's property. We use the ATTOM Data API as our primary source, which provides valuations based on public records, comparable sales, and proprietary algorithms.

### 2.2 What Users See

```
┌─────────────────────────────────────────────────────────────────┐
│  🏠 YOUR HOME'S ESTIMATED VALUE                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                       $425,000                                  │
│                                                                 │
│              Range: $395,000 – $455,000                         │
│                                                                 │
│              ▲ +$12,500 (+3.0%) from last year                  │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Last updated: January 15, 2026                                 │
│  Source: ATTOM Data                                             │
│                                                                 │
│  [ℹ️ How is this calculated?]                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Value Components

| Component | Description | Display |
|-----------|-------------|---------|
| **Point Estimate** | AVM's best estimate of current market value | Large, prominent number |
| **Low Range** | Lower bound of confidence interval | Shown as range |
| **High Range** | Upper bound of confidence interval | Shown as range |
| **Value Change** | Difference from 12 months ago | Arrow + amount + percentage |
| **Last Updated** | Date of most recent valuation | Below estimate |
| **Data Source** | Attribution to AVM provider | Below estimate |

### 2.4 Value Display Rules

```
┌────────────────────────────────────────────────────────────────┐
│                   VALUE DISPLAY RULES                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  NUMBER FORMATTING:                                            │
│  • Always show whole dollars (no cents)                        │
│  • Use comma separators ($425,000 not $425000)                 │
│  • Round to nearest $1,000 for cleaner display                 │
│    (API returns $424,750 → display $425,000)                   │
│                                                                │
│  CHANGE INDICATORS:                                            │
│  • Positive: Green ▲ +$12,500 (+3.0%)                          │
│  • Negative: Red ▼ -$8,000 (-1.9%)                             │
│  • Flat (<1%): Gray ● $0 (0.0%)                                │
│                                                                │
│  CONFIDENCE RANGE:                                             │
│  • Always show range, never just point estimate                │
│  • Format: "Range: $X – $Y" (use en-dash)                      │
│  • If API doesn't provide range, calculate ±7.5%               │
│                                                                │
│  UPDATE FREQUENCY:                                             │
│  • Fetch new value monthly (not daily)                         │
│  • Cache for 24 hours to minimize API calls                    │
│  • Show "Last updated" date prominently                        │
│                                                                │
│  EDGE CASES:                                                   │
│  • No data available: "Estimate unavailable for this property" │
│  • Very old data (>60 days): Show warning badge                │
│  • API error: Show last known value with "as of [date]"        │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 2.5 "How Is This Calculated?" Explanation

When user taps the info link:

```
┌─────────────────────────────────────────────────────────────────┐
│  ← How Your Home Value is Estimated                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Your home's estimated value comes from an Automated            │
│  Valuation Model (AVM), which uses:                             │
│                                                                 │
│  📊 PUBLIC RECORDS                                              │
│     Recent sales in your area, property tax assessments,        │
│     and deed records                                            │
│                                                                 │
│  🏘️ COMPARABLE SALES                                            │
│     What similar homes nearby have sold for recently            │
│                                                                 │
│  📈 MARKET TRENDS                                               │
│     Local real estate market conditions and price trends        │
│                                                                 │
│  🏠 PROPERTY CHARACTERISTICS                                    │
│     Square footage, bedrooms, bathrooms, lot size, age          │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ⚠️ IMPORTANT LIMITATIONS                                       │
│                                                                 │
│  AVMs are estimates, not appraisals. They cannot see:           │
│  • Interior condition or renovations                            │
│  • Unique features or upgrades                                  │
│  • Deferred maintenance or damage                               │
│                                                                 │
│  For off-market homes, AVMs typically have a 7-8% error         │
│  margin. Your actual value could be higher or lower.            │
│                                                                 │
│  For an accurate value, consider a professional appraisal       │
│  or comparative market analysis from a real estate agent.       │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Data provided by ATTOM Data Solutions                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Value History

### 3.1 Overview

A historical chart showing how the home's estimated value has changed over time. This provides context and helps users understand long-term trends rather than fixating on short-term fluctuations.

### 3.2 Chart Specifications

```
┌─────────────────────────────────────────────────────────────────┐
│  📈 VALUE HISTORY                                    [1Y ▼]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  $450K ┤                                                        │
│        │                                            ╭───        │
│  $425K ┤                                    ╭───────╯           │
│        │                            ╭───────╯                   │
│  $400K ┤                    ╭───────╯                           │
│        │            ╭───────╯                                   │
│  $375K ┤    ╭───────╯                                           │
│        │────╯                                                   │
│  $350K ┤                                                        │
│        └────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬──    │
│           Jan  Mar  May  Jul  Sep  Nov  Jan  Mar  May  Jul      │
│           2025                          2026                    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  SUMMARY                                                        │
│  Starting value (Jan 2025):    $365,000                         │
│  Current value:                $425,000                         │
│  Total change:                 +$60,000 (+16.4%)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Time Period Options

| Period | Data Points | Use Case |
|--------|-------------|----------|
| **1 Year** (default) | 12 monthly | Recent trend |
| **2 Years** | 24 monthly | Medium-term view |
| **5 Years** | 60 monthly | Long-term appreciation |
| **Since Purchase** | All available | Total ownership gains |
| **All Time** | All available | Maximum history |

### 3.4 Chart Interaction

```
┌────────────────────────────────────────────────────────────────┐
│                   CHART INTERACTIONS                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  TAP ON DATA POINT:                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         ●───────────────────────────                    │   │
│  │         │                                               │   │
│  │    ┌────┴────┐                                          │   │
│  │    │ Mar 2025│                                          │   │
│  │    │$385,000 │                                          │   │
│  │    └─────────┘                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  PINCH TO ZOOM: Expand/contract time range                     │
│  SWIPE LEFT/RIGHT: Pan through time (if zoomed)                │
│                                                                │
│  CHART STYLE:                                                  │
│  • Line chart with area fill below                             │
│  • Gradient fill (darker at line, fading down)                 │
│  • Data points shown on tap, not always visible                │
│  • Smooth curve (bezier interpolation)                         │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 3.5 Data Point Storage

```
┌────────────────────────────────────────────────────────────────┐
│                  VALUE HISTORY STORAGE                         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  SNAPSHOT FREQUENCY: Monthly (1st of each month)               │
│                                                                │
│  SNAPSHOT DATA:                                                │
│  {                                                             │
│    date: "2025-03-01",                                         │
│    estimatedValue: 385000,                                     │
│    lowRange: 358000,                                           │
│    highRange: 412000,                                          │
│    source: "attom",                                            │
│    confidence: 0.85                                            │
│  }                                                             │
│                                                                │
│  RETENTION: Keep all historical data indefinitely              │
│  (small storage footprint, high user value)                    │
│                                                                │
│  BACKFILL: When user signs up, attempt to retrieve             │
│  historical values if API supports it (ATTOM does)             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 3.6 Empty State

For new users without history:

```
┌─────────────────────────────────────────────────────────────────┐
│  📈 VALUE HISTORY                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                         📊                                      │
│                                                                 │
│              Your value history is building                     │
│                                                                 │
│     We'll track your home's value over time so you can          │
│     see how it changes month to month and year to year.         │
│                                                                 │
│     Check back next month for your first comparison.            │
│                                                                 │
│                                                                 │
│  Current value: $425,000                                        │
│  Tracking since: January 2026                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Mortgage Tracking

### 4.1 Overview

To calculate equity, we need the mortgage balance. In MVP, users enter this manually. In v1.5, we'll add Plaid integration for automatic sync.

### 4.2 Information Captured (MVP - Manual Entry)

| Field | Description | Required |
|-------|-------------|----------|
| **Current Balance** | Outstanding loan principal | Yes |
| **Original Loan Amount** | Initial mortgage amount | Recommended |
| **Interest Rate** | Current rate (for context) | Optional |
| **Loan Type** | Fixed, ARM, FHA, VA, etc. | Optional |
| **Monthly Payment** | Principal + Interest (P&I) | Optional |
| **Lender Name** | For reference | Optional |
| **Loan Start Date** | When mortgage began | Optional |

### 4.3 Multiple Mortgages

Users may have:
- Primary mortgage (1st lien)
- Home equity loan (2nd lien)
- HELOC (line of credit)

```
┌─────────────────────────────────────────────────────────────────┐
│  🏦 YOUR MORTGAGES                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PRIMARY MORTGAGE                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Wells Fargo                                            │    │
│  │  Balance: $285,000                                      │    │
│  │  Rate: 6.25% Fixed                                      │    │
│  │  Payment: $1,847/mo                                     │    │
│  │  Last updated: January 10, 2026           [Edit]        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  HOME EQUITY LOAN                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Chase Bank                                             │    │
│  │  Balance: $25,000                                       │    │
│  │  Rate: 8.5% Fixed                                       │    │
│  │  Payment: $312/mo                                       │    │
│  │  Last updated: January 10, 2026           [Edit]        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  TOTAL MORTGAGE DEBT: $310,000                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  [+ Add Another Loan]                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.4 Update Reminders

Since mortgage balance is manually entered:

```
┌────────────────────────────────────────────────────────────────┐
│                  UPDATE REMINDER LOGIC                         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  REMINDER FREQUENCY: Monthly                                   │
│                                                                │
│  TRIGGER: If balance not updated in 30+ days                   │
│                                                                │
│  NOTIFICATION:                                                 │
│  "📊 Update your mortgage balance to see accurate equity.      │
│   Your last update was 32 days ago."                           │
│                                                                │
│  IN-APP PROMPT:                                                │
│  Show subtle banner on Home Value screen when stale            │
│                                                                │
│  SETTING: User can disable update reminders                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 4.5 No Mortgage Scenario

For users who own outright:

```
┌─────────────────────────────────────────────────────────────────┐
│  🏦 MORTGAGE                                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Do you have a mortgage on this property?                       │
│                                                                 │
│  ┌───────────────────────┐  ┌───────────────────────┐           │
│  │  Yes, add mortgage    │  │  No, I own outright   │           │
│  └───────────────────────┘  └───────────────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

If "No, I own outright":
- Equity = 100% of home value
- Skip mortgage section entirely
- Celebrate their position! 🎉

---

## 5. Equity Calculator

### 5.1 Overview

The equity calculator shows the simple but powerful equation:

**Equity = Estimated Home Value - Total Mortgage Debt**

### 5.2 Equity Display

```
┌─────────────────────────────────────────────────────────────────┐
│  💰 YOUR HOME EQUITY                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                       $115,000                                  │
│                        27% equity                               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░│    │
│  │◄──────── Equity ────────►│◄────── Mortgage ──────────►│    │
│  │         $115,000          │          $310,000          │    │
│  │           27%             │            73%             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  THE MATH                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Estimated Home Value          $425,000                 │    │
│  │  − Primary Mortgage            $285,000                 │    │
│  │  − Home Equity Loan            $25,000                  │    │
│  │  ─────────────────────────────────────                  │    │
│  │  = Your Equity                 $115,000                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ⚠️ Equity is estimated. Actual equity depends on your          │
│     home's true market value, which can only be determined      │
│     through a sale or professional appraisal.                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Equity Progress Bar

Visual representation of equity vs. debt:

```
┌────────────────────────────────────────────────────────────────┐
│                  EQUITY PROGRESS BAR                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  DESIGN:                                                       │
│  • Horizontal bar, full width of container                     │
│  • Left portion (green): Equity                                │
│  • Right portion (gray): Remaining mortgage                    │
│  • Percentage labels below each section                        │
│                                                                │
│  COLOR CODING:                                                 │
│  • Equity: Green (#4CAF50)                                     │
│  • Mortgage: Gray (#E0E0E0)                                    │
│  • Bar background: Light gray (#F5F5F5)                        │
│                                                                │
│  MILESTONES (subtle markers on bar):                           │
│  • 20% - PMI removal threshold                                 │
│  • 50% - Halfway point                                         │
│  • 80% - Strong equity position                                │
│                                                                │
│  ANIMATION:                                                    │
│  • Bar fills smoothly when data loads                          │
│  • Subtle pulse on milestone achievement                       │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 5.4 Equity Milestones

```
┌─────────────────────────────────────────────────────────────────┐
│  🎯 EQUITY MILESTONES                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✅ 10% equity — Congratulations on building equity!            │
│                                                                 │
│  ✅ 20% equity — You may be able to remove PMI                  │
│     └── [Learn about PMI removal →]                             │
│                                                                 │
│  🔲 30% equity — Strong position for HELOC ($XX,XXX available)  │
│     └── 3% more to go                                           │
│                                                                 │
│  🔲 50% equity — You're halfway to owning outright!             │
│     └── 23% more to go                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.5 Equity Without Mortgage Data

If user hasn't entered mortgage:

```
┌─────────────────────────────────────────────────────────────────┐
│  💰 YOUR HOME EQUITY                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    Add your mortgage                            │
│                   to see your equity                            │
│                                                                 │
│  Your home is estimated at $425,000. Enter your mortgage        │
│  balance to calculate how much equity you've built.             │
│                                                                 │
│                   [Add Mortgage Info]                           │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  No mortgage? [I own my home outright]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Accuracy & Disclaimers

### 6.1 Philosophy

We have an ethical obligation to be honest about AVM limitations. Overstating accuracy erodes trust and can lead to bad financial decisions.

### 6.2 Always-Visible Disclaimers

| Context | Disclaimer |
|---------|------------|
| **Below estimate** | "Range: $X – $Y" (always show range) |
| **Value card** | Link: "How is this calculated?" |
| **Equity section** | "Equity is estimated. Actual equity depends on true market value." |
| **First-time view** | Full explanation modal (one-time) |

### 6.3 First-Time Explanation Modal

Shown once when user first accesses Home Value:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                              ✕  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                          📊                                     │
│                                                                 │
│              About Home Value Estimates                         │
│                                                                 │
│  We use an Automated Valuation Model (AVM) to estimate          │
│  your home's value based on public records, comparable          │
│  sales, and market data.                                        │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ⚠️ WHAT TO KNOW                                                │
│                                                                 │
│  • AVMs are estimates, not appraisals                           │
│                                                                 │
│  • For off-market homes, AVMs have a typical                    │
│    error margin of 7-8%                                         │
│                                                                 │
│  • AVMs can't see interior condition, upgrades,                 │
│    or unique features                                           │
│                                                                 │
│  • Your actual value may be higher or lower                     │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  This estimate is useful for tracking trends and                │
│  understanding your general equity position, but should         │
│  not be used as the sole basis for major financial decisions.   │
│                                                                 │
│                      [Got It]                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 AVM Confidence Score

If available from API, show confidence indicator:

```
┌────────────────────────────────────────────────────────────────┐
│                   CONFIDENCE INDICATORS                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  HIGH CONFIDENCE (score 0.85+):                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ●●●●● High confidence estimate                         │   │
│  │  Many comparable sales, stable market                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  MEDIUM CONFIDENCE (score 0.70-0.84):                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ●●●○○ Moderate confidence estimate                     │   │
│  │  Some comparable sales available                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  LOW CONFIDENCE (score <0.70):                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ●●○○○ Lower confidence estimate                        │   │
│  │  Limited comparable data for this property              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  If confidence score not available from API, don't display     │
│  this indicator (avoid showing something misleading).          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 6.5 What We Don't Say

To maintain trust, we avoid:

| Avoid | Why |
|-------|-----|
| "Your home is worth $X" | Implies certainty; use "estimated value" |
| "Zestimate-accurate" | Making claims we can't back up |
| "Real-time value" | AVMs update periodically, not in real-time |
| "Guaranteed" | Nothing about AVMs is guaranteed |
| "Bank-accepted" | Banks use their own appraisals |

---

## 7. User Flows

### 7.1 First-Time Setup Flow

```
┌────────────────────────────────────────────────────────────────┐
│                HOME VALUE SETUP FLOW                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ENTRY POINT: User navigates to Home Value tab (Premium)       │
│                                                                │
│  STEP 1: Explanation Modal                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "About Home Value Estimates"                           │   │
│  │  [Full disclaimer - shown once]                         │   │
│  │                                                         │   │
│  │  [Got It]                                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 2: Fetching Value                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "Getting your home's estimated value..."               │   │
│  │  [Loading animation]                                    │   │
│  │                                                         │   │
│  │  Using: 123 Main Street, Anytown, CA 90210              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 3: Value Reveal                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "Your home's estimated value"                          │   │
│  │                                                         │   │
│  │  $425,000                                               │   │
│  │  Range: $395,000 - $455,000                             │   │
│  │                                                         │   │
│  │  [See Your Equity →]                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 4: Mortgage Prompt                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "Add your mortgage to see your equity"                 │   │
│  │                                                         │   │
│  │  [Add Mortgage]    [I Own Outright]    [Skip for Now]   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 5: (If Add Mortgage) Enter Mortgage Details              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Current balance: [__________]                          │   │
│  │  (Optional details...)                                  │   │
│  │                                                         │   │
│  │  [Save]                                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 6: Equity Summary                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "Your estimated equity"                                │   │
│  │                                                         │   │
│  │  $115,000 (27%)                                         │   │
│  │  [Progress bar]                                         │   │
│  │                                                         │   │
│  │  [Done - Go to Dashboard]                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 7.2 Add Mortgage Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Add Mortgage                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CURRENT BALANCE *                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ 285,000                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│  Enter your most recent statement balance                       │
│                                                                 │
│  LOAN TYPE                                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Fixed Rate                                         ▼   │    │
│  └─────────────────────────────────────────────────────────┘    │
│  Options: Fixed Rate, Adjustable (ARM), FHA, VA, USDA, Other    │
│                                                                 │
│  INTEREST RATE (optional)                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  6.25 %                                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ORIGINAL LOAN AMOUNT (optional)                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ 320,000                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  MONTHLY PAYMENT (optional)                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ 1,847                                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│  Principal + Interest only (exclude taxes/insurance)            │
│                                                                 │
│  LENDER (optional)                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Wells Fargo                                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  💡 In a future update, you'll be able to connect your          │
│     mortgage account to sync this automatically.                │
│                                                                 │
│                         [Save Mortgage]                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.3 Update Mortgage Balance Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Update Balance                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  WELLS FARGO MORTGAGE                                           │
│                                                                 │
│  Previous balance: $287,500                                     │
│  Last updated: December 10, 2025                                │
│                                                                 │
│  NEW BALANCE                                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ 285,000                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Change: -$2,500 (principal paid down)                          │
│                                                                 │
│                          [Update]                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. UI/UX Specifications

### 8.1 Home Value Dashboard (Main Screen)

```
┌─────────────────────────────────────────────────────────────────┐
│  Home Value                                            Premium  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  🏠 ESTIMATED VALUE                                     │    │
│  │                                                         │    │
│  │                    $425,000                             │    │
│  │            Range: $395,000 – $455,000                   │    │
│  │                                                         │    │
│  │            ▲ +$12,500 (+3.0%) past year                 │    │
│  │                                                         │    │
│  │  Updated Jan 15, 2026        [ℹ️ How calculated?]       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  💰 YOUR EQUITY                                         │    │
│  │                                                         │    │
│  │  $115,000                          27% equity           │    │
│  │                                                         │    │
│  │  ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │    │
│  │  ◄── Equity ──►        ◄──── Mortgage ────►            │    │
│  │                                                         │    │
│  │  [View Details]                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  📈 VALUE HISTORY                              [1Y ▼]   │    │
│  │                                                         │    │
│  │       ╭─────────────────────────────────────╮           │    │
│  │      ╱                                       ╲          │    │
│  │  ───╯                                         ╲───      │    │
│  │  Jan    Mar    May    Jul    Sep    Nov    Jan          │    │
│  │                                                         │    │
│  │  [View Full History]                                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  🏦 MORTGAGE                                            │    │
│  │                                                         │    │
│  │  Total Debt: $310,000                                   │    │
│  │  Primary: $285,000 • HELOC: $25,000                     │    │
│  │                                                         │    │
│  │  [Manage Mortgages]                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Card Styles

```
┌────────────────────────────────────────────────────────────────┐
│                      CARD DESIGN SYSTEM                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  VALUE CARD (Hero):                                            │
│  • Background: Gradient (light blue to white)                  │
│  • Value: 36pt bold, dark text                                 │
│  • Range: 14pt, medium gray                                    │
│  • Change: 16pt, green (up) or red (down)                      │
│  • Corner radius: 16px                                         │
│  • Shadow: Subtle drop shadow                                  │
│                                                                │
│  EQUITY CARD:                                                  │
│  • Background: White                                           │
│  • Value: 28pt bold                                            │
│  • Progress bar: 12px height, rounded                          │
│  • Corner radius: 12px                                         │
│                                                                │
│  CHART CARD:                                                   │
│  • Background: White                                           │
│  • Chart area: 180px height minimum                            │
│  • Axis labels: 12pt, light gray                               │
│  • Line: 2px, primary blue                                     │
│  • Fill: Gradient, 20% opacity                                 │
│                                                                │
│  MORTGAGE CARD:                                                │
│  • Background: Light gray (#F5F5F5)                            │
│  • Text: 14pt, dark gray                                       │
│  • Compact layout                                              │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 8.3 Color System

| Element | Color | Hex |
|---------|-------|-----|
| Value increase | Green | #4CAF50 |
| Value decrease | Red | #F44336 |
| Value flat | Gray | #9E9E9E |
| Equity portion | Green | #4CAF50 |
| Mortgage portion | Gray | #E0E0E0 |
| Chart line | Blue | #2196F3 |
| Chart fill | Blue (20%) | #2196F333 |
| Confidence high | Green | #4CAF50 |
| Confidence medium | Yellow | #FFC107 |
| Confidence low | Orange | #FF9800 |

### 8.4 Premium Gating

Home Value is a Premium feature:

```
┌─────────────────────────────────────────────────────────────────┐
│  Home Value                                               🔒    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                          📊                                     │
│                                                                 │
│              Track Your Home's Value                            │
│                                                                 │
│  See your home's estimated value, track changes over            │
│  time, and understand your equity position.                     │
│                                                                 │
│  ✓ Automated home valuation                                     │
│  ✓ Value history over time                                      │
│  ✓ Equity calculator                                            │
│  ✓ Coming soon: Refinance alerts                                │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Included with Keystona Premium                                │
│  $7.99/month                                                    │
│                                                                 │
│                    [Upgrade to Premium]                         │
│                                                                 │
│                    [Learn More]                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. API Integration

### 9.1 Primary Data Source: ATTOM

```
┌────────────────────────────────────────────────────────────────┐
│                    ATTOM DATA API                              │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ENDPOINT: Property AVM                                        │
│  URL: api.gateway.attomdata.com/propertyapi/v1.0.0/avm         │
│                                                                │
│  REQUEST:                                                      │
│  GET /avm/detail?address1=123+Main+St&address2=Anytown,+CA     │
│                                                                │
│  RESPONSE (simplified):                                        │
│  {                                                             │
│    "property": {                                               │
│      "address": {...},                                         │
│      "avm": {                                                  │
│        "amount": {                                             │
│          "value": 425000,                                      │
│          "low": 395250,                                        │
│          "high": 454750,                                       │
│          "valueRange": 59500                                   │
│        },                                                      │
│        "calculated": "2026-01-15",                             │
│        "confidence": 0.85                                      │
│      }                                                         │
│    }                                                           │
│  }                                                             │
│                                                                │
│  COST: ~$500/month starting tier                               │
│  RATE LIMITS: Varies by plan                                   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 9.2 API Caching Strategy

```
┌────────────────────────────────────────────────────────────────┐
│                   CACHING STRATEGY                             │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  GOAL: Minimize API costs while providing fresh data           │
│                                                                │
│  CACHE RULES:                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  • Cache AVM response for 24 hours                      │   │
│  │  • Store monthly snapshots permanently                  │   │
│  │  • Force refresh: Only on 1st of month or user request  │   │
│  │  • Manual refresh: Limit to 1 per week per property     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  REFRESH TRIGGERS:                                             │
│  • 1st of each month (automated snapshot)                      │
│  • User taps "Refresh" (rate limited)                          │
│  • Cache expires after 24 hours + user views                   │
│                                                                │
│  COST ESTIMATION (1,000 Premium users):                        │
│  • Monthly snapshot: 1,000 calls = ~$X                         │
│  • User-initiated: ~500 calls/month = ~$Y                      │
│  • Total: Within $500/month tier                               │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 9.3 Fallback: Zillow Widget

If ATTOM costs are prohibitive for MVP:

```
┌────────────────────────────────────────────────────────────────┐
│                   ZILLOW FALLBACK OPTION                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  OPTION: Embed Zillow Zestimate widget                         │
│                                                                │
│  PROS:                                                         │
│  • Free                                                        │
│  • Well-known brand                                            │
│  • Automatic updates                                           │
│                                                                │
│  CONS:                                                         │
│  • Less control over presentation                              │
│  • Can't store history (their data, their terms)               │
│  • Links to Zillow (sends users away)                          │
│  • May not be available for all properties                     │
│                                                                │
│  RECOMMENDATION: Use ATTOM for MVP. Widget is backup only.     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 9.4 Error Handling

| Error | User Message | Action |
|-------|--------------|--------|
| Property not found | "We couldn't find valuation data for this address. This sometimes happens with new construction or unique properties." | Offer to verify address |
| API timeout | "We're having trouble getting your home's value. Please try again in a few minutes." | Show last cached value if available |
| API rate limit | "We've reached our data limit. Your value will update automatically tomorrow." | Show cached value |
| Low confidence | Show value with "Lower confidence" indicator | Display but flag |
| No data available | "Valuation data isn't available for this property. This may be due to limited comparable sales in your area." | Hide value section, show explanation |

---

## 10. Data Model

### 10.1 Home Valuation Object

```javascript
HomeValuation {
  id: string
  propertyId: string
  
  // Current value
  estimatedValue: number
  lowRange: number
  highRange: number
  confidence: number | null (0-1)
  
  // Source
  source: 'attom' | 'zillow' | 'manual'
  sourceCalculatedDate: date
  fetchedAt: timestamp
  
  // Cache control
  cacheExpiresAt: timestamp
  
  // Audit
  createdAt: timestamp
  updatedAt: timestamp
}
```

### 10.2 Value History Object

```javascript
ValueSnapshot {
  id: string
  propertyId: string
  
  // Snapshot data
  snapshotDate: date (1st of month)
  estimatedValue: number
  lowRange: number
  highRange: number
  confidence: number | null
  
  // Source
  source: 'attom' | 'zillow' | 'manual'
  
  // Audit
  createdAt: timestamp
}
```

### 10.3 Mortgage Object

```javascript
Mortgage {
  id: string
  userId: string
  propertyId: string
  
  // Core data
  currentBalance: number
  balanceAsOfDate: date
  
  // Loan details
  loanType: 'fixed' | 'arm' | 'fha' | 'va' | 'usda' | 'other'
  interestRate: number | null
  originalLoanAmount: number | null
  monthlyPayment: number | null
  lenderName: string | null
  loanStartDate: date | null
  
  // Classification
  mortgageType: 'primary' | 'heloc' | 'home_equity_loan' | 'other'
  lienPosition: 1 | 2 | 3
  
  // Sync (v1.5)
  plaidAccountId: string | null
  plaidLastSync: timestamp | null
  isManualEntry: boolean
  
  // Audit
  createdAt: timestamp
  updatedAt: timestamp
}
```

### 10.4 Balance History Object

```javascript
MortgageBalanceHistory {
  id: string
  mortgageId: string
  
  // Snapshot
  balance: number
  recordedDate: date
  source: 'manual' | 'plaid'
  
  // Audit
  createdAt: timestamp
}
```

### 10.5 Equity Calculation (Derived)

```javascript
// Not stored - calculated on demand

calculateEquity(propertyId) {
  const valuation = getLatestValuation(propertyId)
  const mortgages = getMortgages(propertyId)
  
  const totalDebt = mortgages.reduce((sum, m) => sum + m.currentBalance, 0)
  const equity = valuation.estimatedValue - totalDebt
  const equityPercent = (equity / valuation.estimatedValue) * 100
  
  return {
    estimatedValue: valuation.estimatedValue,
    totalMortgageDebt: totalDebt,
    estimatedEquity: equity,
    equityPercentage: equityPercent,
    mortgageCount: mortgages.length
  }
}
```

### 10.6 Database Indexes

```sql
-- Valuations
CREATE INDEX idx_valuation_property ON home_valuations(property_id);
CREATE INDEX idx_valuation_date ON home_valuations(source_calculated_date);

-- Value snapshots
CREATE INDEX idx_snapshot_property_date ON value_snapshots(property_id, snapshot_date);

-- Mortgages
CREATE INDEX idx_mortgage_property ON mortgages(property_id);
CREATE INDEX idx_mortgage_user ON mortgages(user_id);

-- Balance history
CREATE INDEX idx_balance_mortgage_date ON mortgage_balance_history(mortgage_id, recorded_date);
```

---

## 11. Success Metrics

### 11.1 Adoption

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Feature views (Premium users) | 60%+ | Core Premium value |
| Mortgage entered | 50%+ of viewers | Equity enabled |
| Value history viewed | 40%+ | Engagement depth |
| Return visits | 2+/month | Ongoing value |

### 11.2 Engagement

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Time on feature | 45+ seconds | Meaningful engagement |
| Chart interactions | 30%+ tap/zoom | Feature discovery |
| Mortgage updates | Monthly | Data freshness |
| Refresh button taps | <5%/month | Data is fresh enough |

### 11.3 Data Quality

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Valuation success rate | 95%+ | Coverage |
| API error rate | <1% | Reliability |
| "Value seems wrong" feedback | <5% | Trust |
| Mortgage data completeness | 3+ fields | Richer data |

### 11.4 Business Impact

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Premium conversion (cites value) | 20%+ | Monetization driver |
| Premium retention (uses feature) | +15% | Stickiness |
| Refinance lead clicks (v1.5) | 10%+ | Revenue opportunity |
| Feature NPS | 40+ | Satisfaction |

---

## 12. Implementation Phases

### Phase 1: Foundation (Week 1)

**Goal:** Data model and API integration.

- [ ] HomeValuation data model
- [ ] ValueSnapshot data model
- [ ] ATTOM API integration
- [ ] Basic API error handling
- [ ] Caching layer (24-hour cache)

**Exit Criteria:** Can fetch and store valuation for a property.

### Phase 2: Value Display (Week 2)

**Goal:** Show home value to users.

- [ ] Value card UI
- [ ] Confidence range display
- [ ] Value change calculation (YoY)
- [ ] "How calculated" explanation
- [ ] First-time explanation modal
- [ ] Loading and error states

**Exit Criteria:** User can see their home's estimated value.

### Phase 3: Value History (Week 3)

**Goal:** Historical value chart.

- [ ] Monthly snapshot job
- [ ] Historical backfill (if API supports)
- [ ] Value history chart
- [ ] Time period selector (1Y, 2Y, 5Y, All)
- [ ] Chart interactions (tap, zoom)
- [ ] Empty state for new users

**Exit Criteria:** User can see value trend over time.

### Phase 4: Mortgage Tracking (Week 4)

**Goal:** Manual mortgage entry.

- [ ] Mortgage data model
- [ ] Add mortgage flow
- [ ] Edit mortgage flow
- [ ] Multiple mortgage support
- [ ] Balance update flow
- [ ] Update reminders
- [ ] "Own outright" option

**Exit Criteria:** User can enter and update mortgage info.

### Phase 5: Equity Calculator (Week 5)

**Goal:** Equity display and milestones.

- [ ] Equity calculation logic
- [ ] Equity display card
- [ ] Progress bar visualization
- [ ] "The Math" breakdown
- [ ] Equity milestones
- [ ] No-mortgage state

**Exit Criteria:** User can see their equity position.

### Phase 6: Polish & Premium (Week 6)

**Goal:** Premium gating and polish.

- [ ] Premium feature gating
- [ ] Premium upsell screen
- [ ] Dashboard integration
- [ ] Performance optimization
- [ ] Accessibility review
- [ ] Analytics events
- [ ] Bug fixes

**Exit Criteria:** Feature ready for launch.

---

## 13. Version 1.5: Plaid Integration

### 13.1 Overview

Plaid Liabilities API enables automatic mortgage balance sync, eliminating manual entry and ensuring equity is always accurate.

### 13.2 User Flow

```
┌────────────────────────────────────────────────────────────────┐
│                   PLAID CONNECT FLOW                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  STEP 1: Prompt to Connect                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "Connect your mortgage for automatic updates"          │   │
│  │                                                         │   │
│  │  Link your mortgage account to automatically sync       │   │
│  │  your balance. No more manual updates.                  │   │
│  │                                                         │   │
│  │  🔒 Secure connection via Plaid                         │   │
│  │  📊 Read-only access to balance                         │   │
│  │  🔄 Auto-updates monthly                                │   │
│  │                                                         │   │
│  │  [Connect Mortgage]    [Keep Manual Entry]              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 2: Plaid Link (OAuth)                                    │
│  • Select lender                                               │
│  • Login to lender account                                     │
│  • Authorize read-only access                                  │
│                                                                │
│  STEP 3: Confirmation                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ✓ Mortgage connected                                   │   │
│  │                                                         │   │
│  │  Wells Fargo Mortgage                                   │   │
│  │  Balance: $285,000                                      │   │
│  │  Rate: 6.25%                                            │   │
│  │  Monthly Payment: $1,847                                │   │
│  │                                                         │   │
│  │  We'll update this automatically each month.            │   │
│  │                                                         │   │
│  │  [Done]                                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 13.3 Data Retrieved via Plaid

| Field | Source | Notes |
|-------|--------|-------|
| Current balance | Plaid Liabilities | Primary value |
| Original loan amount | Plaid | If available |
| Interest rate | Plaid | Current rate |
| Monthly payment | Plaid | P&I amount |
| Account name | Plaid | Lender name |
| Escrow balance | Plaid | If available |
| PMI status | Plaid | If available |
| Next payment date | Plaid | If available |

### 13.4 Sync Behavior

```
┌────────────────────────────────────────────────────────────────┐
│                   PLAID SYNC RULES                             │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  SYNC FREQUENCY: Daily check, update if changed                │
│                                                                │
│  SYNC TRIGGER:                                                 │
│  • Nightly batch job (all connected accounts)                  │
│  • User opens Home Value screen (if >24h since sync)           │
│  • User taps "Refresh"                                         │
│                                                                │
│  BALANCE CHANGE HANDLING:                                      │
│  • Store new balance                                           │
│  • Update equity calculation                                   │
│  • Log to balance history                                      │
│                                                                │
│  CONNECTION ISSUES:                                            │
│  • Auth expired: Prompt to reconnect                           │
│  • Lender unavailable: Show last known, flag as stale          │
│  • Account closed: Prompt to remove or mark paid off           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 13.5 V1.5 Additional Features

| Feature | Description |
|---------|-------------|
| **Refinance Alerts** | Notify when rates drop 0.5%+ below user's rate |
| **PMI Removal Alert** | Notify when equity reaches 20% (LTV ≤ 80%) |
| **HELOC Opportunity** | Notify when equity reaches 30%+ ($X available) |
| **ARM Adjustment Warning** | Alert before ARM rate adjusts |

---

## Appendix A: AVM Accuracy Context

### Industry Context

| Metric | Typical AVM Performance |
|--------|-------------------------|
| Median error (on-market) | 2-3% |
| Median error (off-market) | 7-8% |
| 90% confidence interval | ±15-20% |
| Properties with no estimate | 5-10% |

### Factors Affecting Accuracy

| Factor | Impact on Accuracy |
|--------|-------------------|
| Recent comparable sales | Higher accuracy |
| Unique/custom homes | Lower accuracy |
| Rural areas | Lower accuracy |
| New construction | Lower accuracy |
| Recent renovations | AVM may not reflect |
| Deferred maintenance | AVM may not reflect |
| Interior condition | AVM cannot assess |

---

## Appendix B: Competitor Analysis

| Competitor | Approach | Limitations |
|------------|----------|-------------|
| **Zillow** | Zestimate, very prominent | Accuracy issues, over-promises |
| **Redfin** | Redfin Estimate | Similar to Zillow |
| **Realtor.com** | RealEstimate | Less prominent |
| **HomeZada** | Manual + Zillow | Dated, not integrated |
| **Trulia** | Zillow-powered | Zillow acquisition |

### Keystona Differentiation

1. **Honest about limitations** — Always show range, explain methodology
2. **Integrated with equity** — Not just value, but what it means
3. **Part of home management** — Value in context of maintenance, documents
4. **Actionable insights (v1.5+)** — Refinance alerts, PMI removal
5. **No "Zestimate anxiety"** — Monthly updates, not daily

---

## Appendix C: Regulatory Considerations

### Disclaimers Required

1. **Not an appraisal** — AVMs are not substitutes for professional appraisals
2. **Estimate only** — Actual value determined by market transaction
3. **No lending decision** — Should not be used as sole basis for lending
4. **Data limitations** — Based on available public data, may be incomplete

### Fair Housing Considerations

- AVM algorithms must not discriminate based on protected classes
- ATTOM and major providers are subject to fair lending compliance
- Keystona displays data, does not create the model

---

*End of Home Value Tracking Feature Specification*
