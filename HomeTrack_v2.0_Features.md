# HomeTrack v2.0 Features
## Major Enhancements — Feature Overview Document

**Target Release: 4-6 Months Post-MVP**  
*Version 1.0 | January 2026*

---

## Executive Summary

Version 2.0 delivers the **"Carfax for Homes"** promise with major features that differentiate HomeTrack from competitors. These features require significant development effort but deliver substantial user value and create network effects.

| Feature | Primary Value | Effort | Premium? |
|---------|---------------|--------|----------|
| Home History Report | Seller value at sale — the core differentiator | High | Yes |
| Account Transfer | Network effects via buyer/seller handoff | Medium | Yes |
| Home Inventory | Insurance documentation + peace of mind | High | Yes |
| Disclosure Checklist | Reduce seller legal risk | Medium | Yes |
| Before/After Gallery | Visual project documentation | Medium | Yes |
| Receipt Scanner | Frictionless expense capture | Medium | Yes |

---

## 1. Home History Report Generator

### Overview

**The flagship "Carfax" feature.** Generate a comprehensive, professional report documenting the home's complete maintenance and improvement history. Sellers can share this with buyers to demonstrate care and justify asking price.

### Value Proposition

| For Sellers | For Buyers |
|-------------|------------|
| Justify asking price with documented care | Know what you're buying |
| Stand out in competitive market | Understand maintenance history |
| Reduce buyer concerns/objections | See recent improvements |
| Faster sale with transparency | Identify potential issues |
| Professional presentation | Verify seller claims |

### Report Contents

#### Section 1: Property Overview
| Field | Source |
|-------|--------|
| Property address | Home Profile |
| Year built | Home Profile |
| Square footage | Home Profile |
| Lot size | Home Profile |
| Bedrooms / Bathrooms | Home Profile |
| Property type | Home Profile |
| Current estimated value | Home Value Tracking |

#### Section 2: System Inventory
| Content | Source |
|---------|--------|
| All major systems with ages | Home Profile |
| Brand and model information | Home Profile |
| Installation/replacement dates | Home Profile |
| Remaining lifespan estimates | Home Profile |
| Warranty status (active/expired) | Document Vault |
| System photos | Home Profile |

#### Section 3: Maintenance Timeline
| Content | Source |
|---------|--------|
| Complete service history | Maintenance Calendar |
| Service dates | Maintenance Calendar |
| Contractor information | Maintenance Calendar |
| Service costs | Maintenance Calendar |
| DIY vs professional | Maintenance Calendar |
| Completion notes | Maintenance Calendar |

#### Section 4: Improvement Documentation
| Content | Source |
|---------|--------|
| Project list with dates | Before/After Gallery |
| Before/after photos | Before/After Gallery |
| Permit information | Document Vault |
| Contractor details | Maintenance Calendar |
| Project costs | Receipt Scanner / Manual |

#### Section 5: Investment Summary
| Content | Calculation |
|---------|-------------|
| Total maintenance spending | Sum of maintenance costs |
| Total improvement spending | Sum of project costs |
| Spending by category | Grouped totals |
| Spending by year | Annual breakdown |
| Average annual investment | Total ÷ years of ownership |

#### Section 6: Document Attachments
| Documents | Source |
|-----------|--------|
| Permits | Document Vault |
| Warranties (active) | Document Vault |
| Inspection reports | Document Vault |
| Contractor invoices | Document Vault |
| System manuals | Document Vault |

### Report Preview

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                                                           │  │
│  │                    🏠 HOME HISTORY REPORT                 │  │
│  │                                                           │  │
│  │                    123 Oak Street                         │  │
│  │                 Anytown, CA 90210                         │  │
│  │                                                           │  │
│  │              Generated: January 16, 2026                  │  │
│  │                                                           │  │
│  │  ─────────────────────────────────────────────────────    │  │
│  │                                                           │  │
│  │  PROPERTY SNAPSHOT                                        │  │
│  │  Built: 1995 | 2,450 sq ft | 4 bed | 2.5 bath            │  │
│  │  Estimated Value: $425,000                                │  │
│  │                                                           │  │
│  │  OWNERSHIP INVESTMENT                                     │  │
│  │  Total invested in maintenance & improvements:            │  │
│  │                    $47,250                                │  │
│  │                                                           │  │
│  │  HIGHLIGHTS                                               │  │
│  │  ✓ HVAC replaced 2023 (under warranty)                   │  │
│  │  ✓ Roof inspected annually, good condition               │  │
│  │  ✓ Kitchen remodeled 2022 ($28,000)                      │  │
│  │  ✓ 47 maintenance tasks completed                        │  │
│  │                                                           │  │
│  │  [Continue to Full Report →]                              │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Output Formats

| Format | Use Case | Features |
|--------|----------|----------|
| **PDF Download** | Email to buyers, print for showings | Professional layout, includes photos |
| **Web Link** | Share digitally, embed in listings | Interactive, always up-to-date |
| **QR Code** | Include in listing materials, yard signs | Links to web version |

### Web Link Options

```
┌─────────────────────────────────────────────────────────────────┐
│  🔗 SHARE YOUR HOME HISTORY REPORT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SHAREABLE LINK                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  hometrack.com/report/abc123xyz                         │    │
│  │                                          [Copy Link]    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  LINK OPTIONS                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ☐ Require email to view (capture buyer leads)          │    │
│  │  ☑ Show estimated value                                 │    │
│  │  ☑ Show maintenance costs                               │    │
│  │  ☐ Show my contact information                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  LINK EXPIRATION                                                │
│  ○ Never expires                                                │
│  ○ 30 days                                                      │
│  ● 90 days                                                      │
│  ○ Custom date: [________]                                      │
│                                                                 │
│  QR CODE                                                        │
│  ┌─────────────┐                                                │
│  │ ▄▄▄▄▄ ▄▄▄▄ │  [Download QR Code]                            │
│  │ █   █ █▄▄█ │  For listing sheets, flyers, yard signs        │
│  │ █▄▄▄█ ▄▄▄▄ │                                                │
│  └─────────────┘                                                │
│                                                                 │
│  [Generate Report]              [Preview Report]                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Generation Flow

```
┌────────────────────────────────────────────────────────────────┐
│              HOME HISTORY REPORT GENERATION                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  STEP 1: Review Data Completeness                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Your report will include:                              │   │
│  │                                                         │   │
│  │  ✓ Property details                        Complete     │   │
│  │  ✓ 8 systems documented                    Complete     │   │
│  │  ✓ 47 maintenance records                  Complete     │   │
│  │  ⚠️ 2 projects missing costs               Add Now →    │   │
│  │  ✓ 12 documents attached                   Complete     │   │
│  │                                                         │   │
│  │  Report Completeness: ████████████░░ 85%                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 2: Customize Report                                      │
│  • Select sections to include/exclude                          │
│  • Choose which costs to display                               │
│  • Add personal message to buyers                              │
│                                                                │
│  STEP 3: Generate & Share                                      │
│  • Generate PDF and/or web link                                │
│  • Set sharing options                                         │
│  • Download QR code                                            │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Success Metrics

| Metric | Target |
|--------|--------|
| Reports generated | 20%+ of long-term users (2+ years) |
| Reports shared | 60%+ of generated reports |
| Buyer views per report | 5+ average |
| "Helped sell home" survey | 40%+ of sellers |
| Premium retention (report users) | +30% vs. non-users |

---

## 2. Account Transfer to New Owner

### Overview

Enable sellers to transfer complete home history to buyers, creating **network effects** and ensuring data continuity across ownership changes. The seller's careful documentation becomes a gift to the buyer—and makes the buyer a HomeTrack user.

### Value Proposition

| For Sellers | For Buyers | For HomeTrack |
|-------------|------------|---------------|
| Complete handoff of home knowledge | Inherit full history | Network effects (viral growth) |
| Trusted contractor recommendations | Know maintenance schedule | New user acquisition at $0 CAC |
| Clean break from property | Skip setup from scratch | Data continuity improves product |
| Demonstrate professionalism | Immediate value | Retention through ownership transition |

### What Transfers

| Content | Transfers | Notes |
|---------|-----------|-------|
| Property details | ✅ | Address, sq ft, year built, etc. |
| System inventory | ✅ | All systems with ages, brands |
| Appliance registry | ✅ | All appliances with details |
| Maintenance history | ✅ | Full task history with costs |
| Emergency Hub data | ✅ | Shutoff locations, photos |
| Document Vault | ⚠️ Optional | Seller chooses which docs |
| Contractor contacts | ⚠️ Optional | Seller chooses to include |
| Home value history | ❌ | Fresh start for new owner |
| Seller's personal info | ❌ | Never transfers |

### Transfer Flow

```
┌────────────────────────────────────────────────────────────────┐
│                    ACCOUNT TRANSFER FLOW                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  SELLER INITIATES                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🏠 Transfer Home to New Owner                          │   │
│  │                                                         │   │
│  │  Congratulations on your sale! Transfer your home's     │   │
│  │  history to the new owner so they can continue          │   │
│  │  caring for it.                                         │   │
│  │                                                         │   │
│  │  WHAT WILL TRANSFER:                                    │   │
│  │  ✓ Property details and photos                          │   │
│  │  ✓ System and appliance registry                        │   │
│  │  ✓ 47 maintenance records                               │   │
│  │  ✓ Emergency shutoff locations                          │   │
│  │                                                         │   │
│  │  OPTIONAL - You choose:                                 │   │
│  │  ☑ Include documents (12 selected)                      │   │
│  │  ☑ Include contractor contacts (5 contacts)             │   │
│  │                                                         │   │
│  │  WILL NOT TRANSFER:                                     │   │
│  │  • Your personal information                            │   │
│  │  • Your account or payment info                         │   │
│  │                                                         │   │
│  │  [Continue →]                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  INVITE NEW OWNER                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Enter the new owner's email address                    │   │
│  │                                                         │   │
│  │  Email: [buyer@email.com________________]               │   │
│  │                                                         │   │
│  │  They'll receive an invitation to claim this home.      │   │
│  │                                                         │   │
│  │  [Send Invitation]                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  BUYER RECEIVES                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  📧 Subject: Your new home's history is ready!          │   │
│  │                                                         │   │
│  │  The previous owner of 123 Oak Street has shared        │   │
│  │  the home's complete history with you, including:       │   │
│  │                                                         │   │
│  │  • System ages and maintenance records                  │   │
│  │  • Emergency shutoff locations                          │   │
│  │  • Trusted contractor contacts                          │   │
│  │  • Important home documents                             │   │
│  │                                                         │   │
│  │  [Claim Your Home →]                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  BUYER CLAIMS                                                  │
│  • Create account (or link existing)                           │
│  • Review transferred data                                     │
│  • Accept transfer                                             │
│  • Property now belongs to buyer's account                     │
│                                                                │
│  SELLER CONFIRMATION                                           │
│  • Notified that transfer is complete                          │
│  • Property removed from seller's account                      │
│  • Seller retains access to export their data (30 days)        │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Transfer States

| State | Seller View | Buyer View |
|-------|-------------|------------|
| Not initiated | Normal access | N/A |
| Invitation sent | "Pending transfer" badge | Email received |
| Buyer claimed | "Transfer complete" | Full access |
| Transfer expired (30 days) | Invitation cancelled | Link expired |

### Edge Cases

| Scenario | Handling |
|----------|----------|
| Buyer already has HomeTrack | Add property to existing account |
| Buyer ignores invitation | Reminder at 7 days, expires at 30 |
| Seller wants to cancel | Can cancel before buyer accepts |
| Buyer rejects transfer | Seller notified, retains property |
| Sale falls through | Seller can cancel transfer |
| Multiple owners (couple) | Both can be invited as household members |

### Success Metrics

| Metric | Target |
|--------|--------|
| Transfers initiated (of sellers) | 30%+ |
| Transfers completed | 70%+ of initiated |
| Buyer conversion to active user | 60%+ |
| Buyer Premium conversion | 25%+ within 6 months |
| Referral program signups | Track transfers as referral source |

---

## 3. Home Inventory with Valuation

### Overview

Room-by-room inventory of possessions with estimated values, primarily for **insurance documentation**. In case of theft, fire, or disaster, users have a complete record to support their claims.

### Value Proposition

| Problem | Solution |
|---------|----------|
| "What did we own?" after disaster | Complete documented inventory |
| Underinsured without knowing it | Total value vs. coverage comparison |
| Claims denied for lack of proof | Photos + receipts for each item |
| Hours recreating inventory | Already documented |
| Forgot about valuable items | Room-by-room prompts |

### Inventory Structure

```
┌────────────────────────────────────────────────────────────────┐
│                    INVENTORY HIERARCHY                         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  HOME                                                          │
│  ├── Living Room                                               │
│  │   ├── Furniture                                             │
│  │   │   ├── Sofa - West Elm ($2,400)                         │
│  │   │   ├── Coffee Table - CB2 ($650)                        │
│  │   │   └── Bookshelf - IKEA ($180)                          │
│  │   ├── Electronics                                           │
│  │   │   ├── 65" Samsung TV ($1,200)                          │
│  │   │   └── Sonos Soundbar ($450)                            │
│  │   └── Decor                                                 │
│  │       ├── Area Rug ($800)                                  │
│  │       └── Artwork - Local Artist ($350)                    │
│  │                                                             │
│  ├── Kitchen                                                   │
│  │   ├── Appliances (small)                                   │
│  │   ├── Cookware                                             │
│  │   └── Dishes & Glassware                                   │
│  │                                                             │
│  ├── Primary Bedroom                                           │
│  ├── Bedroom 2                                                 │
│  ├── Bathroom(s)                                               │
│  ├── Garage                                                    │
│  ├── Outdoor                                                   │
│  └── Storage/Other                                             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Item Entry

| Field | Description | Required |
|-------|-------------|----------|
| **Item Name** | Description of item | Yes |
| **Room** | Location in home | Yes |
| **Category** | Furniture, Electronics, etc. | Yes |
| **Photo(s)** | Visual documentation | Recommended |
| **Brand/Manufacturer** | For identification | Optional |
| **Model Number** | For exact replacement | Optional |
| **Serial Number** | For theft recovery | Optional |
| **Purchase Date** | When acquired | Optional |
| **Purchase Price** | Original cost | Optional |
| **Current Value** | Estimated now (manual or depreciated) | Recommended |
| **Receipt/Proof** | Linked document | Optional |
| **Notes** | Any additional details | Optional |

### Item Entry UI

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Add Item                                        Living Room  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PHOTO                                                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [📷 Add Photo]                       │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ITEM NAME *                                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Sectional Sofa                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  CATEGORY *                                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Furniture                                          ▼   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  BRAND                                                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  West Elm                                               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  MODEL (optional)                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Harmony 3-Piece Sectional                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌──────────────────────┐  ┌──────────────────────┐             │
│  │  PURCHASE DATE       │  │  PURCHASE PRICE      │             │
│  │  March 2023          │  │  $ 3,200             │             │
│  └──────────────────────┘  └──────────────────────┘             │
│                                                                 │
│  CURRENT VALUE                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  $ 2,400                                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│  💡 Tip: Furniture typically depreciates 10-15% per year        │
│                                                                 │
│  RECEIPT / PROOF OF PURCHASE                                    │
│  [📄 Attach Document]  or  [📷 Take Photo of Receipt]           │
│                                                                 │
│                          [Save Item]                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Room Summary View

```
┌─────────────────────────────────────────────────────────────────┐
│  🏠 HOME INVENTORY                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  TOTAL INVENTORY VALUE                                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                      $67,450                            │    │
│  │                    142 items                            │    │
│  │                                                         │    │
│  │  YOUR COVERAGE: $75,000 contents                        │    │
│  │  ✓ Coverage appears adequate                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  BY ROOM                                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Living Room              $12,450      18 items     →   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  Kitchen                  $8,200       24 items     →   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  Primary Bedroom          $9,800       15 items     →   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  Bedroom 2                $4,200       12 items     →   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  Bedroom 3 / Office       $6,500       18 items     →   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  Garage                   $8,300       32 items     →   │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  Other                    $18,000      23 items     →   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  [+ Add Room]                    [📤 Export for Insurance]      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Insurance Export

```
┌─────────────────────────────────────────────────────────────────┐
│  📤 EXPORT INVENTORY                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  FORMAT                                                         │
│  ○ PDF Report (formatted, with photos)                          │
│  ● Spreadsheet (CSV/Excel)                                      │
│  ○ Both                                                         │
│                                                                 │
│  INCLUDE                                                        │
│  ☑ Item photos                                                  │
│  ☑ Receipt images                                               │
│  ☑ Serial numbers                                               │
│  ☑ Purchase dates and prices                                    │
│  ☑ Current estimated values                                     │
│                                                                 │
│  SCOPE                                                          │
│  ● Entire home                                                  │
│  ○ Selected rooms: [________]                                   │
│  ○ High-value items only (>$500)                                │
│                                                                 │
│                       [Generate Export]                         │
│                                                                 │
│  💡 Keep a copy in cloud storage or email to yourself           │
│     so it's accessible even if your phone is lost.              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Quick-Add Features

| Feature | Description |
|---------|-------------|
| **Barcode Scanner** | Scan UPC for auto-fill product info |
| **Receipt Scanner** | Extract vendor, date, amount from receipt |
| **Batch Photo Mode** | Rapid-fire photo capture, tag later |
| **Room Sweep** | Guided walkthrough prompting by category |
| **Value Suggestions** | Depreciation calculator based on age/category |

### Success Metrics

| Metric | Target |
|--------|--------|
| Inventory started | 30%+ of Premium users |
| Items logged | 50+ per active inventory user |
| Rooms documented | 5+ per user |
| Exports generated | 20%+ of inventory users |
| Insurance claim assist | Track via support/surveys |

---

## 4. Disclosure Checklist Generator

### Overview

State-specific seller disclosure requirements with completion tracking. Helps sellers understand what they must legally disclose, reducing risk of post-sale legal issues.

### Value Proposition

| Problem | Solution |
|---------|----------|
| Don't know what to disclose | State-specific checklist |
| Fear of legal liability | Guided documentation |
| Overwhelmed by forms | Step-by-step completion |
| Missing supporting docs | Links to Document Vault |
| Agent/attorney review | Exportable summary |

### How It Works

```
┌────────────────────────────────────────────────────────────────┐
│                  DISCLOSURE CHECKLIST FLOW                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  1. SELECT STATE                                               │
│     Disclosure requirements vary significantly by state.       │
│     California has extensive requirements; some states         │
│     have minimal requirements.                                 │
│                                                                │
│  2. GENERATE CHECKLIST                                         │
│     Based on state, generate list of disclosure categories:    │
│     • Structural issues                                        │
│     • Water damage history                                     │
│     • Pest infestations                                        │
│     • Environmental hazards (lead, asbestos, radon)            │
│     • HOA information                                          │
│     • Neighborhood nuisances                                   │
│     • Deaths on property (in some states)                      │
│     • Legal disputes                                           │
│                                                                │
│  3. COMPLETE EACH ITEM                                         │
│     For each disclosure item:                                  │
│     • Answer yes/no/unknown                                    │
│     • Add details if applicable                                │
│     • Link supporting documents                                │
│     • Flag items needing attention                             │
│                                                                │
│  4. EXPORT SUMMARY                                             │
│     Generate summary for attorney/agent review.                │
│     Does NOT replace official disclosure forms.                │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Checklist UI

```
┌─────────────────────────────────────────────────────────────────┐
│  📋 SELLER DISCLOSURE CHECKLIST                    California   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PROGRESS: ████████████████░░░░ 80% complete                    │
│                                                                 │
│  STRUCTURAL & SYSTEMS                               12/15 done  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ✓ Foundation cracks or settling?                       │    │
│  │    Answer: No                                           │    │
│  │                                                         │    │
│  │  ✓ Roof leaks or repairs?                               │    │
│  │    Answer: Yes - repaired 2023                          │    │
│  │    📄 Roof repair invoice attached                      │    │
│  │                                                         │    │
│  │  ⚠️ Plumbing issues?                                     │    │
│  │    Answer: Unknown - needs review                       │    │
│  │    [Complete This Item]                                 │    │
│  │                                                         │    │
│  │  ... more items                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  WATER & MOISTURE                                   8/8 done ✓  │
│  ENVIRONMENTAL                                      5/6 done    │
│  NEIGHBORHOOD                                       4/4 done ✓  │
│  LEGAL & TITLE                                      3/5 done    │
│                                                                 │
│  [Export Summary for Review]                                    │
│                                                                 │
│  ⚠️ This checklist helps you prepare but does NOT replace       │
│     official disclosure forms required by your state.           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### State Coverage (Examples)

| State | Disclosure Requirements | Complexity |
|-------|------------------------|------------|
| California | TDS, NHD, many specific forms | Very High |
| Texas | Seller's Disclosure Notice | High |
| Florida | Johnson v. Davis standard | Medium |
| New York | Property Condition Disclosure | Medium |
| States with minimal | Caveat emptor states | Low |

### Important Disclaimers

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚠️ IMPORTANT LEGAL NOTICE                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  This checklist is a PREPARATION TOOL only.                     │
│                                                                 │
│  • It does NOT replace official state disclosure forms          │
│  • It does NOT constitute legal advice                          │
│  • Requirements may have changed since this was created         │
│  • Always work with a real estate attorney or agent             │
│  • HomeTrack is not liable for disclosure completeness          │
│                                                                 │
│  We recommend:                                                  │
│  1. Complete this checklist for your records                    │
│  2. Share with your real estate agent                           │
│  3. Consult an attorney for legal questions                     │
│  4. Complete official state forms with professional help        │
│                                                                 │
│                         [I Understand]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Success Metrics

| Metric | Target |
|--------|--------|
| Checklists started (of sellers) | 40%+ |
| Checklists completed | 70%+ |
| Documents linked | 5+ per checklist |
| Exports generated | 50%+ of completed |
| "Reduced stress" survey | 60%+ |

---

## 5. Before/After Project Gallery

### Overview

Visual documentation of home improvement projects with side-by-side comparisons. Creates compelling content for Home History Report and personal satisfaction.

### Value Proposition

| Use Case | Value |
|----------|-------|
| Home History Report | Visual proof of improvements |
| Personal satisfaction | See your progress |
| Insurance claims | Document improvements |
| Refinance appraisal | Support higher valuation |
| Social sharing | Show off your work |

### Project Structure

| Field | Description | Required |
|-------|-------------|----------|
| **Project Name** | "Kitchen Remodel", "Deck Addition" | Yes |
| **Category** | Kitchen, Bath, Exterior, etc. | Yes |
| **Start Date** | When project began | Yes |
| **End Date** | When completed | Optional until done |
| **Budget** | Planned cost | Optional |
| **Actual Cost** | Final cost | Recommended |
| **Contractor** | Who did the work | Optional |
| **Permits** | Linked permit documents | If applicable |
| **Before Photos** | Starting condition | Recommended |
| **Progress Photos** | During work | Optional |
| **After Photos** | Completed result | Recommended |
| **Notes** | Description, lessons learned | Optional |

### Project Creation Flow

```
┌────────────────────────────────────────────────────────────────┐
│                  CREATE PROJECT FLOW                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  STEP 1: Start Project                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  📸 NEW PROJECT                                         │   │
│  │                                                         │   │
│  │  Project Name: [Kitchen Remodel____________]            │   │
│  │  Category:     [Kitchen                    ▼]           │   │
│  │  Start Date:   [January 15, 2026           ]            │   │
│  │  Budget:       [$ 25,000                   ]            │   │
│  │                                                         │   │
│  │  [Continue →]                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 2: Capture "Before" Photos                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  📷 BEFORE PHOTOS                                       │   │
│  │                                                         │   │
│  │  Document the starting condition from multiple angles.  │   │
│  │                                                         │   │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                        │   │
│  │  │ 📷  │ │ 📷  │ │ 📷  │ │  +  │                        │   │
│  │  │     │ │     │ │     │ │ Add │                        │   │
│  │  └─────┘ └─────┘ └─────┘ └─────┘                        │   │
│  │                                                         │   │
│  │  💡 Tip: Capture overall room + specific areas          │   │
│  │     you plan to change                                  │   │
│  │                                                         │   │
│  │  [Save & Start Project]                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  STEP 3: Track Progress (ongoing)                              │
│  • Add progress photos anytime                                 │
│  • Update costs as invoices come in                            │
│  • Link permits when pulled                                    │
│  • Add notes about decisions, changes                          │
│                                                                │
│  STEP 4: Complete Project                                      │
│  • Add "After" photos                                          │
│  • Enter final cost                                            │
│  • Mark as complete                                            │
│  • Auto-generates comparison view                              │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Before/After Comparison View

```
┌─────────────────────────────────────────────────────────────────┐
│  🏠 KITCHEN REMODEL                              Completed ✓    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────┬────────────────────────┐            │
│  │                        │                        │            │
│  │       BEFORE           │        AFTER           │            │
│  │                        │                        │            │
│  │    [Before Photo]      │    [After Photo]       │            │
│  │                        │                        │            │
│  │                        │                        │            │
│  └────────────────────────┴────────────────────────┘            │
│                                                                 │
│  ◄─────────────────────●─────────────────────►                  │
│  Drag slider to compare                                         │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  PROJECT DETAILS                                                │
│  ├── Duration:     Jan 15 - Mar 20, 2026 (9 weeks)             │
│  ├── Budget:       $25,000                                      │
│  ├── Actual Cost:  $27,500 (10% over)                          │
│  ├── Contractor:   ABC Kitchen & Bath                           │
│  └── Permit:       #2026-1234 (attached)                        │
│                                                                 │
│  WHAT WE DID                                                    │
│  • Replaced cabinets (shaker style, white)                      │
│  • New quartz countertops                                       │
│  • Subway tile backsplash                                       │
│  • New stainless appliances                                     │
│  • Updated lighting                                             │
│                                                                 │
│  [View All 24 Photos]          [Include in Home History Report] │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Interactive Slider

The signature feature: a draggable slider that reveals before/after:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                          │                              │    │
│  │                          │                              │    │
│  │      BEFORE              │        AFTER                 │    │
│  │      IMAGE               │        IMAGE                 │    │
│  │                          │                              │    │
│  │                        ◄─┼─►                            │    │
│  │                          │                              │    │
│  │                          │                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  User drags the center line left/right to reveal               │
│  more of either before or after image.                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Gallery View

```
┌─────────────────────────────────────────────────────────────────┐
│  📸 PROJECT GALLERY                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │                     │  │                     │               │
│  │   [Kitchen Photo]   │  │   [Bathroom Photo]  │               │
│  │                     │  │                     │               │
│  │   Kitchen Remodel   │  │   Primary Bath      │               │
│  │   ✓ Complete        │  │   ● In Progress     │               │
│  │   $27,500           │  │   $12,000 budget    │               │
│  └─────────────────────┘  └─────────────────────┘               │
│                                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │                     │  │                     │               │
│  │   [Deck Photo]      │  │        +            │               │
│  │                     │  │                     │               │
│  │   Deck Staining     │  │   New Project       │               │
│  │   ✓ Complete        │  │                     │               │
│  │   $800              │  │                     │               │
│  └─────────────────────┘  └─────────────────────┘               │
│                                                                 │
│  TOTAL INVESTED: $28,300                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Success Metrics

| Metric | Target |
|--------|--------|
| Projects created | 40%+ of active users |
| Before photos captured | 80%+ of projects |
| After photos captured | 70%+ of completed projects |
| Slider comparisons viewed | 90%+ of completed projects |
| Included in Home History | 60%+ of reports |

---

## 6. Receipt Scanner with Auto-Extraction

### Overview

AI-powered receipt scanning that automatically extracts vendor, date, amount, and line items. Reduces friction of logging maintenance costs and project expenses.

### Value Proposition

| Manual Entry | Receipt Scanner |
|--------------|-----------------|
| Type vendor name | Auto-extracted |
| Enter date | Auto-extracted |
| Enter amount | Auto-extracted |
| Easy to skip/forget | Just snap a photo |
| Errors and typos | OCR accuracy |

### How It Works

```
┌────────────────────────────────────────────────────────────────┐
│                  RECEIPT SCANNER FLOW                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  1. CAPTURE                                                    │
│     User points camera at receipt.                             │
│     Auto-detect edges, auto-capture when stable.               │
│                                                                │
│  2. PROCESS                                                    │
│     Send to OCR API (AWS Textract or Google Document AI).      │
│     Extract structured data.                                   │
│                                                                │
│  3. REVIEW                                                     │
│     Show extracted data for user confirmation.                 │
│     User corrects any errors.                                  │
│                                                                │
│  4. CATEGORIZE                                                 │
│     Auto-suggest category based on vendor.                     │
│     • "Home Depot" → Materials                                 │
│     • "ABC Plumbing" → Professional Service                    │
│                                                                │
│  5. LINK                                                       │
│     Associate with maintenance task or project.                │
│     Store receipt image in Document Vault.                     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Scanner UI

```
┌─────────────────────────────────────────────────────────────────┐
│  📷 SCAN RECEIPT                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                                                         │    │
│  │                                                         │    │
│  │              [CAMERA VIEWFINDER]                        │    │
│  │                                                         │    │
│  │           ┌─────────────────────┐                       │    │
│  │           │   Position receipt  │                       │    │
│  │           │   within frame      │                       │    │
│  │           └─────────────────────┘                       │    │
│  │                                                         │    │
│  │                                                         │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  💡 Hold steady - auto-capture when detected                    │
│                                                                 │
│  [🖼️ Choose from Photos]                    [⚡ Flash: Auto]    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Extraction Review

```
┌─────────────────────────────────────────────────────────────────┐
│  ✓ RECEIPT SCANNED                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐                                           │
│  │                  │  EXTRACTED DATA                           │
│  │    [Receipt      │  ─────────────────────────────            │
│  │     Thumbnail]   │                                           │
│  │                  │  Vendor:   HOME DEPOT              [Edit] │
│  │                  │  Date:     January 15, 2026        [Edit] │
│  └──────────────────┘  Amount:   $127.43                 [Edit] │
│                                                                 │
│  ITEMS DETECTED                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  HVAC Filter 20x25x1 (4-pack)              $45.97       │    │
│  │  Furnace Filter 16x25x1 (2-pack)           $28.99       │    │
│  │  Duct Tape                                 $8.47        │    │
│  │  Tax                                       $6.94        │    │
│  │  ─────────────────────────────────────────────────      │    │
│  │  TOTAL                                     $127.43      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  CATEGORY (auto-suggested)                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Materials / Supplies                               ▼   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  LINK TO                                                        │
│  ○ Maintenance Task: [Select task...          ▼]               │
│  ○ Project: [Select project...                ▼]               │
│  ○ Just save to Document Vault                                  │
│                                                                 │
│                    [Save Receipt]                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Extracted

| Field | Extraction Confidence | Notes |
|-------|----------------------|-------|
| Vendor/Store Name | High | Usually in header |
| Date | High | Multiple date formats |
| Total Amount | High | Usually prominent |
| Subtotal | Medium | Before tax |
| Tax | Medium | When itemized |
| Line Items | Medium | When clearly printed |
| Payment Method | Low | Often partial info |

### Auto-Categorization Rules

| Vendor Pattern | Category |
|----------------|----------|
| Home Depot, Lowe's, Menards | Materials |
| ABC Plumbing, XYZ Electric | Professional Service |
| Sherwin-Williams, Benjamin Moore | Paint/Supplies |
| Amazon (home categories) | Materials |
| HVAC company names | HVAC Service |
| Nursery, garden center | Landscaping |

### Technical Approach

| Component | Solution |
|-----------|----------|
| OCR | AWS Textract or Google Document AI |
| Edge Detection | On-device ML for auto-crop |
| Data Extraction | Structured extraction API |
| Confidence Scores | Show low-confidence fields for review |
| Cost | ~$0.01-0.02 per receipt processed |

### Success Metrics

| Metric | Target |
|--------|--------|
| Receipts scanned | 60%+ of expense entries |
| Auto-extraction accuracy | 90%+ (vendor, date, total) |
| User edits required | <20% of fields |
| Time saved vs manual | 70%+ reduction |
| Feature satisfaction | 4.5+ stars |

---

## Implementation Priority

### Recommended Build Order

| Order | Feature | Rationale |
|-------|---------|-----------|
| 1 | **Before/After Gallery** | Foundation for Home History Report |
| 2 | **Receipt Scanner** | Improves data quality for all features |
| 3 | **Home History Report** | Core differentiator, needs Gallery + data |
| 4 | **Account Transfer** | Network effects, drives growth |
| 5 | **Home Inventory** | Standalone, high value |
| 6 | **Disclosure Checklist** | Complements selling features |

### Estimated Effort

| Feature | Effort | Dependencies |
|---------|--------|--------------|
| Before/After Gallery | 3-4 weeks | Camera integration |
| Receipt Scanner | 3-4 weeks | OCR API integration |
| Home History Report | 4-5 weeks | Needs data from all other features |
| Account Transfer | 3-4 weeks | Auth system, data migration |
| Home Inventory | 4-5 weeks | Camera, OCR for barcodes |
| Disclosure Checklist | 2-3 weeks | State data research |

### Total v2.0 Timeline: 12-16 weeks

---

## Appendix: Feature Dependencies

```
┌────────────────────────────────────────────────────────────────┐
│                    FEATURE DEPENDENCIES                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  HOME HISTORY REPORT                                           │
│  ├── Requires: Home Profile (MVP)                              │
│  ├── Requires: Maintenance Calendar (MVP)                      │
│  ├── Requires: Document Vault (MVP)                            │
│  ├── Enhanced by: Before/After Gallery (v2.0)                  │
│  └── Enhanced by: Receipt Scanner (v2.0)                       │
│                                                                │
│  ACCOUNT TRANSFER                                              │
│  ├── Requires: All MVP features                                │
│  └── Requires: Robust auth system                              │
│                                                                │
│  HOME INVENTORY                                                │
│  ├── Standalone (no dependencies)                              │
│  └── Enhanced by: Receipt Scanner (v2.0)                       │
│                                                                │
│  DISCLOSURE CHECKLIST                                          │
│  ├── Enhanced by: Document Vault (MVP)                         │
│  └── Companion to: Home History Report (v2.0)                  │
│                                                                │
│  BEFORE/AFTER GALLERY                                          │
│  ├── Standalone (no dependencies)                              │
│  └── Feeds into: Home History Report (v2.0)                    │
│                                                                │
│  RECEIPT SCANNER                                               │
│  ├── Integrates with: Maintenance Calendar (MVP)               │
│  ├── Integrates with: Before/After Gallery (v2.0)              │
│  └── Feeds into: Document Vault (MVP)                          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Appendix: Premium Feature Matrix

| Feature | Free | Premium |
|---------|------|---------|
| Before/After Gallery (limited) | 3 projects | Unlimited |
| Before/After Gallery (full) | ❌ | ✅ |
| Receipt Scanner | ❌ | ✅ |
| Home History Report | ❌ | ✅ |
| Account Transfer | ❌ | ✅ |
| Home Inventory | ❌ | ✅ |
| Disclosure Checklist | ❌ | ✅ |

---

## Appendix: Data Sources & APIs

| Feature | API/Service | Cost |
|---------|-------------|------|
| Receipt Scanner | AWS Textract | ~$0.015/page |
| Receipt Scanner (alt) | Google Document AI | ~$0.01/page |
| Barcode Lookup | UPCitemdb or Open Food Facts | Free/Low |
| Disclosure Requirements | Manual research + legal review | One-time |
| PDF Generation | React-PDF or similar | Free |

---

*End of v2.0 Features Overview*
