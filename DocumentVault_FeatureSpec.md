# Document Vault
## Complete Feature Specification

**HomeTrack MVP — Core Feature #1**  
*Version 1.0 | January 2026*

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Document Categories & Types](#2-document-categories--types)
3. [User Flows](#3-user-flows)
4. [Search & Discovery](#4-search--discovery)
5. [Expiration Tracking System](#5-expiration-tracking-system)
6. [Document Detail View](#6-document-detail-view)
7. [Sharing & Export](#7-sharing--export)
8. [UI/UX Specifications](#8-uiux-specifications)
9. [Notifications](#9-notifications)
10. [Error Handling & Edge Cases](#10-error-handling--edge-cases)
11. [Accessibility Requirements](#11-accessibility-requirements)
12. [Data Model](#12-data-model)
13. [Success Metrics](#13-success-metrics)
14. [Implementation Phases](#14-implementation-phases)

---

## 1. Feature Overview

### 1.1 Purpose

The Document Vault is the foundational feature of HomeTrack—a secure, organized, and searchable repository for all home-related documents. It eliminates the chaos of paper files, scattered digital photos, and forgotten warranties by creating a single source of truth for every important document related to the home.

### 1.2 Problem Statement

| Pain Point | Impact |
|------------|--------|
| Warranties get lost or forgotten | Homeowners miss coverage, pay for repairs unnecessarily |
| Documents scattered across email, paper, phone photos | Hours wasted searching for specific documents |
| No system for tracking expiration dates | Insurance lapses, warranty claims missed |
| Receipts lost for major purchases | Can't prove cost basis, warranty claims denied |
| Can't prove maintenance history when selling | Lower sale price, buyer distrust |

### 1.3 Solution

A mobile-first document management system that:

- **Captures** documents via camera, photo library, or file import
- **Organizes** automatically into smart categories
- **Extracts** text via OCR for full-text search
- **Tracks** expiration dates with proactive reminders
- **Shares** securely with contractors, inspectors, or buyers

### 1.4 Core Value Propositions

| Value | How We Deliver |
|-------|----------------|
| **Never lose another document** | Cloud backup with offline access |
| **Find anything in seconds** | Full-text OCR search across all documents |
| **Never miss an expiration** | Smart reminders at 90/30/7 days |
| **Prove your home's history** | Organized records ready for insurance or sale |
| **Share professionally** | Secure links with expiration and access control |

### 1.5 Success Metrics

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Documents uploaded per user (30 days) | 10+ | Core engagement indicator |
| Users with 5+ documents | 60% | Meaningful adoption |
| Search usage rate | 40%+ weekly | Proves OCR value |
| Expiration dates set | 50%+ of applicable docs | Key differentiator usage |
| Document retrieval time | <10 seconds | User satisfaction |
| Upload completion rate | 95%+ | Frictionless experience |

---

## 2. Document Categories & Types

### 2.1 Category Architecture

Documents are organized into **six primary categories** plus user-created custom categories. Each category contains specific document types with tailored metadata fields.

```
Document Vault
├── 📁 Ownership Documents
├── 📁 Insurance
├── 📁 Warranties & Manuals
├── 📁 Maintenance Records
├── 📁 Permits & Compliance
├── 📁 Financial Documents
└── 📁 Custom Categories (user-created)
```

### 2.2 Category Details

#### 📁 Ownership Documents

**Purpose:** Critical legal documents establishing property ownership. Retain for entire ownership + 7 years.

| Document Type | Description | Key Metadata Fields |
|---------------|-------------|---------------------|
| Deed | Legal document transferring ownership | Recording date, grantor, grantee, legal description, county |
| Title Insurance Policy | Protection against title defects | Policy number, coverage amount, effective date, title company |
| Purchase Contract | Original purchase agreement | Purchase price, closing date, seller name, contingencies |
| Closing Disclosure | Final closing statement (HUD-1) | Closing date, final purchase price, all fees |
| Survey/Plat Map | Property boundary documentation | Survey date, surveyor name, lot dimensions, easements |
| HOA Documents | CC&Rs, bylaws, rules | HOA name, dues amount, effective date |
| Property Tax Assessment | Official assessed value | Tax year, assessed value, parcel number |

#### 📁 Insurance

**Purpose:** All insurance-related documents. Expiration tracking is critical for this category.

| Document Type | Description | Key Metadata Fields |
|---------------|-------------|---------------------|
| Homeowners Policy | Primary insurance declaration page | Policy #, carrier, coverage amounts (dwelling, personal property, liability), premium, effective date, expiration date |
| Flood Insurance | Separate flood coverage | Policy #, coverage amount, premium, expiration date, flood zone |
| Earthquake Insurance | Separate earthquake coverage | Policy #, coverage amount, deductible, expiration date |
| Umbrella Policy | Additional liability coverage | Policy #, coverage amount, underlying requirements, expiration date |
| Home Warranty | Appliance/systems warranty policy | Policy #, covered items, service fee, expiration date, provider |
| Insurance Claim Records | Past claims documentation | Claim #, date of loss, description, payout amount, status |
| Insurance Photos | Pre-loss condition documentation | Date taken, room/area, notes |

#### 📁 Warranties & Manuals

**Purpose:** Product warranties and equipment documentation. Expiration tracking is the primary value-add.

| Document Type | Description | Key Metadata Fields |
|---------------|-------------|---------------------|
| Appliance Warranty | Manufacturer warranty | Brand, model, serial #, purchase date, expiration date, retailer |
| System Warranty | HVAC, roof, plumbing warranties | System type, installer, installation date, warranty period, expiration date |
| Contractor Warranty | Workmanship guarantees | Contractor name, work type, completion date, warranty period, expiration date |
| Extended Warranty | Purchased extended coverage | Provider, original product, coverage details, expiration date, claim process |
| Product Manual | User manuals for equipment | Product name, brand, model #, linked appliance |
| Installation Guide | Installation documentation | Product, installer, installation date |

#### 📁 Maintenance Records

**Purpose:** Documentation of all maintenance performed. Critical for building home history.

| Document Type | Description | Key Metadata Fields |
|---------------|-------------|---------------------|
| Service Receipt | Receipt from professional service | Vendor, date, service type, cost, technician name |
| Inspection Report | Professional inspection documentation | Inspector, date, inspection type, findings summary, pass/fail |
| Repair Invoice | Documentation of repairs | Contractor, date, work description, parts used, labor hours, total cost |
| Service Contract | Ongoing service agreements | Provider, services included, term, monthly/annual cost, renewal date |
| DIY Documentation | Self-performed work records | Date, work type, materials used, cost, time spent, notes |
| Maintenance Log Entry | Simple maintenance record | Date, task performed, notes |

#### 📁 Permits & Compliance

**Purpose:** Building permits and compliance documentation. Essential for proving work was done to code.

| Document Type | Description | Key Metadata Fields |
|---------------|-------------|---------------------|
| Building Permit | Permit for construction work | Permit #, issue date, work type, contractor, status, final inspection date |
| Certificate of Occupancy | CO for new construction/major reno | Issue date, issuing authority, property address |
| Inspection Certificate | Passed inspection documentation | Inspector, date, inspection type, result |
| Zoning Documentation | Variance approvals, zoning letters | Type, approval date, conditions, expiration (if any) |
| Code Compliance Letter | Documentation of code compliance | Issue date, scope, issuing body |
| Contractor License | Contractor's license documentation | Contractor, license #, expiration date, trade |

#### 📁 Financial Documents

**Purpose:** Mortgage documents, tax records, and improvement documentation for tax basis tracking.

| Document Type | Description | Key Metadata Fields |
|---------------|-------------|---------------------|
| Mortgage Documents | Loan docs, promissory note | Lender, loan #, original amount, interest rate, term, origination date |
| Property Tax Bill | Annual tax statements | Tax year, amount due, due date, parcel # |
| Improvement Receipt | Major improvement costs | Date, improvement type, cost, contractor, for basis tracking |
| Appraisal | Professional property appraisals | Appraiser, date, appraised value, purpose |
| Refinance Documents | Refinancing documentation | Date, new lender, new terms, closing costs |
| HELOC Documents | Home equity line documentation | Lender, credit limit, draw period, rate |

#### 📁 Custom Categories

Users can create custom categories for documents that don't fit standard categories.

**Features:**
- User-defined category name
- Icon selection from preset library (50+ icons)
- Custom document types within category
- All standard metadata fields available

**Common Custom Categories:**
- Pool & Spa
- Solar System
- Security System
- Landscaping/Irrigation
- Septic System
- Well Water System
- Guest House/ADU
- Storage Unit

### 2.3 Document Retention Guidelines

Display to users as helpful guidance:

| Category | Recommended Retention |
|----------|----------------------|
| Ownership Documents | Entire ownership + 7 years after sale |
| Insurance Policies | Current + 3 years of prior policies |
| Warranties | Until expiration + 1 year |
| Maintenance Records | Entire ownership (valuable for sale) |
| Permits | Permanent (transfers with property) |
| Financial/Tax | 7 years minimum |
| Manuals | Until appliance replaced |

---

## 3. User Flows

### 3.1 Document Upload Flow

#### Primary Upload Flow (Camera Capture)

```
┌─────────────────────────────────────────────────────────────────┐
│  1. TAP "+" BUTTON                                              │
│     └── Floating Action Button (FAB) on Vault home screen       │
│                                                                 │
│  2. SELECT SOURCE                                               │
│     ├── 📷 Camera (default/highlighted)                         │
│     ├── 🖼️ Photo Library                                        │
│     ├── 📄 Files (PDF import)                                   │
│     └── 📧 Email Import (future)                                │
│                                                                 │
│  3. CAPTURE DOCUMENT                                            │
│     ├── Full-screen camera with document detection              │
│     ├── Auto-edge detection highlights document borders         │
│     ├── "Hold steady..." guidance text                          │
│     ├── Auto-capture when stable (optional setting)             │
│     └── Manual capture button                                   │
│                                                                 │
│  4. REVIEW & ADJUST                                             │
│     ├── Preview with auto-crop applied                          │
│     ├── Drag corners to adjust crop                             │
│     ├── Rotate button (90°)                                     │
│     ├── Filter: Auto-enhance | Grayscale | Original             │
│     ├── "Add Page" for multi-page documents                     │
│     ├── Page thumbnails at bottom                               │
│     └── "Retake" | "Continue" buttons                           │
│                                                                 │
│  5. SELECT CATEGORY                                             │
│     ├── 6 category cards in 2x3 grid                            │
│     ├── AI suggestion highlighted (if detected)                 │
│     ├── Custom categories below                                 │
│     └── "Create New Category" option                            │
│                                                                 │
│  6. SELECT DOCUMENT TYPE                                        │
│     ├── List of types for selected category                     │
│     ├── Most common types at top                                │
│     └── "Other" option at bottom                                │
│                                                                 │
│  7. ENTER METADATA                                              │
│     ├── Document name (auto-suggested from OCR if possible)     │
│     ├── Context-specific fields based on document type          │
│     ├── Date fields with calendar picker                        │
│     ├── Amount fields with currency formatting                  │
│     ├── "Link to Appliance/System" (optional)                   │
│     └── Notes field (optional, expandable)                      │
│                                                                 │
│  8. SAVE                                                        │
│     ├── "Save" button (primary)                                 │
│     ├── Upload begins in background                             │
│     ├── Progress indicator shown                                │
│     └── User can navigate away                                  │
│                                                                 │
│  9. CONFIRMATION                                                │
│     ├── Success toast/modal                                     │
│     ├── "Add Another" button                                    │
│     ├── "View Document" button                                  │
│     └── "Done" returns to Vault home                            │
└─────────────────────────────────────────────────────────────────┘
```

#### Express Upload (Minimum Friction)

For users who want speed over organization:

1. Capture/select document
2. Select category only (skip document type)
3. Auto-generate name: `[Category] - [Date]`
4. Save immediately
5. Document added to "Needs Review" queue
6. Badge shown on Vault home: "3 documents need details"

#### Batch Upload

For initial setup or bulk import:

1. Select multiple photos/files (up to 20)
2. Choose single category to apply to all
3. Documents uploaded with auto-generated names
4. "Review & Complete" queue created
5. User can add details to each document later

### 3.2 Document Browse Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  VAULT HOME SCREEN                                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 🔍 Search documents, warranties, receipts...              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 📊 47 documents | ⚠️ 3 expiring soon                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ ⚠️ HVAC Warranty expires in 12 days          [View →]   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ 🏠          │  │ 🛡️          │  │ 📋          │              │
│  │ Ownership   │  │ Insurance   │  │ Warranties  │              │
│  │ 8 docs      │  │ 5 docs      │  │ 12 docs     │              │
│  │             │  │ ⚠️ 1 expiring│  │ ⚠️ 2 expiring│              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ 🔧          │  │ 📜          │  │ 💰          │              │
│  │ Maintenance │  │ Permits     │  │ Financial   │              │
│  │ 15 docs     │  │ 4 docs      │  │ 3 docs      │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                 │
│  RECENT DOCUMENTS                                               │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                   │
│  │ 📄   │ │ 📄   │ │ 📄   │ │ 📄   │ │ 📄   │  →                │
│  │ HVAC │ │ Roof │ │ Tax  │ │ Deed │ │ ...  │                   │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘                   │
│                                                                 │
│                                            ┌─────┐              │
│                                            │  +  │ ← FAB        │
│                                            └─────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Category View Flow

When user taps a category:

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Warranties & Manuals                           🔍  ⋮         │
│  12 documents                                                   │
├─────────────────────────────────────────────────────────────────┤
│  Sort: Newest ▼    Filter: All ▼    View: List | Grid          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ⚠️ EXPIRING SOON (2)                                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ HVAC System Warranty              │ 🟠 12 days    │    │
│  │    │ Lennox • Installed 2022           │               │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Refrigerator Warranty             │ 🟡 45 days    │    │
│  │    │ Samsung • Purchased 2023          │               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ALL WARRANTIES                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Roof Warranty                     │ 🟢 Valid      │    │
│  │    │ GAF • Installed 2021              │ Exp: 2041     │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Dishwasher Warranty               │ 🟢 Valid      │    │
│  │    │ Bosch • Purchased 2024            │ Exp: 2026     │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Water Heater Warranty             │ 🔴 Expired    │    │
│  │    │ Rheem • Installed 2018            │ Exp: 2024     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  [Load More...]                                                 │
│                                                                 │
│                                            ┌─────┐              │
│                                            │  +  │              │
│                                            └─────┘              │
└─────────────────────────────────────────────────────────────────┘
```

**Swipe Actions on Document Cards:**
- Swipe Left → Delete (with confirmation)
- Swipe Right → Share
- Long Press → Multi-select mode

---

## 4. Search & Discovery

### 4.1 Search Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        SEARCH SYSTEM                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   OCR TEXT   │    │   METADATA   │    │   FILTERS    │     │
│  │   SEARCH     │    │   SEARCH     │    │              │     │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤     │
│  │ • Full text  │    │ • Doc name   │    │ • Category   │     │
│  │   from all   │    │ • Doc type   │    │ • Date range │     │
│  │   documents  │    │ • Vendor     │    │ • Expiration │     │
│  │ • Fuzzy      │    │ • Brand      │    │ • Amount     │     │
│  │   matching   │    │ • Amount     │    │ • Has photos │     │
│  │ • Ranked by  │    │ • Notes      │    │ • Linked to  │     │
│  │   relevance  │    │              │    │   appliance  │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                │
│                         ↓ COMBINED ↓                           │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    SEARCH RESULTS                         │ │
│  │  • Ranked by relevance score                              │ │
│  │  • Matching text highlighted in snippet                   │ │
│  │  • Grouped by category (optional)                         │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### 4.2 Search Interface

**Search Bar States:**

| State | Appearance |
|-------|------------|
| Default | "Search documents, warranties, receipts..." placeholder |
| Focused | Keyboard appears, filter chips visible below |
| Active | Query visible, "X" clear button, results updating |
| Results | Result count shown, filter chips active |

**Filter Chips (Below Search Bar):**

```
[ All ] [ Ownership ] [ Insurance ] [ Warranties ] [ Maintenance ] [ Permits ] [ Financial ]
[ Expiring Soon ] [ This Year ] [ Has Amount ]
```

### 4.3 Search Capabilities

| Search Type | How It Works | Example Query |
|-------------|--------------|---------------|
| **Full-Text (OCR)** | Searches extracted text from document images | "water heater" finds warranty PDF mentioning it |
| **Document Name** | Matches against document titles | "roof inspection" finds titled documents |
| **Vendor/Brand** | Searches vendor and brand metadata | "Home Depot" finds all HD receipts |
| **Amount Range** | Filters by dollar amount | "$500" or "$100-500" |
| **Date Range** | Filters by document date | "2024" or "last year" |
| **Category** | Filters to specific category | "warranty" limits to Warranties category |
| **Expiration** | Filters by expiration status | "expiring" shows 90-day window |
| **Natural Language** | Interprets common queries | "HVAC stuff" searches HVAC-related terms |

### 4.4 Search Results Display

```
┌─────────────────────────────────────────────────────────────────┐
│  🔍 water heater                                    ✕           │
├─────────────────────────────────────────────────────────────────┤
│  [ All ] [ Warranties ✓ ] [ Maintenance ] [ Expiring ]          │
├─────────────────────────────────────────────────────────────────┤
│  4 results for "water heater"              Sort: Relevance ▼    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Water Heater Warranty              │ 📋 Warranty  │    │
│  │    │ "...50-gallon WATER HEATER model   │              │    │
│  │    │ XYZ123 is covered for..."          │ 🟢 Valid     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Plumbing Service Receipt           │ 🔧 Maint.    │    │
│  │    │ "...replaced anode rod in WATER    │              │    │
│  │    │ HEATER, flushed tank..."           │ Jan 2024     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Home Inspection Report             │ 📜 Permits   │    │
│  │    │ "...WATER HEATER is 8 years old,   │              │    │
│  │    │ recommend replacement within..."   │ 2022         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 📄 │ Water Heater Manual                │ 📋 Warranty  │    │
│  │    │ "Rheem Performance Plus WATER      │              │    │
│  │    │ HEATER Installation Guide..."      │ Manual       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.5 No Results State

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    🔍                                           │
│                                                                 │
│         No documents found for "xyz123"                         │
│                                                                 │
│         Try:                                                    │
│         • Check spelling                                        │
│         • Use fewer or different keywords                       │
│         • Remove filters                                        │
│                                                                 │
│         [ Clear Search ]    [ Browse All Documents ]            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.6 Recent & Suggested Searches

When search bar is focused but empty:

```
┌─────────────────────────────────────────────────────────────────┐
│  RECENT SEARCHES                                                │
│  🕐 water heater                                                │
│  🕐 home depot                                                  │
│  🕐 roof                                                        │
│                                                                 │
│  SUGGESTED                                                      │
│  ⚡ Expiring soon (3 documents)                                 │
│  ⚡ Added this week                                             │
│  ⚡ Insurance documents                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Expiration Tracking System

### 5.1 Overview

The expiration tracking system is a **key differentiator** that prevents users from missing warranty claims, insurance renewals, and other time-sensitive deadlines. It's one of the primary reasons users will choose HomeTrack over generic file storage.

### 5.2 Documents with Expiration Tracking

| Document Type | Why Tracking Matters | Default Reminders |
|---------------|---------------------|-------------------|
| Appliance Warranty | Claim repairs before coverage ends | 90, 30, 7 days |
| System Warranty | Schedule inspection before expiration | 90, 30, 7 days |
| Contractor Warranty | Document issues while still covered | 60, 14 days |
| Homeowners Insurance | Prevent coverage lapse | 30, 14, 7 days |
| Home Warranty Policy | Decide on renewal | 60, 30, 7 days |
| Service Contracts | Renew or cancel before auto-renewal | 30, 7 days |
| Extended Warranty | Use coverage before it expires | 90, 30, 7 days |
| Contractor License | Verify contractor is still licensed | 30 days |

### 5.3 Expiration Status System

| Status | Badge | Criteria | Visual Treatment |
|--------|-------|----------|------------------|
| **Valid** | 🟢 | >90 days until expiration | Green badge, normal display |
| **Expiring Soon** | 🟡 | 30-90 days until expiration | Yellow badge, subtle highlight |
| **Expiring Imminently** | 🟠 | <30 days until expiration | Orange badge, prominent highlight |
| **Expired** | 🔴 | Past expiration date | Red badge, muted/strikethrough |
| **No Expiration** | — | Document type doesn't expire | No badge |

### 5.4 Expiration Dashboard

Dedicated view accessible from Vault home (tap "X expiring soon"):

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Expiration Tracker                              📅  ⋮        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🔴 EXPIRED (1)                                    [View All →] │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Water Heater Warranty                                   │    │
│  │ Expired 45 days ago • Dec 1, 2025                       │    │
│  │ [ Update Document ] [ Archive ]                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🟠 THIS MONTH (2)                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ HVAC System Warranty                        12 days     │    │
│  │ Expires Jan 27, 2026                                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Pest Control Contract                       23 days     │    │
│  │ Expires Feb 7, 2026                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🟡 NEXT 3 MONTHS (4)                                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Refrigerator Warranty                       45 days     │    │
│  │ Expires Mar 1, 2026                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Homeowners Insurance                        62 days     │    │
│  │ Expires Mar 18, 2026                                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│  [+ 2 more...]                                                  │
│                                                                 │
│  📅 CALENDAR VIEW                                  [Toggle →]   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.5 Calendar View

Toggle to see expirations on a calendar:

```
┌─────────────────────────────────────────────────────────────────┐
│                      JANUARY 2026                               │
│  Su   Mo   Tu   We   Th   Fr   Sa                               │
│                 1    2    3    4                                │
│   5    6    7    8    9   10   11                               │
│  12   13   14  [15]  16   17   18                               │
│  19   20   21   22   23   24   25                               │
│  26  🟠27  28   29   30   31                                    │
│                                                                 │
│  🟠 January 27                                                  │
│  └── HVAC System Warranty expires                               │
│                                                                 │
│                      FEBRUARY 2026                              │
│  Su   Mo   Tu   We   Th   Fr   Sa                               │
│                                  1                              │
│   2    3    4    5    6  🟡7    8                               │
│   9   10   11   12   13   14   15                               │
│  ...                                                            │
└─────────────────────────────────────────────────────────────────┘
```

### 5.6 Expiration Actions

When a document is expiring or expired:

| Action | Description |
|--------|-------------|
| **View Document** | Open document detail to review coverage |
| **Update Document** | Replace with renewed document (keeps history) |
| **Set New Expiration** | Manually extend expiration date |
| **Snooze Reminder** | Delay reminder by 7 days |
| **Mark as Renewed** | Keep document, mark as renewed, enter new expiration |
| **Archive** | Move to archive (for expired, replaced documents) |

---

## 6. Document Detail View

### 6.1 Screen Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  ←                                              ✏️ Edit   ⋮     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                                                         │    │
│  │              [ DOCUMENT PREVIEW ]                       │    │
│  │                                                         │    │
│  │              Tap to view full screen                    │    │
│  │              Pinch to zoom                              │    │
│  │                                                         │    │
│  │                                                         │    │
│  │  ○ ○ ● ○  (page indicators for multi-page)             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  HVAC System Warranty                                           │
│  📋 Warranties & Manuals • System Warranty                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🟠 EXPIRING SOON                                        │    │
│  │ Expires in 12 days (January 27, 2026)                   │    │
│  │ [ Set Reminder ] [ Update Document ]                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  DETAILS                                                        │
│  ├── Brand                    Lennox                            │
│  ├── Model                    XC21                              │
│  ├── Serial Number            1234567890                        │
│  ├── Installation Date        Jan 27, 2022                      │
│  ├── Warranty Period          4 years                           │
│  ├── Expiration Date          Jan 27, 2026                      │
│  └── Installer                ABC Heating & Air                 │
│                                                                 │
│  LINKED ITEMS                                                   │
│  ├── 🔧 HVAC System (Home Profile)                              │
│  └── 📄 HVAC Installation Receipt                               │
│                                                                 │
│  NOTES                                                          │
│  └── "Covers compressor and parts. Labor included              │
│       first 2 years only. Call 1-800-XXX-XXXX for claims."     │
│                                                                 │
│  DOCUMENT INFO                                                  │
│  ├── Added                    Mar 15, 2024                      │
│  ├── Last Modified            Mar 15, 2024                      │
│  └── File Size                1.2 MB                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  [ 📤 Share ]  [ ⬇️ Download ]  [ 🗑️ Delete ]  [ ⋯ More ]      │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Document Preview Features

| Feature | Description |
|---------|-------------|
| **Full-screen view** | Tap preview to enter immersive mode |
| **Pinch to zoom** | Standard iOS/Android zoom gestures |
| **Page navigation** | Swipe left/right for multi-page docs |
| **Page thumbnails** | Bottom strip showing all pages |
| **Add page** | Button to append additional pages |
| **Rotate** | Rotate view (doesn't modify original) |
| **Share from preview** | Quick share while viewing |

### 6.3 Metadata Fields by Document Type

Each document type displays relevant fields:

**Warranty Documents:**
- Brand, Model, Serial Number
- Purchase Date, Purchase Price
- Warranty Period, Expiration Date
- Retailer/Installer
- Claim Phone Number

**Insurance Documents:**
- Carrier, Policy Number
- Coverage Amounts (Dwelling, Personal Property, Liability)
- Deductible
- Premium, Payment Frequency
- Effective Date, Expiration Date
- Agent Name, Agent Phone

**Maintenance Records:**
- Vendor/Contractor Name
- Service Date
- Service Type
- Cost (Labor, Parts, Total)
- Technician Name
- Next Service Recommended

**Permits:**
- Permit Number
- Issue Date
- Work Type
- Contractor
- Status (Open, Closed, Final)
- Final Inspection Date

### 6.4 Edit Mode

Tap "Edit" to modify document:

- All metadata fields become editable
- Can change category/document type
- Can add/remove pages
- Can crop/rotate pages
- Can add/edit notes
- "Save" or "Cancel" buttons appear

### 6.5 More Actions Menu

```
┌─────────────────────────────────────┐
│  Move to Category...                │
│  ──────────────────────────────     │
│  Duplicate Document                 │
│  ──────────────────────────────     │
│  Add to Home History Report         │
│  ──────────────────────────────     │
│  Print                              │
│  ──────────────────────────────     │
│  View OCR Text                      │
│  ──────────────────────────────     │
│  Document History                   │
└─────────────────────────────────────┘
```

---

## 7. Sharing & Export

### 7.1 Share Options

When user taps "Share" on a document:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Share Document                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🔗 Create Shareable Link                                       │
│     Generate a secure link anyone can view                      │
│                                                                 │
│  📧 Email                                                       │
│     Attach document to new email                                │
│                                                                 │
│  📤 Export PDF                                                  │
│     Download as PDF file                                        │
│                                                                 │
│  🖼️ Export Image                                                │
│     Download original image(s)                                  │
│                                                                 │
│  🖨️ Print                                                       │
│     Send to printer                                             │
│                                                                 │
│  📱 AirDrop (iOS)                                               │
│     Share to nearby devices                                     │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  👷 Share with Contractor                                       │
│     Quick share flow for professionals                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Shareable Link Options

```
┌─────────────────────────────────────────────────────────────────┐
│                     Create Shareable Link                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Link expires after:                                            │
│  [ 24 hours ] [ 7 days ✓ ] [ 30 days ] [ Never ]               │
│                                                                 │
│  ☐ Require password to view                                     │
│    Password: [____________]                                     │
│                                                                 │
│  ☐ Allow download                                               │
│                                                                 │
│  ☐ Notify me when viewed                                        │
│                                                                 │
│                        [ Create Link ]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Link Features:**
- Unique URL: `hometrack.app/doc/a1b2c3d4`
- View-only by default
- View count tracking
- Can be revoked anytime
- Access log (who viewed, when)

### 7.3 Share with Contractor Flow

Optimized flow for sharing with professionals:

1. **Select documents** (multi-select enabled)
2. **Enter recipient** (email or select from saved contractors)
3. **Add message** (optional)
4. **Set expiration** (default: 7 days)
5. **Send**

Recipient receives:
- Email with HomeTrack branding
- Custom message from homeowner
- Secure link to view documents
- Option to download (if enabled)

### 7.4 Bulk Export

From category view or search results:

1. Tap "Select" in header
2. Check documents to export
3. Tap "Export" action
4. Choose format:
   - **ZIP file**: Individual files in folder
   - **Merged PDF**: All documents combined
   - **With metadata**: Include CSV of all metadata

### 7.5 Print Functionality

- Native print dialog (AirPrint / Android Print)
- Option to include metadata as cover page
- Multi-page documents print in order
- Scaling options: Fit to page, Actual size

---

## 8. UI/UX Specifications

### 8.1 Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Speed First** | Document upload in <30 seconds |
| **Progressive Disclosure** | Essential fields first, details optional |
| **Recognition Over Recall** | Category icons, visual thumbnails, recent items |
| **Forgiveness** | Undo delete, edit anytime, no data loss |
| **Accessibility** | WCAG 2.1 AA, VoiceOver/TalkBack support |

### 8.2 Category Visual Identity

| Category | Icon | Primary Color | Background |
|----------|------|---------------|------------|
| Ownership | 🏠 | #1565C0 (Blue) | #E3F2FD |
| Insurance | 🛡️ | #7B1FA2 (Purple) | #F3E5F5 |
| Warranties | 📋 | #F57C00 (Orange) | #FFF3E0 |
| Maintenance | 🔧 | #388E3C (Green) | #E8F5E9 |
| Permits | 📜 | #D32F2F (Red) | #FFEBEE |
| Financial | 💰 | #00796B (Teal) | #E0F2F1 |

### 8.3 Expiration Badge Colors

| Status | Background | Text | Border |
|--------|------------|------|--------|
| Valid (>90 days) | #E8F5E9 | #2E7D32 | #81C784 |
| Expiring Soon (30-90) | #FFF8E1 | #F57F17 | #FFD54F |
| Imminent (<30) | #FFF3E0 | #E65100 | #FFB74D |
| Expired | #FFEBEE | #C62828 | #EF9A9A |

### 8.4 Document Card Design

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────┐                                                       │
│  │      │  Document Name                        [Status Badge]  │
│  │ 📄   │  Document Type • Category                             │
│  │      │  Date or key metadata                                 │
│  └──────┘                                                       │
│   40x50   Primary text: 16pt, semibold                          │
│   thumb   Secondary: 14pt, gray                                 │
│           Tertiary: 12pt, light gray                            │
└─────────────────────────────────────────────────────────────────┘

Card specs:
- Height: 72pt minimum
- Padding: 16pt horizontal, 12pt vertical
- Thumbnail: 40x50pt, rounded 4pt corners
- Touch target: Full card width
- Divider: 1pt, #E0E0E0
```

### 8.5 Empty States

**First-Time User (No Documents):**
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        📁                                       │
│                                                                 │
│              Your Document Vault is Ready                       │
│                                                                 │
│     Store warranties, receipts, permits, and more.              │
│     We'll keep them safe, organized, and searchable.            │
│                                                                 │
│              [ Add Your First Document ]                        │
│                                                                 │
│              What can I store? →                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Empty Category:**
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        📋                                       │
│                                                                 │
│              No Warranties Yet                                  │
│                                                                 │
│     Keep track of all your product and service warranties       │
│     so you never miss a claim.                                  │
│                                                                 │
│     Common documents:                                           │
│     • Appliance warranties                                      │
│     • HVAC system warranty                                      │
│     • Roof warranty                                             │
│     • Contractor workmanship guarantees                         │
│                                                                 │
│              [ Add Warranty Document ]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.6 Loading States

| State | Display |
|-------|---------|
| **Initial load** | Skeleton cards (shimmer effect) |
| **Search in progress** | Inline spinner with "Searching..." |
| **Document opening** | Full-screen spinner |
| **Upload in progress** | Progress bar with percentage |
| **OCR processing** | "Processing document..." with spinner |

### 8.7 Error States

| Error | Display | Action |
|-------|---------|--------|
| **Network offline** | Banner: "You're offline. Changes will sync when connected." | Dismiss |
| **Upload failed** | Toast: "Upload failed. Tap to retry." | Tap to retry |
| **Search failed** | Inline: "Search unavailable. Try again." | Retry button |
| **Document not found** | Full screen: "Document not found" | Back button |

---

## 9. Notifications

### 9.1 Notification Types

| Type | Trigger | Content |
|------|---------|---------|
| **Expiration Warning** | 90/30/7 days before | "[Document] expires in X days" |
| **Expired** | Day of expiration | "[Document] expired today" |
| **Upload Complete** | Background upload finishes | "[Document] uploaded successfully" |
| **Upload Failed** | Upload error | "Upload failed. Tap to retry." |
| **Weekly Digest** | Weekly (if enabled) | "You have X documents expiring soon" |
| **Document Shared** | Someone views shared link | "[Name] viewed [Document]" |

### 9.2 Expiration Notification Content

**90 Days Before:**
```
📋 Warranty Expiring Soon
Your Samsung Refrigerator warranty expires in 90 days (April 15, 2026).
Review coverage and note any issues to claim before expiration.
[View Document]
```

**30 Days Before:**
```
📋 Warranty Expiring Soon
Your Samsung Refrigerator warranty expires in 30 days (April 15, 2026).
Schedule any needed repairs while still covered.
[View Document] [Snooze 7 Days]
```

**7 Days Before:**
```
⚠️ Warranty Expiring This Week
Your Samsung Refrigerator warranty expires in 7 days (April 15, 2026).
Last chance to file any warranty claims!
[View Document] [Snooze]
```

**Day Of Expiration:**
```
🔴 Warranty Expired
Your Samsung Refrigerator warranty expired today.
[Update Document] [Archive]
```

### 9.3 Notification Settings

```
┌─────────────────────────────────────────────────────────────────┐
│  Notification Settings                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  EXPIRATION REMINDERS                                           │
│  ──────────────────────────────────────────────                 │
│  Enable Expiration Reminders              [Toggle ON]           │
│                                                                 │
│  Reminder Schedule                                              │
│  [ ] 90 days before                                             │
│  [✓] 30 days before                                             │
│  [✓] 7 days before                                              │
│  [✓] Day of expiration                                          │
│                                                                 │
│  Weekly Digest Email                      [Toggle OFF]          │
│  Receive weekly summary of upcoming expirations                 │
│                                                                 │
│  GENERAL                                                        │
│  ──────────────────────────────────────────────                 │
│  Upload Notifications                     [Toggle ON]           │
│  Share Activity                           [Toggle ON]           │
│                                                                 │
│  QUIET HOURS                                                    │
│  ──────────────────────────────────────────────                 │
│  Do Not Disturb                           [Toggle OFF]          │
│  From: 10:00 PM    To: 7:00 AM                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Error Handling & Edge Cases

### 10.1 Upload Scenarios

| Scenario | Behavior | User Message |
|----------|----------|--------------|
| Network failure during upload | Queue upload, retry automatically when connected | "Upload paused. Will resume when connected." |
| File too large (>25MB) | Block upload, offer to compress | "File exceeds 25MB. Compress and retry?" |
| Unsupported format | Block upload, show supported formats | "File type not supported. Try PDF, JPG, or PNG." |
| OCR processing fails | Save document, mark text as unavailable | "Document saved. Text search may be limited." |
| Storage quota exceeded (free tier) | Block upload, show upgrade prompt | "Storage full. Upgrade for unlimited storage." |
| Corrupted file | Block upload, suggest re-capture | "This file appears corrupted. Please try again." |
| Camera permission denied | Show settings prompt | "Camera access needed. Enable in Settings." |
| Photo library permission denied | Show settings prompt | "Photo access needed. Enable in Settings." |

### 10.2 Sync & Conflict Scenarios

| Scenario | Resolution | User Message |
|----------|------------|--------------|
| Edit on two devices simultaneously | Last write wins, keep version history | "Document updated from another device." |
| Offline edits + cloud changes | Show conflict resolution UI | "Conflict detected. Keep which version?" |
| Delete on one device while editing on another | Propagate delete, offer restore from trash | "Document deleted on another device. Restore?" |
| Long offline period | Full sync on reconnect | "Syncing X documents..." |

### 10.3 Edge Cases

| Case | Handling |
|------|----------|
| **Duplicate document detection** | Warn user if uploading very similar document to existing one |
| **Very long document name** | Truncate with ellipsis in list view, full name in detail view |
| **Expired share link accessed** | Show "Link expired" page with request new link option |
| **Invalid expiration date** | Prevent dates in the past for new documents |
| **Category deleted with documents** | Move documents to "Uncategorized" |
| **Account deleted** | 30-day grace period, then permanent deletion |
| **Shared document deleted** | Shared links become invalid, viewers see "no longer available" |

### 10.4 Data Recovery

| Feature | Implementation |
|---------|----------------|
| **Trash** | Deleted documents go to trash, auto-delete after 30 days |
| **Version History** | Keep last 5 versions of edited documents |
| **Account Recovery** | 30-day window to restore deleted account |
| **Export All** | Settings option to download complete archive (ZIP) |

---

## 11. Accessibility Requirements

### 11.1 Visual Accessibility

| Requirement | Implementation |
|-------------|----------------|
| **Color contrast** | All text meets WCAG 2.1 AA (4.5:1 minimum) |
| **Dynamic type** | Support iOS Dynamic Type and Android font scaling |
| **Color independence** | Never use color alone as indicator (always + icon/text) |
| **Dark mode** | Full dark mode support |
| **Touch targets** | Minimum 44x44pt touch targets |
| **Focus indicators** | Clear focus states for keyboard navigation |

### 11.2 Screen Reader Support

| Element | Accessibility Label Example |
|---------|----------------------------|
| Category card | "Warranties and Manuals. 12 documents. 2 expiring soon. Button." |
| Document card | "HVAC System Warranty. Expires in 12 days. System Warranty. Button." |
| Expiration badge | "Expiring soon. 12 days remaining." |
| Upload button | "Add new document. Button." |
| Search field | "Search documents. Text field." |
| Document preview | "Document preview. Page 1 of 3. Double tap to view full screen." |

### 11.3 Motor Accessibility

| Feature | Alternative |
|---------|-------------|
| Swipe to delete | Long press menu with delete option |
| Pinch to zoom | Zoom buttons in toolbar |
| Multi-page swipe | Page navigation buttons |
| Pull to refresh | Refresh button in header |

### 11.4 Cognitive Accessibility

| Feature | Implementation |
|---------|----------------|
| **Simple language** | Plain language for all instructions |
| **Consistent navigation** | Same patterns throughout app |
| **Clear feedback** | Confirmation for all destructive actions |
| **Progress indicators** | Always show where user is in multi-step flows |
| **Error recovery** | Clear error messages with specific actions |

---

## 12. Data Model

### 12.1 Document Object

```javascript
Document {
  id: string (UUID)
  userId: string (owner)
  
  // Basic Info
  name: string
  category: CategoryType
  documentType: string
  
  // Files
  files: [{
    id: string
    url: string (cloud storage URL)
    thumbnailUrl: string
    mimeType: string
    sizeBytes: number
    pageNumber: number
    ocrText: string (extracted text)
    ocrStatus: 'pending' | 'complete' | 'failed'
  }]
  
  // Metadata (varies by document type)
  metadata: {
    // Common
    documentDate: date
    notes: string
    
    // Warranty-specific
    brand: string
    model: string
    serialNumber: string
    purchaseDate: date
    purchasePrice: number
    warrantyPeriod: string
    expirationDate: date
    retailer: string
    
    // Insurance-specific
    carrier: string
    policyNumber: string
    coverageAmounts: object
    premium: number
    effectiveDate: date
    expirationDate: date
    agentName: string
    agentPhone: string
    
    // Maintenance-specific
    vendor: string
    serviceDate: date
    serviceType: string
    cost: number
    technicianName: string
    
    // ... other type-specific fields
  }
  
  // Expiration Tracking
  expirationDate: date | null
  expirationReminders: [{
    daysBeforeExpiration: number
    sent: boolean
    sentAt: date | null
  }]
  
  // Links
  linkedAppliance: string | null (appliance ID)
  linkedDocuments: [string] (document IDs)
  
  // Sharing
  shares: [{
    id: string
    createdAt: date
    expiresAt: date | null
    password: string | null
    allowDownload: boolean
    viewCount: number
    lastViewedAt: date | null
  }]
  
  // Audit
  createdAt: date
  updatedAt: date
  isArchived: boolean
  isDeleted: boolean
  deletedAt: date | null
}
```

### 12.2 Category Object

```javascript
Category {
  id: string
  userId: string | null (null for system categories)
  name: string
  icon: string (icon name)
  color: string (hex color)
  isSystem: boolean
  documentTypes: [string]
  sortOrder: number
  documentCount: number (computed)
  createdAt: date
}
```

### 12.3 Indexes Required

```
Documents:
- userId + category + createdAt (list by category)
- userId + expirationDate (expiration dashboard)
- userId + ocrText (full-text search)
- userId + isDeleted + deletedAt (trash cleanup)
- shares.id (share link lookup)

Categories:
- userId + sortOrder (category list)
```

---

## 13. Success Metrics

### 13.1 Engagement Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Documents uploaded (first 7 days) | 5+ | Count per user |
| Documents uploaded (first 30 days) | 10+ | Count per user |
| Users with all categories used | 30% | Users with 1+ doc in each |
| Return visits (weekly) | 40%+ | WAU / total users |
| Session duration | 3+ minutes | Average session length |

### 13.2 Feature Adoption Metrics

| Feature | Target Adoption | Measurement |
|---------|-----------------|-------------|
| Search usage | 40% weekly | Users who search / WAU |
| Expiration dates set | 50% of applicable | Docs with dates / total |
| Notifications enabled | 70% | Users with push enabled |
| Document shared | 10% of users | Users who've shared 1+ |
| Category customization | 5% | Users with custom categories |

### 13.3 Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Upload completion rate | 95%+ | Completed / started |
| OCR success rate | 98%+ | Successful / attempted |
| Search success rate | 80%+ | Searches with clicks |
| Document retrieval time | <10 sec | Time to find document |
| App crashes | <0.1% | Crashes / sessions |

### 13.4 Retention Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Day 1 retention | 50%+ | Users returning day 2 |
| Day 7 retention | 30%+ | Users returning week 2 |
| Day 30 retention | 20%+ | Users returning month 2 |
| Churn rate (monthly) | <10% | Lost users / total |

---

## 14. Implementation Phases

### Phase 1: Core Upload & Storage (Weeks 1-3)

**Goal:** Users can capture, categorize, and store documents.

- [ ] Camera capture with auto-edge detection
- [ ] Photo library import
- [ ] PDF file import
- [ ] Multi-page document support
- [ ] Cloud storage integration
- [ ] Category selection flow
- [ ] Basic metadata entry
- [ ] Background upload with progress

**Exit Criteria:** User can upload and view a document.

### Phase 2: Organization & Navigation (Weeks 4-5)

**Goal:** Users can find and manage their documents.

- [ ] Category grid home screen
- [ ] Category list views with sorting/filtering
- [ ] Document detail screen
- [ ] Full-screen document viewer with zoom
- [ ] Edit metadata functionality
- [ ] Delete with trash recovery
- [ ] Move between categories

**Exit Criteria:** User can browse, view details, and organize documents.

### Phase 3: Search & OCR (Weeks 6-7)

**Goal:** Users can search across all documents.

- [ ] OCR processing pipeline integration
- [ ] Full-text search implementation
- [ ] Search results UI with highlighting
- [ ] Filter chips and sort options
- [ ] Search index optimization
- [ ] Recent/suggested searches

**Exit Criteria:** User can find documents by searching content.

### Phase 4: Expiration Tracking (Weeks 8-9)

**Goal:** Users never miss an expiration.

- [ ] Expiration date input and storage
- [ ] Status badges (valid/expiring/expired)
- [ ] Expiration dashboard view
- [ ] Push notification scheduling
- [ ] Notification preferences
- [ ] Snooze and dismiss functionality
- [ ] Calendar view

**Exit Criteria:** User receives working expiration reminders.

### Phase 5: Sharing & Export (Week 10)

**Goal:** Users can share documents securely.

- [ ] Secure link generation
- [ ] Link expiration and revocation
- [ ] PDF export
- [ ] System share sheet integration
- [ ] Bulk export (ZIP)
- [ ] Print functionality
- [ ] Contractor share flow

**Exit Criteria:** User can share documents via secure link.

### Phase 6: Polish & Launch (Weeks 11-12)

**Goal:** Production-ready feature.

- [ ] Empty states and onboarding
- [ ] Error handling and edge cases
- [ ] Accessibility audit and fixes
- [ ] Performance optimization
- [ ] Analytics integration
- [ ] App Store assets
- [ ] Beta testing
- [ ] Bug fixes

**Exit Criteria:** Document Vault ready for public launch.

---

## Appendix A: Supported File Formats

| Format | Extensions | Max Size | Notes |
|--------|------------|----------|-------|
| PDF | .pdf | 25 MB | Native support, OCR applied |
| JPEG | .jpg, .jpeg | 25 MB | Auto-enhancement available |
| PNG | .png | 25 MB | Transparency preserved |
| HEIC | .heic | 25 MB | iOS native, converted for storage |
| WebP | .webp | 25 MB | Android native |

---

## Appendix B: OCR Language Support

Initial launch: **English only**

Future expansion:
- Spanish
- French  
- German
- Portuguese
- Italian

---

## Appendix C: Keyboard Shortcuts (Tablet/Desktop)

| Shortcut | Action |
|----------|--------|
| ⌘/Ctrl + N | New document |
| ⌘/Ctrl + F | Focus search |
| ⌘/Ctrl + , | Open settings |
| Delete/Backspace | Delete selected |
| Enter | Open selected document |
| Escape | Close modal/back |
| Arrow keys | Navigate list |

---

*End of Document Vault Feature Specification*
