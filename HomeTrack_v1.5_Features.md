# HomeTrack v1.5 Features
## Quick Wins — Feature Overview Document

**Target Release: 2-3 Months Post-MVP**  
*Version 1.0 | January 2026*

---

## Executive Summary

Version 1.5 focuses on **high-value, lower-effort features** that extend MVP capabilities and drive Premium conversions. These features leverage existing infrastructure while adding meaningful new value.

| Feature | Primary Value | Effort | Premium? |
|---------|---------------|--------|----------|
| Weather-Triggered Alerts | Prevent damage proactively | Medium | Yes |
| Home Tour Checklist | Capture users earlier in journey | Low | Free |
| Refinance Opportunity Alerts | Financial optimization + lead gen | Medium | Yes |
| Project ROI Calculator | Informed improvement decisions | Low | Yes |
| Mortgage Sync via Plaid | Eliminate manual entry friction | Medium | Yes |

---

## 1. Weather-Triggered Alerts

### Overview

Proactive notifications based on weather forecasts that help homeowners prevent damage before it happens. Transforms HomeTrack from reactive to predictive.

### Value Proposition

| Without Feature | With Feature |
|-----------------|--------------|
| Pipes freeze, costly repairs | "Freeze warning tonight" → drip faucets |
| Storm damages outdoor items | "High winds expected" → secure furniture |
| AC overworks in heat wave | "Heat wave coming" → check filter, adjust thermostat |
| Post-storm damage unnoticed | "Storm passed" → inspect roof prompt |

### Alert Types

| Trigger | Threshold | Alert Title | Action Items |
|---------|-----------|-------------|--------------|
| **Freeze Warning** | Temps ≤32°F | "Freezing temperatures tonight" | Drip faucets, open cabinet doors, disconnect hoses, check pipe insulation |
| **Severe Storm** | NWS severe warning | "Severe storm approaching" | Secure outdoor furniture, check sump pump, charge devices, review emergency hub |
| **Hurricane Watch** | NWS hurricane watch | "Hurricane watch issued" | Full prep checklist, document pre-storm condition, review evacuation plan |
| **Heat Wave** | 3+ days ≥95°F | "Extended heat advisory" | Check AC filter, adjust thermostat, inspect weatherstripping |
| **Post-Storm** | 4-6 hrs after severe | "Storm has passed" | Inspect roof, check for water intrusion, document any damage, check trees |
| **Heavy Rain** | >2" expected | "Heavy rain expected" | Check gutters, test sump pump, inspect basement |
| **High Wind** | Gusts >50mph | "High wind warning" | Secure loose items, check tree limbs, park away from trees |

### User Experience

```
┌─────────────────────────────────────────────────────────────────┐
│  🌡️ WEATHER ALERT                                    3:42 PM    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ❄️ Freeze Warning Tonight                                      │
│                                                                 │
│  Temperatures expected to drop to 28°F between                  │
│  11 PM and 6 AM tomorrow.                                       │
│                                                                 │
│  PROTECT YOUR HOME:                                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ☐ Drip faucets (kitchen, bathrooms)                    │    │
│  │  ☐ Open cabinet doors under sinks                       │    │
│  │  ☐ Disconnect and drain outdoor hoses                   │    │
│  │  ☐ Check pipe insulation in garage/crawlspace           │    │
│  │  ☐ Know your water shutoff location                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  [View Water Shutoff]              [Dismiss]                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Technical Approach

| Component | Solution |
|-----------|----------|
| Weather Data | NOAA National Weather Service API (free, reliable) |
| Polling Frequency | Every 30 minutes |
| Location | Based on property ZIP code |
| Alert Delivery | Push notification + in-app |
| Climate Awareness | Adjust thresholds by climate zone (freeze alerts not needed in Zone 1) |

### Integration Points

- **Emergency Hub**: Link to shutoff locations in freeze/storm alerts
- **Maintenance Calendar**: Create follow-up tasks (e.g., "Inspect roof after storm")
- **Home Profile**: Climate zone determines which alerts are relevant

### Success Metrics

| Metric | Target |
|--------|--------|
| Alert open rate | 60%+ |
| Checklist completion | 40%+ items checked |
| Feature cited in Premium conversion | 15%+ |
| "Helped prevent damage" survey | 25%+ |

---

## 2. Home Tour Checklist

### Overview

Interactive checklist for homebuyers touring properties. Captures users at the **beginning** of their homeownership journey, before they even close on a home.

### Value Proposition

| Problem | Solution |
|---------|----------|
| Forget what you saw after 5 houses | Structured notes + photos per property |
| Miss red flags during tour | Guided inspection checklist |
| Can't remember system ages | Prompts to ask about HVAC, water heater, roof |
| Hard to compare properties | Standardized checklist across tours |

### Checklist Structure

#### Exterior Inspection
| Item | What to Check | Red Flags |
|------|---------------|-----------|
| Roof | Condition, age, missing shingles | Sagging, multiple layers, >20 years |
| Gutters | Condition, drainage | Pulling away, overflowing stains |
| Siding | Cracks, rot, paint condition | Wood rot, gaps, peeling |
| Foundation | Cracks, settling | Horizontal cracks, stair-step cracks |
| Drainage | Grading, water flow direction | Water pooling near foundation |
| Driveway/Walks | Cracks, heaving | Major cracks, trip hazards |
| Landscaping | Trees near house, overgrowth | Trees touching roof, root issues |

#### Interior Inspection
| Item | What to Check | Red Flags |
|------|---------------|-----------|
| Ceilings | Water stains, cracks | Brown stains, sagging |
| Walls | Cracks, fresh paint (hiding issues?) | Diagonal cracks, bulging |
| Floors | Level, squeaks, condition | Significant slope, soft spots |
| Windows | Operation, seals, condensation | Foggy double-pane, won't open |
| Doors | Operation, gaps | Won't close, large gaps |
| Electrical | Outlet condition, panel type | Two-prong only, Federal Pacific panel |
| Plumbing | Water pressure, drain speed | Low pressure, slow drains |

#### Systems Check
| System | Questions to Ask | Capture |
|--------|------------------|---------|
| HVAC | Age? Last serviced? | Brand, model, install year |
| Water Heater | Age? Tank or tankless? | Brand, capacity, install year |
| Roof | Age? Material? Warranty? | Install year, material type |
| Electrical | Panel amperage? Updated? | 100A/200A, year updated |
| Plumbing | Pipe material? Issues? | Copper/PEX/galvanized |

### User Experience

```
┌─────────────────────────────────────────────────────────────────┐
│  🏠 HOME TOUR: 123 Oak Street                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PROGRESS: ████████████░░░░░░░░ 60%                             │
│                                                                 │
│  EXTERIOR                                              ✓ Done   │
│  INTERIOR                                              In Progress │
│  SYSTEMS                                               Not Started │
│  OVERALL IMPRESSION                                    Not Started │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  INTERIOR INSPECTION                                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ☑ Ceilings - No water stains                           │    │
│  │  ☑ Walls - Minor crack in bedroom 2                     │    │
│  │      📷 1 photo attached                                │    │
│  │  ☐ Floors                                               │    │
│  │  ☐ Windows                                              │    │
│  │  ☐ Doors                                                │    │
│  │  ☐ Electrical outlets                                   │    │
│  │  ☐ Plumbing (run water, check pressure)                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  [📷 Add Photo]                           [Continue →]          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Feature Details

| Capability | Description |
|------------|-------------|
| Multiple Properties | Save checklists for multiple homes being considered |
| Photo Capture | Attach photos to specific checklist items |
| Notes | Free-form notes per item and overall |
| Red Flag Indicators | Visual warnings for concerning items |
| Comparison View | Side-by-side comparison of toured properties |
| Export to PDF | Share with inspector, agent, or family |
| Import to HomeTrack | After purchase, convert to Home Profile |

### Why Free?

- **Top of funnel**: Captures users before purchase
- **Habit formation**: Users already using app when they close
- **Conversion path**: Natural upgrade to Premium for ongoing tracking
- **Referral driver**: Share with friends also house hunting

### Success Metrics

| Metric | Target |
|--------|--------|
| Checklists started | 10%+ of new signups |
| Checklists completed | 60%+ of started |
| Properties compared | 2+ per user |
| Conversion to Premium post-purchase | 30%+ |
| PDF exports | 25%+ |

---

## 3. Refinance Opportunity Alerts

### Overview

Intelligent notifications when market conditions or user equity suggest refinancing may benefit the homeowner. High-value lead generation opportunity.

### Value Proposition

| Scenario | Alert | Potential Benefit |
|----------|-------|-------------------|
| Rates drop significantly | "Rates are 1% below yours" | Save $200+/month |
| Equity reaches 20% | "You may eliminate PMI" | Save $100-300/month |
| Equity reaches 30%+ | "HELOC options available" | Access $XX,XXX for improvements |
| ARM adjustment approaching | "Your rate adjusts in 6 months" | Lock in fixed rate |

### Alert Types

#### Rate Drop Alert
```
┌─────────────────────────────────────────────────────────────────┐
│  📉 REFINANCE OPPORTUNITY                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Current mortgage rates have dropped!                           │
│                                                                 │
│  YOUR RATE:        6.75%                                        │
│  CURRENT RATES:    5.625% (30-yr fixed avg)                     │
│  DIFFERENCE:       1.125%                                       │
│                                                                 │
│  POTENTIAL SAVINGS                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Monthly:     ~$185/month                               │    │
│  │  Annual:      ~$2,220/year                              │    │
│  │  Over loan:   ~$66,600 (30 years)                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ⚠️ Estimates based on current balance. Actual savings          │
│     depend on loan terms, closing costs, and qualification.     │
│                                                                 │
│  [Explore Refinance Options]              [Dismiss]             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### PMI Removal Alert
```
┌─────────────────────────────────────────────────────────────────┐
│  🎉 PMI REMOVAL ELIGIBLE                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Congratulations! You've reached 20% equity.                    │
│                                                                 │
│  HOME VALUE:       $425,000                                     │
│  MORTGAGE:         $340,000                                     │
│  EQUITY:           $85,000 (20%)                                │
│  LTV RATIO:        80%                                          │
│                                                                 │
│  You may be able to remove Private Mortgage Insurance (PMI)     │
│  and save $125-200/month.                                       │
│                                                                 │
│  NEXT STEPS:                                                    │
│  1. Contact your lender to request PMI removal                  │
│  2. You may need a new appraisal ($300-500)                     │
│  3. Lender reviews and removes PMI if approved                  │
│                                                                 │
│  [Learn More About PMI Removal]           [Dismiss]             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### HELOC Opportunity Alert
```
┌─────────────────────────────────────────────────────────────────┐
│  💰 HOME EQUITY OPTIONS                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  With 35% equity, you have options!                             │
│                                                                 │
│  HOME VALUE:       $425,000                                     │
│  MORTGAGE:         $276,000                                     │
│  EQUITY:           $149,000 (35%)                               │
│                                                                 │
│  POTENTIAL ACCESS (keeping 20% equity):                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Available for HELOC/Loan:  ~$64,000                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Common uses:                                                   │
│  • Home improvements (often tax-deductible interest)            │
│  • Debt consolidation                                           │
│  • Emergency fund                                               │
│                                                                 │
│  [Explore HELOC Options]                  [Dismiss]             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Alert Triggers

| Alert Type | Trigger Condition | Frequency |
|------------|-------------------|-----------|
| Rate Drop | Current rates >0.5% below user's rate | Check weekly, alert max 1x/quarter |
| PMI Removal | Equity ≥20% (LTV ≤80%) | One-time when threshold crossed |
| HELOC Eligible | Equity ≥30% | One-time when threshold crossed |
| ARM Adjustment | ARM adjusts within 6 months | 6 months, 3 months, 1 month before |

### Technical Approach

| Component | Solution |
|-----------|----------|
| Rate Data | Freddie Mac PMMS (free, weekly) or partner API |
| User's Rate | From mortgage entry (manual or Plaid) |
| Equity Calculation | From Home Value + Mortgage balance |
| Savings Calculator | Standard amortization formulas |

### Monetization: Lead Generation

| Lead Type | Estimated Value | Partner Model |
|-----------|-----------------|---------------|
| Refinance Lead | $45-250 per qualified lead | Affiliate network or direct lender partnerships |
| HELOC Lead | $30-100 per lead | Bank/credit union partnerships |

**User Experience**: "Explore Options" button leads to:
1. Educational content (what is refinancing, HELOC, etc.)
2. Optional: Connect with partner lenders (with clear disclosure)
3. User always in control — no auto-sharing of info

### Success Metrics

| Metric | Target |
|--------|--------|
| Alert open rate | 50%+ |
| "Explore Options" click rate | 20%+ |
| Lead conversion (if implemented) | 5%+ |
| User-reported savings | Track anecdotally |

---

## 4. Project ROI Calculator

### Overview

Help homeowners make informed decisions about improvements by showing expected return on investment based on industry data (Remodeling Magazine's Cost vs. Value Report).

### Value Proposition

| Question | Calculator Answers |
|----------|-------------------|
| "Is this project worth it?" | Shows % of cost typically recouped at sale |
| "Which project should I prioritize?" | Compare ROI across multiple projects |
| "How much will this add to my home's value?" | Estimated value added |
| "Should I go high-end or mid-range?" | ROI comparison by project tier |

### Project Categories

| Category | Example Projects |
|----------|------------------|
| **Exterior** | Siding, entry door, garage door, roofing, windows |
| **Kitchen** | Minor remodel, major remodel, upscale remodel |
| **Bathroom** | Bath remodel, bath addition, universal design bath |
| **Living Space** | Basement finish, attic conversion, room addition |
| **Outdoor** | Deck addition, patio, landscaping |
| **Systems** | HVAC, insulation, electrical upgrade |

### Sample ROI Data (2024 Cost vs. Value)

| Project | Avg Cost | Avg Resale Value | ROI |
|---------|----------|------------------|-----|
| Garage Door Replacement | $4,302 | $4,418 | 102.7% |
| Manufactured Stone Veneer | $10,925 | $11,177 | 102.3% |
| Entry Door Replacement (Steel) | $2,214 | $2,235 | 100.9% |
| Minor Kitchen Remodel | $26,790 | $22,963 | 85.7% |
| Siding Replacement (Vinyl) | $16,348 | $12,694 | 77.6% |
| Bath Remodel (Midrange) | $24,606 | $17,525 | 71.2% |
| Major Kitchen Remodel (Midrange) | $77,939 | $45,519 | 58.4% |
| Primary Suite Addition | $156,741 | $85,722 | 54.7% |

### User Experience

```
┌─────────────────────────────────────────────────────────────────┐
│  📊 PROJECT ROI CALCULATOR                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SELECT A PROJECT                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Kitchen Remodel - Minor (Midrange)                 ▼   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  YOUR ESTIMATED COST                                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ 25,000                                               │    │
│  └─────────────────────────────────────────────────────────┘    │
│  National avg: $26,790                                          │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  PROJECTED RETURN                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │  ROI:                    85.7%                          │    │
│  │  Estimated Value Added:  $21,425                        │    │
│  │  Net Cost:               $3,575                         │    │
│  │                                                         │    │
│  │  ████████████████████████████████░░░░░░░░░░             │    │
│  │  ◄─── Value Recouped ───►│◄── Net Cost ──►             │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  📍 Regional adjustment: West Coast (+5.2%)                     │
│     Adjusted ROI: ~90.9%                                        │
│                                                                 │
│  [Compare Another Project]        [Save to My Projects]         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Comparison View

```
┌─────────────────────────────────────────────────────────────────┐
│  📊 COMPARE PROJECTS                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Sorted by: ROI (highest first)                                 │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  1. Garage Door Replacement                             │    │
│  │     Cost: $4,000    ROI: 102.7%    Value Add: $4,108    │    │
│  │     █████████████████████████████████████████████ 103%  │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  2. Entry Door (Steel)                                  │    │
│  │     Cost: $2,200    ROI: 100.9%    Value Add: $2,220    │    │
│  │     █████████████████████████████████████████████ 101%  │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  3. Minor Kitchen Remodel                               │    │
│  │     Cost: $25,000   ROI: 85.7%     Value Add: $21,425   │    │
│  │     ████████████████████████████████████░░░░░░░░░  86%  │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  4. Bathroom Remodel                                    │    │
│  │     Cost: $22,000   ROI: 71.2%     Value Add: $15,664   │    │
│  │     ██████████████████████████████░░░░░░░░░░░░░░░  71%  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  💡 Tip: High-ROI projects like garage doors and entry doors    │
│     often make sense to do before selling.                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Source

- **Primary**: Remodeling Magazine's Cost vs. Value Report (annual, free to reference)
- **Regional Adjustment**: Report includes 150 US markets with regional factors
- **Update Frequency**: Annually when new report releases

### Success Metrics

| Metric | Target |
|--------|--------|
| Calculator uses | 30%+ of Premium users |
| Projects compared | 2+ per session |
| "Save to Projects" | 20%+ |
| Cited in Premium conversion | 10%+ |

---

## 5. Mortgage Sync via Plaid

### Overview

Automatic mortgage balance and details sync via Plaid Liabilities API, eliminating manual entry and ensuring equity calculations are always accurate.

### Value Proposition

| Manual Entry | Plaid Sync |
|--------------|------------|
| User must update monthly | Auto-updates automatically |
| Often forgotten/stale | Always current |
| Only balance captured | Full loan details |
| Error-prone | Bank-accurate data |

### Data Retrieved

| Field | Availability | Notes |
|-------|--------------|-------|
| Current Balance | ✅ Always | Primary value |
| Original Loan Amount | ✅ Common | For progress tracking |
| Interest Rate | ✅ Common | For refinance alerts |
| Monthly Payment | ✅ Common | P&I amount |
| Next Payment Due | ✅ Common | For reminders |
| Escrow Balance | ⚠️ Sometimes | If available |
| PMI Amount | ⚠️ Sometimes | If available |
| Loan Origination Date | ⚠️ Sometimes | If available |
| Lender Name | ✅ Always | Account name |
| Loan Type | ⚠️ Sometimes | Fixed, ARM, etc. |

### Connection Flow

```
┌────────────────────────────────────────────────────────────────┐
│                   PLAID CONNECTION FLOW                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  STEP 1: Prompt                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🔗 Connect Your Mortgage                               │   │
│  │                                                         │   │
│  │  Automatically sync your mortgage balance for           │   │
│  │  accurate equity tracking. No more manual updates.      │   │
│  │                                                         │   │
│  │  🔒 Bank-level security via Plaid                       │   │
│  │  👁️ Read-only access (we can't move money)              │   │
│  │  🔄 Updates automatically                               │   │
│  │                                                         │   │
│  │  [Connect Mortgage Account]                             │   │
│  │                                                         │   │
│  │  [Continue with Manual Entry]                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 2: Plaid Link                                            │
│  • Standard Plaid Link modal                                   │
│  • User selects their lender                                   │
│  • User authenticates with lender                              │
│  • User authorizes read-only access                            │
│                                                                │
│  STEP 3: Confirmation                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ✓ Mortgage Connected!                                  │   │
│  │                                                         │   │
│  │  Wells Fargo Home Mortgage                              │   │
│  │                                                         │   │
│  │  Current Balance:    $284,532                           │   │
│  │  Interest Rate:      6.25%                              │   │
│  │  Monthly Payment:    $1,847                             │   │
│  │  Next Due:           February 1, 2026                   │   │
│  │                                                         │   │
│  │  We'll keep this updated automatically.                 │   │
│  │                                                         │   │
│  │  [Done]                                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Sync Behavior

| Scenario | Behavior |
|----------|----------|
| Initial connect | Fetch all available data immediately |
| Ongoing sync | Check daily, update if balance changed |
| User views Home Value | Trigger sync if >24 hours stale |
| Balance change detected | Update equity calculation, log to history |
| Connection expires | Prompt user to reconnect |
| Lender not supported | Fall back to manual entry |

### Technical Details

| Component | Specification |
|-----------|---------------|
| API | Plaid Liabilities API |
| Products | `liabilities` |
| Account Types | `mortgage` |
| Webhook Events | `LIABILITIES_DEFAULT_UPDATE` |
| Cost | Per-connection pricing (varies by volume) |

### Error Handling

| Error | User Experience |
|-------|-----------------|
| Auth expired | "Your mortgage connection needs to be refreshed" → Reconnect flow |
| Lender unavailable | "We couldn't reach [Lender]. Showing last known balance from [date]" |
| Account not found | "We couldn't find a mortgage account. Is this the right login?" |
| Lender not supported | "Unfortunately, [Lender] isn't supported yet. You can enter your info manually." |

### Privacy & Security

| Concern | How We Address |
|---------|----------------|
| Data access | Read-only — we cannot move money or make changes |
| Data storage | Only store balance/loan info, not full account access |
| Third-party sharing | Never share with third parties without explicit consent |
| Disconnection | User can disconnect anytime, we delete stored tokens |

### Success Metrics

| Metric | Target |
|--------|--------|
| Plaid connection rate | 40%+ of users with mortgage |
| Manual entry reduction | 60%+ choose Plaid over manual |
| Data freshness | 95%+ accounts synced within 7 days |
| Reconnection success | 80%+ complete reconnection when prompted |

---

## Implementation Priority

### Recommended Build Order

| Order | Feature | Rationale |
|-------|---------|-----------|
| 1 | **Plaid Mortgage Sync** | Enables accurate data for other features |
| 2 | **Refinance Alerts** | Leverages Plaid data, high user value |
| 3 | **Weather Alerts** | Standalone, high engagement |
| 4 | **Project ROI Calculator** | Standalone, quick build |
| 5 | **Home Tour Checklist** | Top of funnel, can launch anytime |

### Estimated Effort

| Feature | Effort | Dependencies |
|---------|--------|--------------|
| Plaid Mortgage Sync | 3-4 weeks | Plaid account, legal review |
| Refinance Alerts | 2-3 weeks | Plaid (for rate), Home Value (for equity) |
| Weather Alerts | 2-3 weeks | Home Profile (location), Emergency Hub (links) |
| Project ROI Calculator | 1-2 weeks | None (standalone) |
| Home Tour Checklist | 2-3 weeks | None (standalone) |

### Total v1.5 Timeline: 8-12 weeks

---

## Appendix: Data Sources

| Feature | Data Source | Cost | Notes |
|---------|-------------|------|-------|
| Weather Alerts | NOAA/NWS API | Free | Reliable, comprehensive |
| Mortgage Sync | Plaid Liabilities | Per-connection | Industry standard |
| Interest Rates | Freddie Mac PMMS | Free | Weekly updates |
| Project ROI | Cost vs. Value Report | Free | Annual publication |
| Home Value | ATTOM (from MVP) | ~$500/mo | Already integrated |

---

## Appendix: Premium Feature Matrix

| Feature | Free | Premium |
|---------|------|---------|
| Home Tour Checklist | ✅ | ✅ |
| Weather Alerts | ❌ | ✅ |
| Refinance Alerts | ❌ | ✅ |
| PMI/HELOC Alerts | ❌ | ✅ |
| Project ROI Calculator | ❌ | ✅ |
| Plaid Mortgage Sync | ❌ | ✅ |

---

*End of v1.5 Features Overview*
