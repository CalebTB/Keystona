# Emergency Hub
## Complete Feature Specification

**Keystona MVP — Core Feature #4**  
*Version 1.0 | January 2026*

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Utility Shutoff Guides](#2-utility-shutoff-guides)
3. [Emergency Contacts](#3-emergency-contacts)
4. [Insurance Information](#4-insurance-information)
5. [Emergency Procedures](#5-emergency-procedures)
6. [Offline Architecture](#6-offline-architecture)
7. [Emergency Mode UI](#7-emergency-mode-ui)
8. [User Flows](#8-user-flows)
9. [UI/UX Specifications](#9-uiux-specifications)
10. [Integration Points](#10-integration-points)
11. [Data Model](#11-data-model)
12. [Success Metrics](#12-success-metrics)
13. [Implementation Phases](#13-implementation-phases)

---

## 1. Feature Overview

### 1.1 Purpose

The Emergency Hub is a centralized, **offline-capable** repository for critical home emergency information. When disaster strikes—a burst pipe, gas leak, or electrical fire—homeowners need instant access to shutoff locations, emergency contacts, and insurance details, even without internet connectivity. This is Keystona's key differentiator: **no competitor executes offline emergency access well**.

### 1.2 Problem Statement

| Emergency Scenario | Current Reality | Impact |
|--------------------|-----------------|--------|
| Burst pipe flooding basement | Homeowner doesn't know where water shutoff is | Thousands in water damage while searching |
| Gas smell detected | Can't find gas meter or shutoff valve | Safety risk, delayed response |
| Electrical fire/sparking | Don't know which breaker controls what | Dangerous delay, potential injury |
| Major damage occurs | Insurance policy info buried in files | Delayed claims, missed coverage |
| Need emergency plumber | Scrambling to find a number at 2 AM | Longer wait, potential scam services |
| Internet is down during emergency | Cloud-only apps are useless | No access to critical information |

### 1.3 Solution

An offline-first emergency information center that provides:

- **Utility shutoff locations** with photos, instructions, and tool requirements
- **One-tap emergency contacts** for trusted service providers
- **Insurance quick-reference** with policy numbers and claims process
- **Step-by-step emergency procedures** for common home emergencies
- **100% offline access** — works even when power/internet is out
- **High-contrast emergency UI** — readable in low-light/stress situations

### 1.4 Core Value Propositions

| Value | How We Deliver |
|-------|----------------|
| **Find shutoffs instantly** | Photo-documented locations with clear instructions |
| **Call help immediately** | One-tap dialing to trusted contractors |
| **File claims faster** | Insurance info at your fingertips |
| **Stay calm under pressure** | Step-by-step guides for emergencies |
| **Works without internet** | Full offline functionality |
| **Readable in any condition** | High-contrast emergency mode |

### 1.5 Key Differentiator: Offline-First

```
┌────────────────────────────────────────────────────────────────┐
│                  WHY OFFLINE MATTERS                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  SCENARIO: Basement flooding at 2 AM                           │
│                                                                │
│  ❌ TYPICAL APPS:                                               │
│  ├── App requires login → Server timeout                       │
│  ├── Data stored in cloud → No internet = no access            │
│  ├── Photos won't load → Can't see shutoff location            │
│  └── Result: Scrambling while water damage mounts              │
│                                                                │
│  ✅ HOMETRACK EMERGENCY HUB:                                    │
│  ├── No login required for emergency data                      │
│  ├── All data cached locally on device                         │
│  ├── Photos stored offline (compressed)                        │
│  ├── One-tap to call plumber                                   │
│  └── Result: Water off in 60 seconds                           │
│                                                                │
│  EMERGENCIES WHEN INTERNET FAILS:                              │
│  • Power outage (router down)                                  │
│  • Natural disasters (infrastructure damaged)                  │
│  • Flooding (equipment damaged)                                │
│  • Rural areas (weak connectivity)                             │
│  • Basement emergencies (poor signal)                          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 1.6 Success Metrics

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Emergency Hub completion rate | 70%+ | Users have documented their home |
| All shutoffs documented | 60%+ | Core safety value delivered |
| Emergency contacts added | 3+ per user | Help is one tap away |
| Insurance info completed | 50%+ | Claims readiness |
| Offline data synced | 100% | Reliability when needed |
| Time to find shutoff (user test) | <30 seconds | Usability under stress |

---

## 2. Utility Shutoff Guides

### 2.1 Overview

The most critical Emergency Hub feature: photo-documented utility shutoff locations with clear, step-by-step instructions anyone can follow—even someone unfamiliar with the home.

### 2.2 Water Shutoff

#### Information Captured

| Field | Description | Required |
|-------|-------------|----------|
| **Main Shutoff Location** | Where in the home (basement, crawlspace, utility room, exterior) | Yes |
| **Location Photo** | Wide shot showing shutoff in context | Yes |
| **Valve Close-up Photo** | Detail of the valve itself | Recommended |
| **Valve Type** | Ball valve, gate valve, or other | Yes |
| **Turn Direction** | Clockwise or counterclockwise to close | Yes |
| **Tools Required** | None, adjustable wrench, shutoff key, etc. | Yes |
| **Special Instructions** | Any home-specific notes | Optional |
| **Secondary Shutoffs** | Locations of fixture-specific shutoffs | Optional |

#### Valve Types Guide

```
┌─────────────────────────────────────────────────────────────────┐
│                    WATER VALVE TYPES                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BALL VALVE (Most Common Modern)                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [========●========]  ← Lever handle                    │    │
│  │                                                         │    │
│  │  • Quarter turn (90°) to close                          │    │
│  │  • Handle parallel to pipe = OPEN                       │    │
│  │  • Handle perpendicular to pipe = CLOSED                │    │
│  │  • No tools typically needed                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  GATE VALVE (Older Homes)                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │       ╭───╮                                             │    │
│  │       │ ○ │  ← Round wheel handle                       │    │
│  │       ╰───╯                                             │    │
│  │                                                         │    │
│  │  • Multiple turns to close (5-10 rotations)             │    │
│  │  • Turn clockwise to close                              │    │
│  │  • May be stiff if not used regularly                   │    │
│  │  • No tools typically needed                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  CURB STOP / STREET VALVE                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Located at property line/meter box                     │    │
│  │                                                         │    │
│  │  • Requires special curb key/shutoff tool               │    │
│  │  • Use if main valve fails or is inaccessible           │    │
│  │  • May require calling water company                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Step-by-Step Instructions Template

```
┌─────────────────────────────────────────────────────────────────┐
│  💧 SHUT OFF WATER                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LOCATION: Basement, northwest corner, behind furnace           │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [LOCATION PHOTO]                     │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  VALVE TYPE: Ball Valve (lever handle)                          │
│  TOOLS NEEDED: None                                             │
│                                                                 │
│  INSTRUCTIONS:                                                  │
│  ─────────────────────────────────────────────────              │
│  1. Locate the valve (see photo above)                          │
│                                                                 │
│  2. Turn the lever 90° clockwise                                │
│     ┌──────────────────────────────────┐                        │
│     │  OPEN: ═══●═══  →  CLOSED: ═══   │                        │
│     │              ↓               │   │                        │
│     │              ●               │   │                        │
│     └──────────────────────────────────┘                        │
│                                                                 │
│  3. Verify water is off:                                        │
│     • Open a faucet - water should stop                         │
│     • Flush a toilet - tank should not refill                   │
│                                                                 │
│  ⚠️ NOTE: If valve is stuck, do NOT force it.                   │
│     Call a plumber or use the street shutoff.                   │
│                                                                 │
│  SECONDARY SHUTOFFS:                                            │
│  • Under kitchen sink (for kitchen only)                        │
│  • Behind toilet (for toilet only)                              │
│  • Under bathroom sinks (for sinks only)                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  [📞 Call Plumber]                              [Edit Info]     │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Gas Shutoff

#### Information Captured

| Field | Description | Required |
|-------|-------------|----------|
| **Meter Location** | Exterior location of gas meter | Yes |
| **Meter Photo** | Photo showing meter and shutoff | Yes |
| **House-Side Valve Location** | Interior shutoff if exists | Optional |
| **Valve Type** | Lever or rectangular lug | Yes |
| **Tools Required** | Adjustable wrench, gas wrench, etc. | Yes |
| **Gas Company Phone** | Emergency number for gas company | Yes |
| **Safety Warnings** | Home-specific hazards or notes | Auto-included |

#### Safety Warnings (Always Displayed)

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚠️ GAS SAFETY WARNINGS                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🚨 IF YOU SMELL GAS:                                           │
│  ────────────────────                                           │
│  1. Do NOT turn on/off any lights or switches                   │
│  2. Do NOT use phones inside the house                          │
│  3. Do NOT light matches or create sparks                       │
│  4. Leave the house immediately                                 │
│  5. Call gas company from outside or neighbor's house           │
│  6. Do NOT re-enter until cleared by gas company                │
│                                                                 │
│  🔧 AFTER SHUTTING OFF GAS:                                     │
│  ─────────────────────────                                      │
│  • Do NOT attempt to turn gas back on yourself                  │
│  • Gas company must relight pilot lights                        │
│  • Have all appliances checked before restoring                 │
│                                                                 │
│  📞 GAS EMERGENCY: [Gas Company Number]                         │
│     or call 911                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Gas Shutoff Instructions Template

```
┌─────────────────────────────────────────────────────────────────┐
│  🔥 SHUT OFF GAS                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  METER LOCATION: Left side of house, near AC unit               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [METER PHOTO]                        │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  VALVE TYPE: Rectangular lug (requires wrench)                  │
│  TOOLS NEEDED: Adjustable wrench or gas shutoff wrench          │
│                                                                 │
│  INSTRUCTIONS:                                                  │
│  ─────────────────────────────────────────────────              │
│  1. Locate the shutoff valve on the inlet pipe                  │
│     (between meter and house)                                   │
│                                                                 │
│  2. Using a wrench, turn the valve 1/4 turn                     │
│     ┌──────────────────────────────────┐                        │
│     │  ON:  ═══█═══  →  OFF: ═══       │                        │
│     │              ↓           █       │                        │
│     │                          ║       │                        │
│     └──────────────────────────────────┘                        │
│     When OFF, the valve is perpendicular to the pipe            │
│                                                                 │
│  3. Verify: Pilot lights will go out, gas appliances stop       │
│                                                                 │
│  ⚠️ Do NOT turn gas back on yourself.                           │
│     Call gas company to restore service.                        │
│                                                                 │
│  💡 TIP: Keep a gas shutoff wrench near the meter               │
│     or in your emergency kit.                                   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  [📞 Call Gas Company]     [🚨 Call 911]         [Edit Info]    │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 Electrical Panel

#### Information Captured

| Field | Description | Required |
|-------|-------------|----------|
| **Panel Location** | Where in the home | Yes |
| **Panel Photo** | Photo of closed panel | Yes |
| **Open Panel Photo** | Photo showing breakers | Recommended |
| **Main Breaker Location** | Position in panel (usually top) | Yes |
| **Main Breaker Amperage** | 100A, 200A, etc. | Recommended |
| **Circuit Directory** | List of what each breaker controls | Recommended |
| **Special Notes** | GFCI locations, subpanels, etc. | Optional |

#### Circuit Directory Template

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚡ CIRCUIT DIRECTORY                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  MAIN BREAKER: 200A (Top of panel)                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  #   │ AMP │ DESCRIPTION                                │    │
│  ├──────┼─────┼────────────────────────────────────────────┤    │
│  │  1   │ 20A │ Kitchen outlets (east wall)                │    │
│  │  2   │ 20A │ Kitchen outlets (west wall)                │    │
│  │  3   │ 15A │ Dining room / Living room                  │    │
│  │  4   │ 15A │ Master bedroom                             │    │
│  │  5   │ 15A │ Bedroom 2 + Bedroom 3                      │    │
│  │  6   │ 15A │ Bathroom (GFCI)                            │    │
│  │  7   │ 20A │ Garage outlets                             │    │
│  │  8   │ 15A │ Exterior outlets (GFCI)                    │    │
│  │  9   │ 30A │ Dryer (240V)                               │    │
│  │  10  │ 50A │ Range/Oven (240V)                          │    │
│  │  11  │ 20A │ Dishwasher                                 │    │
│  │  12  │ 20A │ Refrigerator                               │    │
│  │  13  │ 20A │ Washer                                     │    │
│  │  14  │ 30A │ AC Condenser (240V)                        │    │
│  │  15  │ 15A │ Furnace / Air Handler                      │    │
│  │  16  │ 20A │ Water Heater (if electric)                 │    │
│  └──────┴─────┴────────────────────────────────────────────┘    │
│                                                                 │
│  [+ Add Circuit]                          [Edit Directory]      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Electrical Shutoff Instructions

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚡ SHUT OFF ELECTRICITY                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PANEL LOCATION: Garage, east wall                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [PANEL PHOTO]                        │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  TO SHUT OFF ALL POWER:                                         │
│  ─────────────────────────────────────────────────              │
│  1. Open the panel door                                         │
│  2. Locate the MAIN BREAKER (largest, usually at top)           │
│  3. Flip the main breaker to OFF                                │
│                                                                 │
│  TO SHUT OFF ONE CIRCUIT:                                       │
│  ─────────────────────────────────────────────────              │
│  1. Find the circuit in the directory above                     │
│  2. Flip that specific breaker to OFF                           │
│  3. Verify power is off before working                          │
│                                                                 │
│  ⚠️ SAFETY:                                                     │
│  • Stand on dry surface when operating panel                    │
│  • Use flashlight, not candles, if power is out                 │
│  • If breaker keeps tripping, call an electrician               │
│  • Never touch wires inside the panel                           │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  [📞 Call Electrician]                          [Edit Info]     │
└─────────────────────────────────────────────────────────────────┘
```

### 2.5 Additional Shutoffs (Optional)

Users can document additional utility shutoffs:

| Utility | Common Locations |
|---------|-----------------|
| **Sprinkler System** | Basement, utility room, or exterior |
| **Pool/Spa Equipment** | Pool equipment pad |
| **Sump Pump** | Basement or crawlspace |
| **Well Pump** | Near pressure tank |
| **Propane Tank** | At tank location |
| **Solar System** | Rapid shutdown at inverter/panel |
| **Generator** | At generator location |
| **HVAC System** | At disconnect near unit |

---

## 3. Emergency Contacts

### 3.1 Overview

One-tap calling to trusted service providers and emergency services. Contacts are organized by category and include key details beyond just a phone number.

### 3.2 Contact Categories

```
┌────────────────────────────────────────────────────────────────┐
│                  EMERGENCY CONTACT CATEGORIES                  │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  🚨 EMERGENCY SERVICES (Pre-populated)                         │
│  ├── 911 - Police/Fire/Ambulance                               │
│  ├── Poison Control: 1-800-222-1222                            │
│  └── Local non-emergency police                                │
│                                                                │
│  🔧 HOME SERVICES (User adds)                                  │
│  ├── Plumber                                                   │
│  ├── Electrician                                               │
│  ├── HVAC Technician                                           │
│  ├── General Contractor                                        │
│  ├── Handyman                                                  │
│  ├── Locksmith                                                 │
│  └── Appliance Repair                                          │
│                                                                │
│  🏠 UTILITIES (User adds)                                      │
│  ├── Electric Company                                          │
│  ├── Gas Company                                               │
│  ├── Water Company                                             │
│  ├── Internet/Cable Provider                                   │
│  └── Trash/Recycling                                           │
│                                                                │
│  🛡️ INSURANCE (User adds)                                      │
│  ├── Insurance Agent                                           │
│  ├── Claims Hotline                                            │
│  └── Roadside Assistance                                       │
│                                                                │
│  👥 PERSONAL (User adds)                                       │
│  ├── Neighbor with spare key                                   │
│  ├── Family emergency contact                                  │
│  ├── Pet emergency contact                                     │
│  └── Landlord/Property Manager                                 │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 3.3 Contact Card Information

| Field | Description | Required |
|-------|-------------|----------|
| **Name/Company** | Contact or company name | Yes |
| **Category** | From list above | Yes |
| **Phone (Primary)** | Main contact number | Yes |
| **Phone (Secondary)** | After-hours or alternate | Optional |
| **Available Hours** | "24/7" or "M-F 8-5" | Optional |
| **Notes** | Special instructions, account numbers | Optional |
| **Is Favorite** | Show in quick-access section | Optional |
| **Added From** | Manual or from Maintenance Calendar | Auto |

### 3.4 Contact Card UI

```
┌─────────────────────────────────────────────────────────────────┐
│  EMERGENCY CONTACTS                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ⭐ FAVORITES (One-tap calling)                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │    │
│  │  │    💧    │  │    ⚡    │  │    🔥    │  │    🛡️    │ │    │
│  │  │ Plumber  │  │Electrician│ │   HVAC   │  │Insurance │ │    │
│  │  │   CALL   │  │   CALL   │  │   CALL   │  │   CALL   │ │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🔧 HOME SERVICES                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  💧 ABC Plumbing                                        │    │
│  │     (555) 123-4567 • 24/7 Emergency                     │    │
│  │     ──────────────────────────────                      │    │
│  │     [📞 Call]  [💬 Text]  [ℹ️ Details]                   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  ⚡ Smith Electric                                       │    │
│  │     (555) 234-5678 • M-F 7am-6pm, Emergency avail       │    │
│  │     ──────────────────────────────────────────────      │    │
│  │     [📞 Call]  [💬 Text]  [ℹ️ Details]                   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  🌡️ Comfort Air HVAC                                    │    │
│  │     (555) 345-6789 • 24/7                               │    │
│  │     ──────────────────────────────────────────────      │    │
│  │     [📞 Call]  [💬 Text]  [ℹ️ Details]                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🏠 UTILITIES                                      [View All →] │
│                                                                 │
│  🛡️ INSURANCE                                      [View All →] │
│                                                                 │
│                         [+ Add Contact]                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.5 Contact Detail View

```
┌─────────────────────────────────────────────────────────────────┐
│  ←                                          ⭐ Favorite   [⋮]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                          💧                                     │
│                    ABC Plumbing                                 │
│                   Plumber • 24/7                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │              [     📞 CALL NOW     ]                    │    │
│  │                  (555) 123-4567                         │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  CONTACT INFO                                                   │
│  ├── Primary Phone      (555) 123-4567                          │
│  ├── After Hours        (555) 123-9999                          │
│  ├── Email              service@abcplumbing.com                 │
│  └── Website            abcplumbing.com                         │
│                                                                 │
│  AVAILABILITY                                                   │
│  └── 24/7 Emergency Service                                     │
│                                                                 │
│  NOTES                                                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Account #: 12345                                       │    │
│  │  Used for water heater install (2023)                   │    │
│  │  Ask for Mike - he knows our house                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  SERVICE HISTORY (from Maintenance Calendar)                    │
│  ├── Jan 2024 - Water heater replacement ($1,200)               │
│  ├── Jun 2023 - Faucet repair ($150)                            │
│  └── Mar 2023 - Drain cleaning ($175)                           │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  [💬 Text]        [📧 Email]        [🗺️ Directions]            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Insurance Information

### 4.1 Overview

Quick-access insurance reference for filing claims during emergencies. Not a replacement for full policy documents, but instant access to critical details.

### 4.2 Information Captured

#### Homeowners/Renters Insurance

| Field | Description | Required |
|-------|-------------|----------|
| **Insurance Company** | Company name | Yes |
| **Policy Number** | Full policy number | Yes |
| **Policy Type** | Homeowners, Renters, Condo | Yes |
| **Coverage Amount** | Dwelling coverage | Recommended |
| **Deductible** | Standard deductible | Recommended |
| **Agent Name** | Personal agent | Recommended |
| **Agent Phone** | Agent direct line | Recommended |
| **Agent Email** | Agent email | Optional |
| **Claims Phone** | 24/7 claims hotline | Yes |
| **Policy Expiration** | Renewal date | Recommended |
| **Linked Document** | Policy PDF in Document Vault | Optional |

#### Additional Policies (Optional)

| Policy Type | Key Information |
|-------------|-----------------|
| **Flood Insurance** | Separate policy required in flood zones |
| **Earthquake Insurance** | Separate policy in seismic areas |
| **Umbrella Policy** | Additional liability coverage |
| **Home Warranty** | Appliance/system coverage |

### 4.3 Insurance Card UI

```
┌─────────────────────────────────────────────────────────────────┐
│  🛡️ INSURANCE INFO                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  HOMEOWNERS INSURANCE                                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │  STATE FARM                                             │    │
│  │  Policy #: HO-1234567-89                                │    │
│  │                                                         │    │
│  │  Dwelling Coverage:    $350,000                         │    │
│  │  Deductible:           $1,000                           │    │
│  │  Expires:              March 15, 2026                   │    │
│  │                                                         │    │
│  │  ──────────────────────────────────────────────────     │    │
│  │                                                         │    │
│  │  AGENT: Jane Smith                                      │    │
│  │  [📞 (555) 456-7890]     [📧 Email Agent]               │    │
│  │                                                         │    │
│  │  24/7 CLAIMS: 1-800-732-5246                            │    │
│  │  [📞 FILE A CLAIM]                                      │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  WHAT TO DO WHEN FILING A CLAIM                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  1. Document damage with photos/video BEFORE cleanup    │    │
│  │  2. Make temporary repairs to prevent further damage    │    │
│  │  3. Keep all receipts for emergency repairs             │    │
│  │  4. Call claims hotline within 24 hours                 │    │
│  │  5. Don't throw away damaged items until adjuster sees  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ADDITIONAL COVERAGE                                            │
│  ├── 🌊 Flood Insurance: Not enrolled  [+ Add]                  │
│  └── 🏠 Home Warranty: American Home Shield [View]              │
│                                                                 │
│  [📄 View Policy Document]              [✏️ Edit Info]          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.4 Claims Checklist

Pre-populated guidance for filing claims:

```
┌─────────────────────────────────────────────────────────────────┐
│  📋 DAMAGE DOCUMENTATION CHECKLIST                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BEFORE YOU CLEAN UP:                                           │
│  ☐ Take photos of all damage (wide + close-up)                  │
│  ☐ Take video walkthrough of affected areas                     │
│  ☐ Note date and time damage occurred                           │
│  ☐ Write description of what happened                           │
│                                                                 │
│  IMMEDIATE STEPS:                                               │
│  ☐ Make temporary repairs to prevent further damage             │
│  ☐ Keep receipts for all emergency repairs                      │
│  ☐ Keep damaged items for adjuster inspection                   │
│  ☐ Start inventory of damaged/lost items                        │
│                                                                 │
│  FILE YOUR CLAIM:                                               │
│  ☐ Call claims hotline within 24-48 hours                       │
│  ☐ Get claim number and adjuster contact                        │
│  ☐ Provide photos and documentation                             │
│  ☐ Schedule adjuster visit                                      │
│                                                                 │
│  [📸 Document Damage Now]              [📞 Call Claims]         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Emergency Procedures

### 5.1 Overview

Step-by-step guides for common home emergencies. Simple, clear instructions that work under stress.

### 5.2 Procedure Categories

| Category | Emergencies Covered |
|----------|---------------------|
| **Water** | Burst pipe, flooding, water heater leak, toilet overflow, sump pump failure |
| **Fire** | Kitchen fire, electrical fire, smoke detector activation, fire escape |
| **Gas** | Gas smell, gas leak, carbon monoxide alarm |
| **Electrical** | Power outage, sparking outlet, breaker tripping, electrical fire |
| **Weather** | Tornado, hurricane, severe storm, power outage, flooding |
| **Security** | Break-in, suspicious activity, lock-out |
| **Medical** | Injury at home, poison exposure |

### 5.3 Procedure Template

Each procedure follows a consistent format:

```
┌─────────────────────────────────────────────────────────────────┐
│  🚨 [EMERGENCY TYPE]                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ⚠️ DANGER ASSESSMENT                                           │
│  [Quick check: Is it safe to act?]                              │
│                                                                 │
│  🚶 STEP-BY-STEP ACTIONS                                        │
│  1. [First action]                                              │
│  2. [Second action]                                             │
│  3. [Third action]                                              │
│  ...                                                            │
│                                                                 │
│  📞 WHO TO CALL                                                 │
│  [One-tap call buttons]                                         │
│                                                                 │
│  ⏭️ NEXT STEPS                                                  │
│  [After immediate emergency is handled]                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4 Example: Burst Pipe

```
┌─────────────────────────────────────────────────────────────────┐
│  💧 BURST PIPE / FLOODING                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ⚠️ DANGER CHECK:                                               │
│  • Is water near electrical outlets? → Turn off power first     │
│  • Is flooding severe? → Evacuate, call 911                     │
│                                                                 │
│  🚶 STEP BY STEP:                                               │
│  ─────────────────────────────────────────────────              │
│                                                                 │
│  STEP 1: SHUT OFF WATER                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Your shutoff: Basement, NW corner                      │    │
│  │  [📍 View Location & Instructions]                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  STEP 2: SHUT OFF ELECTRICITY (if water near outlets)           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Panel location: Garage, east wall                      │    │
│  │  [📍 View Location & Instructions]                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  STEP 3: CALL A PLUMBER                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [📞 ABC Plumbing - (555) 123-4567]                     │    │
│  │  24/7 Emergency Service                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  STEP 4: DOCUMENT DAMAGE (for insurance)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  • Take photos of water source and damage               │    │
│  │  • Note time discovered                                 │    │
│  │  [📸 Open Camera]                                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  STEP 5: BEGIN CLEANUP                                          │
│  • Remove standing water (wet vac, mops, towels)                │
│  • Move furniture and valuables                                 │
│  • Set up fans for drying                                       │
│  • Consider calling water damage restoration                    │
│                                                                 │
│  ⏭️ AFTER THE EMERGENCY:                                        │
│  ─────────────────────────────────────────────────              │
│  ☐ File insurance claim within 24 hours                         │
│  ☐ Get plumber's report for insurance                           │
│  ☐ Check for mold within 24-48 hours                            │
│  ☐ Schedule any needed repairs                                  │
│                                                                 │
│  [🛡️ View Insurance Info]          [📞 Call Insurance]         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.5 Example: Gas Leak

```
┌─────────────────────────────────────────────────────────────────┐
│  🔥 GAS LEAK / GAS SMELL                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🚨 CRITICAL - READ FIRST:                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ❌ Do NOT turn on/off ANY lights or switches           │    │
│  │  ❌ Do NOT use your phone INSIDE the house              │    │
│  │  ❌ Do NOT light matches, lighters, or candles          │    │
│  │  ❌ Do NOT start your car in the garage                 │    │
│  │                                                         │    │
│  │  ✅ LEAVE THE HOUSE IMMEDIATELY                         │    │
│  │  ✅ Call from outside or a neighbor's house             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🚶 STEP BY STEP:                                               │
│  ─────────────────────────────────────────────────              │
│                                                                 │
│  STEP 1: EVACUATE IMMEDIATELY                                   │
│  • Get everyone out of the house                                │
│  • Leave doors open as you exit (helps gas dissipate)           │
│  • Move at least 100 feet away from the house                   │
│                                                                 │
│  STEP 2: CALL GAS COMPANY (from outside)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [📞 Gas Company: (555) 999-8888]                       │    │
│  │  OR                                                     │    │
│  │  [🚨 Call 911]                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  STEP 3: IF SAFE, SHUT OFF GAS AT METER                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Only if you can do so without re-entering the house    │    │
│  │  Your meter: Left side of house, near AC unit           │    │
│  │  [📍 View Shutoff Instructions]                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  STEP 4: WAIT FOR CLEARANCE                                     │
│  • Do NOT re-enter until gas company clears the house           │
│  • Gas company will check for leaks and relight pilots          │
│                                                                 │
│  ⚠️ Carbon Monoxide Warning:                                    │
│  If CO detector is alarming, follow same evacuation steps.      │
│  CO is odorless - trust your detector.                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.6 All Procedures List

| Emergency | Key Actions |
|-----------|-------------|
| **Burst Pipe** | Shut water → Shut power if needed → Call plumber → Document |
| **Toilet Overflow** | Turn valve behind toilet → Use plunger → Clean/disinfect |
| **Water Heater Leak** | Shut water to heater → Shut power/gas → Call plumber |
| **Sump Pump Failure** | Check power → Check float → Remove water manually → Call pro |
| **Kitchen Fire** | Turn off heat → Cover with lid/baking soda → Never use water on grease |
| **Electrical Fire** | Cut power at panel → Use Class C extinguisher → Call 911 |
| **Gas Smell** | Evacuate → Call from outside → Don't use switches |
| **CO Alarm** | Evacuate → Call 911 → Don't re-enter until cleared |
| **Power Outage** | Check breakers → Check neighbors → Call utility → Use flashlights |
| **Sparking Outlet** | Turn off breaker → Don't use outlet → Call electrician |
| **Tornado Warning** | Go to basement/interior room → Stay away from windows |
| **Hurricane** | Follow evacuation orders → Secure home → Document for insurance |
| **Break-In** | Call 911 → Don't enter if in progress → Document for police |
| **Lock-Out** | Call locksmith → Check all entries → Consider spare key plan |

---

## 6. Offline Architecture

### 6.1 Design Principles

```
┌────────────────────────────────────────────────────────────────┐
│                   OFFLINE-FIRST ARCHITECTURE                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  PRINCIPLE 1: Emergency data is ALWAYS available               │
│  ───────────────────────────────────────────────               │
│  • All Emergency Hub data stored locally                       │
│  • No network request required to view                         │
│  • Works in airplane mode, basement, power outage              │
│                                                                │
│  PRINCIPLE 2: Sync when possible, cache always                 │
│  ───────────────────────────────────────────────               │
│  • Changes sync to cloud when online                           │
│  • Local database is source of truth for reads                 │
│  • Conflict resolution favors most recent change               │
│                                                                │
│  PRINCIPLE 3: Minimal storage footprint                        │
│  ───────────────────────────────────────────────               │
│  • Photos compressed to max 500KB each                         │
│  • Only essential data cached (not full documents)             │
│  • Total offline footprint target: <50MB per property          │
│                                                                │
│  PRINCIPLE 4: Graceful degradation                             │
│  ───────────────────────────────────────────────               │
│  • If photo fails to load, show placeholder + text             │
│  • If contact call fails, show number to dial manually         │
│  • Never show "no connection" error for cached data            │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 6.2 Data Storage Strategy

```
┌────────────────────────────────────────────────────────────────┐
│                     STORAGE ARCHITECTURE                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     LOCAL DEVICE                          │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  SQLite Database (Emergency Data)                  │  │  │
│  │  │  ├── Utility shutoffs (text + refs)                │  │  │
│  │  │  ├── Emergency contacts                            │  │  │
│  │  │  ├── Insurance info                                │  │  │
│  │  │  ├── Emergency procedures                          │  │  │
│  │  │  └── Last sync timestamp                           │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  Local File Storage (Photos)                       │  │  │
│  │  │  ├── shutoff_water_main.jpg (≤500KB)               │  │  │
│  │  │  ├── shutoff_water_detail.jpg (≤500KB)             │  │  │
│  │  │  ├── shutoff_gas.jpg (≤500KB)                      │  │  │
│  │  │  ├── electrical_panel.jpg (≤500KB)                 │  │  │
│  │  │  └── electrical_panel_open.jpg (≤500KB)            │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                            ↕ Sync                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                       CLOUD                               │  │
│  │  ├── Firestore (structured data)                         │  │
│  │  └── Cloud Storage (full-res photos)                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 6.3 Sync Behavior

| Scenario | Behavior |
|----------|----------|
| **App opened online** | Check for updates, sync any pending changes |
| **App opened offline** | Load from local SQLite, queue any changes |
| **Data edited online** | Save locally + sync to cloud immediately |
| **Data edited offline** | Save locally, queue for sync when online |
| **Connection restored** | Auto-sync queued changes, pull remote updates |
| **Conflict detected** | Most recent timestamp wins, log for review |

### 6.4 Photo Compression

```
┌────────────────────────────────────────────────────────────────┐
│                   PHOTO STORAGE RULES                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  CAPTURE:                                                      │
│  • Original photo captured at device resolution                │
│  • Immediately compressed for offline storage                  │
│  • Original uploaded to cloud (full quality backup)            │
│                                                                │
│  COMPRESSION SPECS:                                            │
│  • Max file size: 500KB per photo                              │
│  • Max dimensions: 1200x1200 pixels                            │
│  • Format: JPEG at 80% quality                                 │
│  • Preserve EXIF orientation                                   │
│                                                                │
│  STORAGE BUDGET:                                               │
│  • Max 10 emergency photos (5MB)                               │
│  • Procedures use illustrations, not photos                    │
│  • Contact photos not stored offline                           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 6.5 Offline Indicators

```
┌─────────────────────────────────────────────────────────────────┐
│  💧 Water Shutoff                                    ✓ Offline  │
├─────────────────────────────────────────────────────────────────┤

   ✓ Offline = Data available without internet
   ⟳ Syncing = Update in progress  
   ⚠️ Pending = Changes waiting to sync
   📵 Unavailable = Data not yet cached (rare)
```

---

## 7. Emergency Mode UI

### 7.1 Design Principles

When someone accesses the Emergency Hub, they may be:
- Panicked and stressed
- In a dark basement
- Dealing with water/smoke
- Holding a flashlight
- Trying to give instructions to someone else

**UI must be:**
- High contrast for readability
- Large tap targets
- Minimal scrolling for critical info
- One-tap calling
- Readable in low light

### 7.2 Color System

| Element | Normal Mode | Emergency Mode |
|---------|-------------|----------------|
| Background | White (#FFFFFF) | Near-black (#1A1A1A) |
| Text | Dark gray (#333333) | White (#FFFFFF) |
| Primary action | Blue (#2196F3) | Bright orange (#FF6D00) |
| Danger/warning | Red (#F44336) | Bright red (#FF1744) |
| Success | Green (#4CAF50) | Bright green (#00E676) |
| Icons | Gray (#757575) | White (#FFFFFF) |

### 7.3 Emergency Mode Toggle

```
┌─────────────────────────────────────────────────────────────────┐
│  ● EMERGENCY MODE                                    [Turn Off] │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  High-contrast mode for emergencies.                            │
│  Larger text. Easier to read in low light.                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │     [  💧 WATER  ]     [  🔥 GAS  ]     [  ⚡ POWER  ]  │    │
│  │                                                         │    │
│  │                    [  🚨 CALL 911  ]                    │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.4 Typography in Emergency Mode

| Element | Normal | Emergency Mode |
|---------|--------|----------------|
| Headers | 20pt | 28pt Bold |
| Body text | 16pt | 20pt |
| Button text | 16pt | 22pt Bold |
| Instructions | 14pt | 18pt |
| Minimum tap target | 44pt | 56pt |

### 7.5 Auto-Activation

Emergency mode can auto-activate when:
- User taps emergency shortcut from home screen widget
- User opens app via "Emergency" notification
- User explicitly enables in settings

---

## 8. User Flows

### 8.1 Initial Setup Flow

```
┌────────────────────────────────────────────────────────────────┐
│                  EMERGENCY HUB SETUP                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  STEP 1: Welcome                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │  🚨 Set Up Your Emergency Hub                           │   │
│  │                                                         │   │
│  │  In an emergency, you'll have instant access to:        │   │
│  │  • Utility shutoff locations                            │   │
│  │  • Emergency contacts                                   │   │
│  │  • Insurance information                                │   │
│  │                                                         │   │
│  │  Even without internet.                                 │   │
│  │                                                         │   │
│  │  Takes about 10 minutes. Grab your phone and walk       │   │
│  │  around your home to photograph shutoff locations.      │   │
│  │                                                         │   │
│  │              [Let's Get Started]                        │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 2: Water Shutoff                                         │
│  → Guide user to locate and photograph main water shutoff      │
│  → Capture valve type and turn direction                       │
│                                                                │
│  STEP 3: Gas Shutoff                                           │
│  → Guide to meter location                                     │
│  → Capture photo and tool requirements                         │
│  → Auto-add safety warnings                                    │
│                                                                │
│  STEP 4: Electrical Panel                                      │
│  → Guide to panel location                                     │
│  → Photo of panel (closed and open)                            │
│  → Identify main breaker                                       │
│  → Optional: Circuit directory                                 │
│                                                                │
│  STEP 5: Emergency Contacts                                    │
│  → Prompt to add plumber, electrician, HVAC                    │
│  → Import from phone contacts option                           │
│  → Skip for now option                                         │
│                                                                │
│  STEP 6: Insurance Info                                        │
│  → Add policy number and claims phone                          │
│  → Photo of insurance card option                              │
│  → Skip for now option                                         │
│                                                                │
│  STEP 7: Complete!                                             │
│  → Show completion status                                      │
│  → Prompt for any missing items                                │
│  → Explain offline access                                      │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 8.2 Add Water Shutoff Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Add Water Shutoff                                   [Skip]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  💧 Where is your main water shutoff?                           │
│                                                                 │
│  The main shutoff controls all water to your home.              │
│  Common locations:                                              │
│  • Basement (near water heater or front wall)                   │
│  • Crawlspace (near where water enters)                         │
│  • Utility room or garage                                       │
│  • Exterior (near foundation or at meter)                       │
│                                                                 │
│  LOCATION                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Basement - Northwest corner                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  TAKE A PHOTO                                                   │
│  Show the shutoff valve and surrounding area so anyone          │
│  could find it.                                                 │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [📷 Take Photo]                      │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│                          [Continue →]                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.3 Add Water Shutoff - Valve Details

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Water Shutoff Details                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [CAPTURED PHOTO]                     │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│  [Retake Photo]                                                 │
│                                                                 │
│  VALVE TYPE                                                     │
│  What kind of valve do you see?                                 │
│                                                                 │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │  [BALL VALVE]  │  │  [GATE VALVE]  │  │    [OTHER]     │     │
│  │    Lever       │  │   Round wheel  │  │                │     │
│  │  ○ Selected    │  │   ○            │  │   ○            │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
│                                                                 │
│  TURN DIRECTION                                                 │
│  Which way to turn OFF?                                         │
│                                                                 │
│  ┌────────────────────────┐  ┌────────────────────────┐         │
│  │  ↻ Clockwise           │  │  ↺ Counter-clockwise   │         │
│  │    ● Selected          │  │    ○                   │         │
│  └────────────────────────┘  └────────────────────────┘         │
│                                                                 │
│  TOOLS NEEDED                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ☐ None (hand-turn)                                     │    │
│  │  ☐ Adjustable wrench                                    │    │
│  │  ☐ Shutoff key/curb key                                 │    │
│  │  ☐ Other: ___________                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ADDITIONAL NOTES (Optional)                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│                          [Save →]                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.4 Emergency Access Flow

```
┌────────────────────────────────────────────────────────────────┐
│              EMERGENCY ACCESS FLOW                             │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  USER HAS EMERGENCY → Opens app or widget                      │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🚨 EMERGENCY HUB                                       │   │
│  │                                                         │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                  │   │
│  │  │   💧    │  │   🔥    │  │   ⚡    │                  │   │
│  │  │  WATER  │  │   GAS   │  │  POWER  │                  │   │
│  │  └─────────┘  └─────────┘  └─────────┘                  │   │
│  │                                                         │   │
│  │  [📞 Emergency Contacts]                                │   │
│  │  [🛡️ Insurance Info]                                   │   │
│  │  [📋 Emergency Procedures]                              │   │
│  │                                                         │   │
│  │                [🚨 Call 911]                            │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  USER TAPS "WATER" →                                           │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  💧 SHUT OFF WATER                                      │   │
│  │                                                         │   │
│  │  [PHOTO OF SHUTOFF LOCATION]                            │   │
│  │                                                         │   │
│  │  Location: Basement, NW corner                          │   │
│  │  Valve: Ball valve (lever)                              │   │
│  │  Turn: 90° clockwise to close                           │   │
│  │  Tools: None needed                                     │   │
│  │                                                         │   │
│  │  [See Full Instructions]                                │   │
│  │                                                         │   │
│  │  ────────────────────────────────────                   │   │
│  │                                                         │   │
│  │  [📞 Call Plumber: ABC Plumbing]                        │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  Critical info visible in <5 seconds, one screen.              │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 9. UI/UX Specifications

### 9.1 Emergency Hub Home Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  Emergency Hub                                 ● Emergency Mode │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  📵 Available Offline                    Last sync: Now │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  UTILITY SHUTOFFS                                               │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │       💧         │  │       🔥         │  │      ⚡      │   │
│  │     WATER        │  │      GAS         │  │    POWER     │   │
│  │    ✓ Ready       │  │    ✓ Ready       │  │   ✓ Ready    │   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
│                                                                 │
│  QUICK CONTACTS                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐        │    │
│  │  │   💧   │  │   ⚡   │  │   🌡️   │  │   🛡️   │        │    │
│  │  │Plumber │  │Electric│  │  HVAC  │  │Insuranc│        │    │
│  │  │  CALL  │  │  CALL  │  │  CALL  │  │  CALL  │        │    │
│  │  └────────┘  └────────┘  └────────┘  └────────┘        │    │
│  └─────────────────────────────────────────────────────────┘    │
│  [View All Contacts →]                                          │
│                                                                 │
│  INSURANCE                                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  🛡️ State Farm                                          │    │
│  │     Policy: HO-1234567-89                               │    │
│  │     [📞 Claims: 1-800-732-5246]        [View Details →] │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  EMERGENCY PROCEDURES                                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  What's your emergency?                                 │    │
│  │  [Flooding] [Fire] [Gas Leak] [Power Out] [More...]     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                       [🚨 Call 911]                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 Setup Completion Status

```
┌─────────────────────────────────────────────────────────────────┐
│  Emergency Hub Setup                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ████████████████████████░░░░░░  75% Complete                   │
│                                                                 │
│  UTILITY SHUTOFFS                                               │
│  ├── ✅ Water Shutoff                          Documented       │
│  ├── ✅ Gas Shutoff                            Documented       │
│  └── ✅ Electrical Panel                       Documented       │
│                                                                 │
│  EMERGENCY CONTACTS                                             │
│  ├── ✅ Plumber                                Added            │
│  ├── ⚠️ Electrician                            Missing          │
│  ├── ⚠️ HVAC                                   Missing          │
│  └── ✅ Insurance Agent                        Added            │
│                                                                 │
│  INSURANCE                                                      │
│  └── ✅ Homeowners Policy                      Complete         │
│                                                                 │
│  [Complete Setup →]                                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 9.3 Widget Design (iOS/Android)

```
┌─────────────────────────────────────────────────────────────────┐
│  HOMETRACK EMERGENCY WIDGET (4x2)                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  🚨 EMERGENCY HUB                                       │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │    │
│  │  │   💧    │  │   🔥    │  │   ⚡    │  │   📞    │    │    │
│  │  │  Water  │  │   Gas   │  │  Power  │  │Contacts │    │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Tapping any button opens Emergency Hub directly to that        │
│  section, in Emergency Mode.                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 9.4 Color Coding

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Water | Blue | #2196F3 | Water shutoff, plumber |
| Gas | Orange | #FF9800 | Gas shutoff, warnings |
| Electric | Yellow | #FFC107 | Electrical panel, electrician |
| Emergency | Red | #F44336 | 911, critical warnings |
| Insurance | Purple | #9C27B0 | Insurance section |
| Success/Ready | Green | #4CAF50 | Documented/complete |
| Warning/Missing | Amber | #FFA000 | Incomplete items |

---

## 10. Integration Points

### 10.1 Home Profile Integration

```
┌────────────────────────────────────────────────────────────────┐
│            EMERGENCY HUB ←→ HOME PROFILE                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  SYSTEM LOCATIONS:                                             │
│  • Water heater location → Available in emergency hub          │
│  • HVAC location → Available for troubleshooting               │
│  • Sump pump location → Available in flooding procedure        │
│                                                                │
│  AUTO-PROMPTS:                                                 │
│  • User adds "Gas Furnace" → Prompt to document gas shutoff    │
│  • User adds "Water Heater" → Prompt to document water shutoff │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 10.2 Maintenance Calendar Integration

```
┌────────────────────────────────────────────────────────────────┐
│         EMERGENCY HUB ←→ MAINTENANCE CALENDAR                  │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  CONTRACTOR SHARING:                                           │
│  • Contractor completes maintenance task                       │
│  • Prompt: "Add ABC Plumbing to Emergency Contacts?"           │
│  • Contact added with service history                          │
│                                                                │
│  SERVICE HISTORY:                                              │
│  • Emergency contact card shows past service                   │
│  • "Last service: Jan 2024 - Water heater repair"              │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 10.3 Document Vault Integration

```
┌────────────────────────────────────────────────────────────────┐
│            EMERGENCY HUB ←→ DOCUMENT VAULT                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  INSURANCE DOCUMENTS:                                          │
│  • Link insurance policy PDF to insurance card                 │
│  • Quick view from Emergency Hub (if online)                   │
│                                                                │
│  UTILITY DOCUMENTS:                                            │
│  • Link utility account docs                                   │
│  • Service agreements for reference                            │
│                                                                │
│  NOTE: Document Vault docs are NOT cached offline              │
│  (too large). Only quick-reference info is offline.            │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 11. Data Model

### 11.1 Emergency Hub Object

```javascript
EmergencyHub {
  id: string
  userId: string
  propertyId: string
  
  // Completion tracking
  setupComplete: boolean
  completionPercentage: number
  lastUpdated: timestamp
  lastSyncedToDevice: timestamp
  
  // Component status
  waterShutoffComplete: boolean
  gasShutoffComplete: boolean
  electricalPanelComplete: boolean
  contactsMinimum: boolean (3+ contacts)
  insuranceComplete: boolean
}
```

### 11.2 Utility Shutoff Object

```javascript
UtilityShutoff {
  id: string
  propertyId: string
  utilityType: 'water' | 'gas' | 'electrical' | 'other'
  
  // Location
  locationDescription: string
  locationPhoto: {
    localPath: string (offline)
    cloudUrl: string
    thumbnailPath: string (offline)
  }
  detailPhoto: {
    localPath: string (offline)
    cloudUrl: string
    thumbnailPath: string (offline)
  } | null
  
  // Water-specific
  valveType: 'ball' | 'gate' | 'other' | null
  turnDirection: 'clockwise' | 'counterclockwise' | null
  
  // Gas-specific
  toolRequired: string | null
  gasCompanyPhone: string | null
  
  // Electrical-specific
  mainBreakerLocation: string | null
  mainBreakerAmperage: number | null
  circuitDirectory: [{
    circuitNumber: number
    amperage: number
    description: string
  }] | null
  
  // Common
  toolsRequired: [string]
  specialInstructions: string | null
  
  // Audit
  createdAt: timestamp
  updatedAt: timestamp
  offlineCachedAt: timestamp
}
```

### 11.3 Emergency Contact Object

```javascript
EmergencyContact {
  id: string
  userId: string
  propertyId: string
  
  // Identity
  name: string
  companyName: string | null
  category: ContactCategory
  
  // Contact info
  phonePrimary: string
  phoneSecondary: string | null
  email: string | null
  website: string | null
  
  // Availability
  availableHours: string | null
  is24x7: boolean
  
  // User data
  notes: string | null
  isFavorite: boolean
  
  // Source
  addedFrom: 'manual' | 'maintenance_calendar' | 'import'
  linkedContractorId: string | null (from Maintenance Calendar)
  
  // Audit
  createdAt: timestamp
  updatedAt: timestamp
}

ContactCategory = [
  'emergency_services',
  'plumber',
  'electrician',
  'hvac',
  'general_contractor',
  'handyman',
  'locksmith',
  'appliance_repair',
  'utility_electric',
  'utility_gas',
  'utility_water',
  'insurance_agent',
  'insurance_claims',
  'neighbor',
  'family',
  'landlord',
  'other'
]
```

### 11.4 Insurance Info Object

```javascript
InsuranceInfo {
  id: string
  userId: string
  propertyId: string
  policyType: 'homeowners' | 'renters' | 'condo' | 'flood' | 'earthquake' | 'umbrella' | 'home_warranty'
  
  // Policy details
  insuranceCompany: string
  policyNumber: string
  coverageAmount: number | null
  deductible: number | null
  policyExpiration: date | null
  
  // Contacts
  agentName: string | null
  agentPhone: string | null
  agentEmail: string | null
  claimsPhone: string
  
  // Documents
  linkedPolicyDocumentId: string | null (Document Vault)
  
  // Audit
  createdAt: timestamp
  updatedAt: timestamp
}
```

### 11.5 Offline Cache Schema (SQLite)

```sql
-- Emergency data cached locally for offline access

CREATE TABLE shutoffs (
  id TEXT PRIMARY KEY,
  property_id TEXT,
  utility_type TEXT,
  location_description TEXT,
  valve_type TEXT,
  turn_direction TEXT,
  tools_required TEXT,  -- JSON array
  special_instructions TEXT,
  gas_company_phone TEXT,
  main_breaker_location TEXT,
  main_breaker_amperage INTEGER,
  circuit_directory TEXT,  -- JSON array
  cached_at INTEGER
);

CREATE TABLE shutoff_photos (
  id TEXT PRIMARY KEY,
  shutoff_id TEXT,
  photo_type TEXT,  -- 'location' | 'detail'
  local_path TEXT,
  cached_at INTEGER,
  FOREIGN KEY (shutoff_id) REFERENCES shutoffs(id)
);

CREATE TABLE contacts (
  id TEXT PRIMARY KEY,
  property_id TEXT,
  name TEXT,
  company_name TEXT,
  category TEXT,
  phone_primary TEXT,
  phone_secondary TEXT,
  available_hours TEXT,
  is_24x7 INTEGER,
  is_favorite INTEGER,
  notes TEXT,
  cached_at INTEGER
);

CREATE TABLE insurance (
  id TEXT PRIMARY KEY,
  property_id TEXT,
  policy_type TEXT,
  insurance_company TEXT,
  policy_number TEXT,
  coverage_amount REAL,
  deductible REAL,
  agent_name TEXT,
  agent_phone TEXT,
  claims_phone TEXT,
  policy_expiration INTEGER,
  cached_at INTEGER
);

CREATE TABLE sync_status (
  id TEXT PRIMARY KEY,
  last_sync INTEGER,
  pending_changes TEXT  -- JSON array of pending updates
);
```

---

## 12. Success Metrics

### 12.1 Setup & Completion

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Emergency Hub started | 80%+ of users | Feature discovery |
| Emergency Hub completed | 70%+ | Full value delivered |
| All shutoffs documented | 60%+ | Core safety value |
| 3+ emergency contacts | 70%+ | Help accessible |
| Insurance info added | 50%+ | Claims readiness |

### 12.2 Offline Reliability

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Offline data sync rate | 100% | Always available |
| Photo cache success | 99%+ | Visual guidance works |
| Offline access errors | <1% | Reliability |
| Sync conflict rate | <0.5% | Data integrity |

### 12.3 Usability (User Testing)

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Time to find shutoff info | <30 seconds | Usability under stress |
| Time to call contact | <10 seconds | One-tap working |
| Task completion (setup) | 90%+ complete each step | Flow clarity |
| Error rate during setup | <5% | UX quality |

### 12.4 Engagement

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Monthly hub views | 1+ per user | Feature awareness |
| Contact calls via app | Track | Feature value |
| Setup completion time | <15 minutes | Not too burdensome |
| Return to complete setup | 60%+ | Users value feature |

### 12.5 Business Impact

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Premium conversion (cites hub) | 15%+ | Monetization driver |
| Retention impact | +20% vs. non-users | Stickiness |
| NPS impact | +10 points | Satisfaction |
| App store reviews mentioning | Track | Marketing value |

---

## 13. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Basic data model and offline architecture.

- [ ] SQLite local database setup
- [ ] Offline-first data layer
- [ ] Basic sync mechanism
- [ ] Emergency Hub shell UI
- [ ] Photo capture and compression

**Exit Criteria:** Can save and retrieve data offline.

### Phase 2: Utility Shutoffs (Weeks 3-4)

**Goal:** Complete shutoff documentation.

- [ ] Water shutoff flow (full)
- [ ] Gas shutoff flow (full, with safety warnings)
- [ ] Electrical panel flow (full, with circuit directory)
- [ ] Photo storage and offline caching
- [ ] Shutoff instructions display

**Exit Criteria:** User can document all three shutoffs with photos.

### Phase 3: Emergency Contacts (Week 5)

**Goal:** Contact management with one-tap calling.

- [ ] Contact CRUD operations
- [ ] Contact categories
- [ ] Favorites / quick access
- [ ] One-tap calling integration
- [ ] Contact import from phone
- [ ] Offline contact access

**Exit Criteria:** User can add contacts and call with one tap.

### Phase 4: Insurance Info (Week 6)

**Goal:** Insurance quick-reference.

- [ ] Insurance info entry
- [ ] Multiple policy support
- [ ] Claims guidance content
- [ ] Document Vault linking
- [ ] Offline insurance display

**Exit Criteria:** User can view insurance info and call claims.

### Phase 5: Emergency Procedures (Week 7)

**Goal:** Step-by-step emergency guides.

- [ ] Procedure content (all scenarios)
- [ ] Procedure UI with steps
- [ ] Integration with shutoffs (deep links)
- [ ] Integration with contacts (call buttons)
- [ ] Offline procedure access

**Exit Criteria:** User can follow procedure for any emergency.

### Phase 6: Emergency Mode UI (Week 8)

**Goal:** High-contrast, stress-tested interface.

- [ ] Emergency mode color scheme
- [ ] Large typography implementation
- [ ] Auto-activation triggers
- [ ] Widget for home screen
- [ ] Accessibility audit

**Exit Criteria:** UI tested for readability in low-light conditions.

### Phase 7: Integration & Polish (Weeks 9-10)

**Goal:** Connect to other features, polish experience.

- [ ] Home Profile integration
- [ ] Maintenance Calendar contractor sync
- [ ] Document Vault linking
- [ ] Setup completion tracking
- [ ] Onboarding flow
- [ ] Performance optimization
- [ ] Bug fixes and polish

**Exit Criteria:** Emergency Hub ready for launch.

---

## Appendix A: Emergency Procedure Content

### Procedure: Burst Pipe / Flooding
1. Shut off water (link to shutoff)
2. Shut off electricity if needed (link to panel)
3. Call plumber (link to contact)
4. Document damage for insurance
5. Begin cleanup
6. File insurance claim

### Procedure: Gas Leak
1. Evacuate immediately
2. Call gas company from outside
3. Do NOT use switches or phones inside
4. Shut off gas at meter if safe
5. Wait for clearance

### Procedure: Electrical Fire
1. Cut power at panel if safe
2. Use Class C extinguisher (never water)
3. Call 911
4. Evacuate if not contained
5. Do not re-enter until cleared

### Procedure: Power Outage
1. Check breaker panel
2. Check if neighbors affected
3. Call electric company
4. Use flashlights, not candles
5. Protect food in refrigerator

*(Additional procedures in full implementation)*

---

## Appendix B: Pre-Populated Content

### Emergency Services (Auto-added)
- 911 - Police/Fire/Ambulance
- Poison Control: 1-800-222-1222
- National Suicide Prevention: 988

### Gas Company Lookup
- Populated based on ZIP code
- User can override

### Safety Warnings (Always shown)
- Gas safety warnings (never use switches)
- Electrical safety (stand on dry surface)
- Fire safety (evacuation routes)

---

## Appendix C: Offline Storage Budget

| Content | Est. Size | Notes |
|---------|-----------|-------|
| Shutoff data (text) | ~5 KB | Minimal |
| Shutoff photos (3) | ~1.5 MB | 500KB each max |
| Panel photo | ~500 KB | Compressed |
| Contacts (20) | ~10 KB | Text only |
| Insurance info | ~5 KB | Text only |
| Procedures | ~50 KB | Pre-loaded content |
| **Total** | **~2.1 MB** | Well under 50MB budget |

---

*End of Emergency Hub Feature Specification*
