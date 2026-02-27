# Software Requirements Specification — HomeTrack (Keystona)

*The Smart Way to Manage Your Home*

**MVP through v2.0 — Complete Product Specification**

**Version:** 1.0
**Date:** February 2026
**Prepared by:** Caleb (Founder & Product Owner)
**Status:** Active — Living Document

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [Functional Requirements — MVP (v1.0)](#3-functional-requirements--mvp-v10)
4. [Functional Requirements — v1.5 (Quick Wins)](#4-functional-requirements--v15-quick-wins)
5. [Functional Requirements — v2.0 (Major Enhancements)](#5-functional-requirements--v20-major-enhancements)
6. [Cross-Cutting Functional Requirements](#6-cross-cutting-functional-requirements)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [Technology Stack](#8-technology-stack)
9. [Data Model (Core Tables)](#9-data-model-core-tables)
10. [Release Plan & Success Metrics](#10-release-plan--success-metrics)
11. [Future Considerations (Not In Scope)](#11-future-considerations-not-in-scope)
12. [Appendices](#12-appendices)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) defines the complete functional and non-functional requirements for HomeTrack — a comprehensive home management platform. It serves as the authoritative source of truth for what the product does, why it exists, and how it should behave. This document is written to be directly actionable by both human developers and AI development agents.

### 1.2 Product Vision

HomeTrack was born from a real problem: the overwhelming experience of buying a home and trying to organize the mountain of paperwork, warranties, insurance policies, and appliance information that comes with it. There's no single place to keep it all together, no system that tells you what maintenance to do and when, and no way to quickly find critical information in an emergency.

> **Founder's Statement**
>
> "I had recently bought a house and was just trying to gather everything together because of how much paperwork it was to ingest when signing at closing and getting warranties, getting insurance policies, making sure to keep up to date with appliances." — Caleb, Founder

HomeTrack is the smart way to manage your home. It combines document storage, maintenance tracking, emergency preparedness, and home system monitoring into a single, mobile-first platform that helps homeowners stay organized from closing day forward.

### 1.3 Scope

This SRS covers the full product roadmap from MVP (v1.0) through v2.0, organized into three release phases:

- **MVP (v1.0)** — Core four pillars: Document Vault, Home Profile, Maintenance Calendar, Emergency Hub
- **v1.5 (Quick Wins)** — Weather alerts, Home Tour Checklist, Refinance Alerts, Project ROI Calculator, Plaid Mortgage Sync
- **v2.0 (Major Enhancements)** — Home History Report, Account Transfer, Before/After Gallery, Receipt Scanner, Home Inventory, Disclosure Checklist

> **Scope Decision: Home Value Tracking**
>
> Home Value Tracking (ATTOM API integration, equity calculator) is intentionally deferred from MVP. The core product focuses on practical, everyday homeowner needs — documents, maintenance, systems, and emergencies. Value tracking and analytics features will be revisited based on user feedback and demand.

### 1.4 Intended Audience

| Audience | How They Use This Document |
|----------|---------------------------|
| Caleb (Founder/Product Owner) | Source of truth for product decisions; ensures features match the original vision |
| AI Development Agents | Authoritative spec for implementation; agents should treat this as the requirement, not make assumptions |
| Future Developers / Contractors | Onboarding reference for understanding what the product does and why |

### 1.5 Business Context

HomeTrack is a lifestyle business focused on sustainable revenue and long-term ownership. The goal is not hyper-growth or acquisition — it's building a product that genuinely helps homeowners and generates reliable recurring revenue. Success is measured by users who get real value, not vanity metrics.

| Dimension | Decision |
|-----------|----------|
| Business Model | Freemium SaaS with Premium ($7.99/mo) and Family ($14.99/mo) tiers |
| Revenue Goal | Sustainable recurring revenue; lifestyle business |
| Target Market | US homeowners, primarily first-time buyers aged 28–42 |
| Growth Strategy | Organic growth via content, partnerships, referrals; paid ads supplementary |
| Feature Philosophy | Ship core value first, then add features users actually ask for |

### 1.6 Definitions & Acronyms

| Term | Definition |
|------|-----------|
| AVM | Automated Valuation Model — algorithmic home value estimate |
| CCPA | California Consumer Privacy Act |
| IECC | International Energy Conservation Code — defines US climate zones |
| MVP | Minimum Viable Product (v1.0) |
| OCR | Optical Character Recognition — extracting text from images/PDFs |
| RLS | Row Level Security — Supabase database access control |
| SRS | Software Requirements Specification (this document) |

---

## 2. Overall Description

### 2.1 Product Perspective

HomeTrack is a new, standalone product. It does not replace or extend an existing system. The platform consists of a mobile application (primary), a web application (secondary), and a shared backend. The mobile app is the primary experience; the web app provides a desktop-optimized companion for tasks like document management and report generation.

### 2.2 Target Users

**Primary: First-Time Homeowners**

Ages 28–42, household income $75K–$200K. Digital natives comfortable with subscription apps. Proactive about protecting their investment but anxious about "doing it wrong." They just closed on a home and are overwhelmed by paperwork, maintenance responsibilities, and unfamiliar systems.

**Secondary Segments**

| Segment | Key Need | Primary Features |
|---------|----------|-----------------|
| Move-Up Buyers | Document improvements for resale value | Document Vault, Maintenance Calendar, Home History Report (v2.0) |
| Empty Nesters | Organize decades of documents, prepare for downsizing | Document Vault, Home Profile |
| Small Landlords | Multi-property maintenance tracking | Family tier with multi-property support |
| Pre-Purchase Buyers | Evaluate properties during house hunting | Home Tour Checklist (v1.5, free) |

### 2.3 Product Features Summary

*Features are organized by release version. The MVP focuses on four core pillars that deliver immediate, practical value.*

**MVP (v1.0) — Core Four Pillars**

| Feature | One-Line Description | Free / Premium |
|---------|---------------------|----------------|
| Document Vault | Secure, searchable repository for all home documents with OCR and expiration tracking | Free (25 docs) / Premium (unlimited) |
| Home Profile | Complete digital record of property details, systems, and appliances with lifespan tracking | Free |
| Maintenance Calendar | Climate-aware maintenance scheduling with seasonal checklists and completion tracking | Free |
| Emergency Hub | Offline-capable emergency info: shutoff locations, contacts, insurance, procedures | Free |

**v1.5 — Quick Wins (2–3 Months Post-MVP)**

| Feature | One-Line Description | Free / Premium |
|---------|---------------------|----------------|
| Weather-Triggered Alerts | Proactive notifications based on weather forecasts to prevent damage | Premium |
| Home Tour Checklist | Interactive property evaluation tool for house hunters | Free (acquisition funnel) |
| Refinance Opportunity Alerts | Notifications when market conditions suggest refinancing benefits | Premium |
| Project ROI Calculator | Estimate return on improvement projects before investing | Premium |
| Plaid Mortgage Sync | Automatic mortgage balance sync via Plaid for equity tracking | Premium |

**v2.0 — Major Enhancements (4–6 Months Post-MVP)**

| Feature | One-Line Description | Free / Premium |
|---------|---------------------|----------------|
| Home History Report | Generate a "Carfax for homes" document for selling | Premium |
| Account Transfer | Transfer complete home history to new owner at sale | Premium |
| Before/After Gallery | Visual project documentation with side-by-side comparisons | Premium |
| Receipt Scanner | AI-powered receipt capture with auto-extraction of vendor, date, amount | Premium |
| Home Inventory | Room-by-room possession inventory for insurance documentation | Premium |
| Disclosure Checklist | State-specific seller disclosure requirements with completion tracking | Premium |

### 2.4 Design & Operating Constraints

| Constraint | Requirement | Rationale |
|-----------|-------------|-----------|
| Device Support | Must work on phones 3+ years old (iOS 15+, Android 10+) | Accessibility for all homeowners, not just those with new devices |
| Language | English-only for MVP; multilingual support planned for future | Focus resources on core experience first |
| Data Residency | All user data must remain in US-based servers | User trust, regulatory alignment |
| Privacy Compliance | CCPA-compliant from day one | California is a major market; sets the standard for all users |
| Offline Capability | Emergency Hub must function with zero internet connectivity | Emergencies often knock out power/internet |
| Platform Priority | Mobile-first (Flutter); web secondary (Next.js) | Homeowners need info on the go, not at a desk |

### 2.5 Assumptions & Dependencies

**Assumptions**

- Users own or are purchasing a home in the United States
- Users have a smartphone with a camera capable of photographing documents
- Users are willing to invest 15–30 minutes in initial setup (onboarding)
- Homeowners will engage with maintenance reminders if the tasks are relevant and actionable
- The combination of features (not any single feature) is the primary value driver

**External Dependencies**

| Dependency | Provider | Risk if Unavailable |
|-----------|----------|-------------------|
| OCR Processing | Google Cloud Vision API | Document search degraded; upload still works |
| Push Notifications | Firebase Cloud Messaging | Reminders delayed; in-app alerts still work |
| Property Data (future) | ATTOM API | Home Value Tracking unavailable; core features unaffected |
| Payments | RevenueCat + Stripe | New subscriptions blocked; existing features still work |
| Weather Data (v1.5) | NOAA/NWS API | Weather alerts unavailable; manual maintenance still works |
| Mortgage Sync (v1.5) | Plaid API | Manual balance entry fallback |

---

## 3. Functional Requirements — MVP (v1.0)

### 3.1 Document Vault

*The foundational feature of HomeTrack. A secure, organized, searchable repository for all home-related documents. Eliminates the chaos of paper files, scattered digital photos, and forgotten warranties.*

#### 3.1.1 Document Upload

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DV-001 | Users can upload documents via camera capture, photo library, or file import (PDF) | Must Have |
| DV-002 | Camera capture includes auto-edge detection and perspective correction | Should Have |
| DV-003 | Multi-page document scanning: users can capture multiple pages as one document | Must Have |
| DV-004 | Supported formats: PDF, JPG, PNG, HEIC | Must Have |
| DV-005 | Maximum file size: 25MB per document | Must Have |
| DV-006 | Upload progress indicator with ability to cancel | Must Have |
| DV-007 | Upload continues in background if user navigates away | Should Have |

#### 3.1.2 Document Organization

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DV-008 | Six pre-defined categories: Ownership, Insurance, Warranties & Manuals, Maintenance Records, Permits & Compliance, Financial Documents | Must Have |
| DV-009 | Users can create custom categories with user-defined names and icon selection | Should Have |
| DV-010 | Each document has a type within its category (e.g., "Appliance Warranty" under Warranties) | Must Have |
| DV-011 | Documents have category-specific metadata fields (e.g., policy number for insurance, serial number for warranties) | Must Have |
| DV-012 | Users can rename, re-categorize, and delete documents | Must Have |
| DV-013 | Free tier limited to 25 documents; Premium unlimited | Must Have |

#### 3.1.3 OCR Search

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DV-014 | All uploaded documents are processed via OCR (Google Cloud Vision API) to extract text | Must Have |
| DV-015 | Full-text search across all document content, names, and metadata | Must Have |
| DV-016 | Search results show document name, category, and matching text snippet | Must Have |
| DV-017 | Search returns results in under 2 seconds | Must Have |
| DV-018 | Free tier: basic search (name/category only); Premium: full OCR search | Must Have |

#### 3.1.4 Expiration Tracking

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DV-019 | Users can set expiration dates on any document (warranties, insurance policies, contracts) | Must Have |
| DV-020 | System sends push notification reminders at 90, 30, and 7 days before expiration | Must Have |
| DV-021 | Expiration dashboard shows all documents with upcoming expirations sorted by urgency | Must Have |
| DV-022 | Visual status indicators: Active (green), Expiring Soon (yellow/orange), Expired (red) | Must Have |
| DV-023 | Users can snooze or dismiss expiration reminders | Should Have |

#### 3.1.5 Document Viewing & Sharing

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DV-024 | In-app document preview without requiring external apps | Must Have |
| DV-025 | Pinch-to-zoom on document preview | Must Have |
| DV-026 | Share documents via secure link with optional expiration date and access controls | Should Have |
| DV-027 | Export/download individual documents or bulk export by category | Should Have |

### 3.2 Home Profile

*The central hub of HomeTrack — a comprehensive digital record of everything about your home. Captures property details, tracks every major system and appliance, and monitors their age against expected lifespan. Think of it as your home's medical record.*

#### 3.2.1 Property Information

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HP-001 | Capture core property details: address, square footage, year built, bedrooms, bathrooms, lot size, property type | Must Have |
| HP-002 | Property photo (exterior) for visual identification | Should Have |
| HP-003 | Purchase information: date, price, down payment | Should Have |
| HP-004 | Climate zone auto-detection from ZIP code (IECC zones) | Must Have |

#### 3.2.2 Systems Registry

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HP-005 | Track major home systems: HVAC, water heater, electrical panel, roof, plumbing, foundation, siding, windows, insulation | Must Have |
| HP-006 | For each system: brand, model, serial number, installation date, warranty info, photos | Must Have |
| HP-007 | Quick-add templates with pre-populated fields for common system types | Should Have |
| HP-008 | Brand autocomplete from curated list (Carrier, Lennox, Trane, Rheem, etc.) | Should Have |
| HP-009 | Adding a system auto-generates relevant maintenance tasks in the Maintenance Calendar | Must Have |

#### 3.2.3 Appliances Registry

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HP-010 | Track kitchen, laundry, and other appliances: brand, model, serial, purchase date, warranty | Must Have |
| HP-011 | Photo capture of appliance and model/serial number label | Must Have |
| HP-012 | Link appliances to warranty documents in the Document Vault | Must Have |
| HP-013 | Prompt to register warranty with manufacturer within 30 days of adding | Should Have |

#### 3.2.4 Lifespan Tracking

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HP-014 | Visual progress bars showing age vs. expected lifespan for each system/appliance (e.g., "Water heater: 9 of 12 years") | Must Have |
| HP-015 | Lifespan data sourced from NAHB standards (furnace: 15–20yr, AC: 10–15yr, water heater tank: 8–12yr, etc.) | Must Have |
| HP-016 | Status indicators: Healthy (green), Aging (yellow), End of Life (red) | Must Have |
| HP-017 | 5-year forecast view: what will likely need replacement in 1, 3, 5 years | Should Have |
| HP-018 | Users can override default lifespan values | Should Have |
| HP-019 | Replacement cost estimates for budgeting | Should Have |

### 3.3 Maintenance Calendar

*A smart maintenance scheduling system that provides climate-aware reminders and tracks completion of routine home care. The goal is to make proactive maintenance the default behavior, not an afterthought.*

#### 3.3.1 Task Generation & Scheduling

| Req ID | Requirement | Priority |
|--------|------------|----------|
| MC-001 | Auto-generate seasonal maintenance tasks based on home profile and climate zone | Must Have |
| MC-002 | Auto-generate system-specific tasks when systems are added to Home Profile (e.g., water heater → "Flush water heater" annually) | Must Have |
| MC-003 | Pre-built seasonal checklists: Spring, Summer, Fall, Winter | Must Have |
| MC-004 | Climate zone awareness: adjust task relevance and frequency by IECC zone (e.g., no winterize pipes for Zone 1) | Must Have |
| MC-005 | Users can create custom tasks with flexible recurrence: one-time, weekly, monthly, quarterly, annual | Must Have |
| MC-006 | Users can snooze or skip tasks with optional reason | Must Have |

#### 3.3.2 Task Completion & Documentation

| Req ID | Requirement | Priority |
|--------|------------|----------|
| MC-007 | Quick Complete: one-tap to mark a task done with auto-timestamp | Must Have |
| MC-008 | Detailed Complete: add date, who did it (DIY/contractor), cost, photos, notes | Must Have |
| MC-009 | Attach receipts or invoices from Document Vault to completed tasks | Should Have |
| MC-010 | Completed tasks logged to history with all captured details | Must Have |
| MC-011 | Recurring tasks auto-schedule next occurrence after completion | Must Have |
| MC-012 | Service history displayed on system detail view (from Home Profile) | Must Have |

#### 3.3.3 Notifications & Reminders

| Req ID | Requirement | Priority |
|--------|------------|----------|
| MC-013 | Push notification reminders at 7 days and 1 day before due date | Must Have |
| MC-014 | Overdue task notifications at 1 day and 7 days past due | Must Have |
| MC-015 | Configurable notification timing (default: weekends 9–10 AM) | Should Have |
| MC-016 | Users can disable notifications per-task or globally | Must Have |

#### 3.3.4 Calendar Views & UI

| Req ID | Requirement | Priority |
|--------|------------|----------|
| MC-017 | Filter tabs: All, Overdue, This Week, This Month, By System | Must Have |
| MC-018 | Color-coded task status: Overdue (red), Due Today (orange), Due Soon (yellow), Scheduled (blue), Completed (green) | Must Have |
| MC-019 | Task cards show: category icon, task name, due info, quick complete button | Must Have |
| MC-020 | DIY vs. Professional indicator on each task | Should Have |
| MC-021 | Home Health Score: aggregate metric reflecting maintenance completion rate | Should Have |

### 3.4 Emergency Hub

*Centralized, offline-capable emergency information. When disaster strikes — burst pipe, gas leak, electrical fire — homeowners need instant access to shutoff locations, emergency contacts, and insurance details, even without internet. This is HomeTrack's key differentiator: no competitor executes offline emergency access well.*

#### 3.4.1 Utility Shutoff Guides

| Req ID | Requirement | Priority |
|--------|------------|----------|
| EH-001 | Document water main shutoff: location, photo(s), valve type, turn direction, tools needed | Must Have |
| EH-002 | Document gas shutoff: meter location, house-side valve, safety warnings, gas wrench reminder | Must Have |
| EH-003 | Document electrical panel: location photo, main breaker identification, circuit directory | Must Have |
| EH-004 | Document individual water valves: toilets, sinks, washing machine, water heater | Should Have |
| EH-005 | Step-by-step shutoff instructions written for someone unfamiliar with the home | Must Have |
| EH-006 | All shutoff data and photos available offline | Must Have |

#### 3.4.2 Emergency Contacts

| Req ID | Requirement | Priority |
|--------|------------|----------|
| EH-007 | Store emergency contacts: plumber, electrician, HVAC tech, general contractor, insurance agent | Must Have |
| EH-008 | One-tap calling from contact cards | Must Have |
| EH-009 | Business hours display when available | Should Have |
| EH-010 | Contact categories: Urgent (plumber, electrician), Maintenance (HVAC, pest), Insurance, Utilities | Must Have |
| EH-011 | Contacts available offline | Must Have |

#### 3.4.3 Insurance Quick Reference

| Req ID | Requirement | Priority |
|--------|------------|----------|
| EH-012 | Store homeowner's insurance policy number, provider, agent contact | Must Have |
| EH-013 | Claims phone number prominently displayed | Must Have |
| EH-014 | Link to full policy document in Document Vault | Should Have |
| EH-015 | Insurance info available offline | Must Have |

#### 3.4.4 Offline Architecture

| Req ID | Requirement | Priority |
|--------|------------|----------|
| EH-016 | All Emergency Hub data cached locally in compressed format (max 500KB each) | Must Have |
| EH-017 | Data syncs with cloud on app open when online | Must Have |
| EH-018 | High-contrast emergency mode UI for low-light/stress situations | Should Have |
| EH-019 | Emergency Hub loads and displays in under 1 second, including offline | Must Have |

---

## 4. Functional Requirements — v1.5 (Quick Wins)

*High-value features targeting 2–3 months post-MVP. These extend core capabilities and drive Premium conversions. Build order: Plaid Mortgage Sync → Refinance Alerts → Weather Alerts → Project ROI Calculator → Home Tour Checklist.*

### 4.1 Weather-Triggered Alerts

| Req ID | Requirement | Priority |
|--------|------------|----------|
| WA-001 | Monitor NOAA/NWS API for weather events affecting user's property location | Must Have |
| WA-002 | Alert types: Freeze Warning, Severe Storm, Hurricane Watch, Heat Wave, Post-Storm | Must Have |
| WA-003 | Each alert includes actionable checklist of protection steps | Must Have |
| WA-004 | Alerts link to relevant Emergency Hub data (e.g., freeze alert links to water shutoff) | Must Have |
| WA-005 | Auto-create follow-up maintenance tasks (e.g., "Inspect roof after storm") | Should Have |
| WA-006 | Climate zone awareness: don't send freeze alerts in Zone 1 (Miami) | Must Have |
| WA-007 | Premium-only feature | Must Have |

### 4.2 Home Tour Checklist

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HT-001 | Interactive checklist for evaluating properties during house hunting | Must Have |
| HT-002 | Sections: Exterior, Interior, Systems, Red Flags | Must Have |
| HT-003 | Photo capture per checklist item | Must Have |
| HT-004 | Save multiple properties for comparison | Must Have |
| HT-005 | Side-by-side comparison view of toured properties | Should Have |
| HT-006 | Export to PDF for sharing with inspector or agent | Should Have |
| HT-007 | After purchase: convert checklist into Home Profile | Should Have |
| HT-008 | Free feature (top-of-funnel acquisition tool) | Must Have |

### 4.3 Refinance Opportunity Alerts

| Req ID | Requirement | Priority |
|--------|------------|----------|
| RA-001 | Alert when mortgage rates drop >0.5% below user's rate | Must Have |
| RA-002 | Alert when equity reaches 20% (PMI elimination opportunity) | Must Have |
| RA-003 | Alert when equity reaches 30%+ (HELOC eligibility) | Should Have |
| RA-004 | Alert when ARM adjustment date is approaching | Should Have |
| RA-005 | Rate data sourced from Freddie Mac PMMS (free, weekly) | Must Have |
| RA-006 | Premium-only feature | Must Have |

### 4.4 Project ROI Calculator

| Req ID | Requirement | Priority |
|--------|------------|----------|
| ROI-001 | Users input planned improvement type and estimated cost | Must Have |
| ROI-002 | System returns estimated ROI based on Cost vs. Value Report data | Must Have |
| ROI-003 | Results adjusted by region | Should Have |
| ROI-004 | Premium-only feature | Must Have |

### 4.5 Plaid Mortgage Sync

| Req ID | Requirement | Priority |
|--------|------------|----------|
| PL-001 | Connect mortgage account via Plaid Liabilities API for automatic balance sync | Must Have |
| PL-002 | Read-only access — cannot move money or make changes | Must Have |
| PL-003 | Manual entry fallback if Plaid connection fails or lender unsupported | Must Have |
| PL-004 | User can disconnect at any time; stored tokens deleted immediately | Must Have |
| PL-005 | Premium-only feature | Must Have |

---

## 5. Functional Requirements — v2.0 (Major Enhancements)

*Major features targeting 4–6 months post-MVP. These deliver the "Carfax for homes" promise and create network effects. Build order: Before/After Gallery → Receipt Scanner → Home History Report → Account Transfer → Home Inventory → Disclosure Checklist.*

### 5.1 Home History Report

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HR-001 | Generate a comprehensive PDF report documenting the home's complete history | Must Have |
| HR-002 | Report sections: Property Overview, System Inventory, Maintenance Timeline, Improvements, Investment Summary, Active Warranties | Must Have |
| HR-003 | Data auto-populated from Home Profile, Maintenance Calendar, Document Vault | Must Have |
| HR-004 | Completeness score showing data quality before generating | Should Have |
| HR-005 | Customizable: seller can include/exclude sections and choose what costs to display | Must Have |
| HR-006 | Share via PDF download, web link, or QR code | Must Have |
| HR-007 | Premium-only feature | Must Have |

### 5.2 Account Transfer

| Req ID | Requirement | Priority |
|--------|------------|----------|
| AT-001 | Seller initiates transfer from within the app | Must Have |
| AT-002 | Buyer receives email invitation to claim the home's history | Must Have |
| AT-003 | Transfers: property details, system inventory, maintenance history, emergency hub data | Must Have |
| AT-004 | Optional transfers: documents (seller chooses which), contractor contacts | Must Have |
| AT-005 | Never transfers: seller's personal info, home value history | Must Have |
| AT-006 | Seller retains data export access for 30 days post-transfer | Must Have |
| AT-007 | Premium-only feature | Must Have |

### 5.3 Before/After Gallery

| Req ID | Requirement | Priority |
|--------|------------|----------|
| BA-001 | Create projects with name, category, start date, budget | Must Have |
| BA-002 | Upload before, progress, and after photos | Must Have |
| BA-003 | Interactive slider comparison view (before/after side-by-side) | Must Have |
| BA-004 | Link permits, receipts, and contractor info to projects | Should Have |
| BA-005 | Projects feed into Home History Report | Must Have |
| BA-006 | Free: 3 projects; Premium: unlimited | Must Have |

### 5.4 Receipt Scanner

| Req ID | Requirement | Priority |
|--------|------------|----------|
| RS-001 | Camera-based receipt capture with auto-edge detection and crop | Must Have |
| RS-002 | AI extraction of: vendor, date, total amount, line items | Must Have |
| RS-003 | Auto-categorization based on vendor (Home Depot → Materials) | Should Have |
| RS-004 | User reviews and confirms/edits extracted data before saving | Must Have |
| RS-005 | Link receipt to maintenance task or improvement project | Must Have |
| RS-006 | Premium-only feature | Must Have |

### 5.5 Home Inventory

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HI-001 | Room-by-room inventory of possessions for insurance purposes | Must Have |
| HI-002 | Per item: photo, description, brand, model, purchase date, purchase price, estimated current value | Must Have |
| HI-003 | Receipt/proof of purchase attachment | Should Have |
| HI-004 | Total inventory value calculation | Must Have |
| HI-005 | Export for insurance company submission | Must Have |
| HI-006 | Premium-only feature | Must Have |

### 5.6 Disclosure Checklist

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DC-001 | State-specific seller disclosure requirements loaded by state selection | Must Have |
| DC-002 | Interactive checklist with completion tracking | Must Have |
| DC-003 | Link relevant documents from vault to each disclosure item | Should Have |
| DC-004 | Flag items requiring attention or additional documentation | Must Have |
| DC-005 | Export summary for real estate agent or attorney review | Should Have |
| DC-006 | Premium-only feature | Must Have |

---

## 6. Cross-Cutting Functional Requirements

### 6.1 Authentication & User Management

| Req ID | Requirement | Priority |
|--------|------------|----------|
| AUTH-001 | Email/password authentication via Supabase Auth | Must Have |
| AUTH-002 | Google OAuth login | Must Have |
| AUTH-003 | Apple Sign-In (required for iOS App Store) | Must Have |
| AUTH-004 | Magic link (passwordless) login option | Should Have |
| AUTH-005 | JWT-based session management | Must Have |

### 6.2 Household Members

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HM-001 | Property owner can invite household members via email | Must Have |
| HM-002 | Household members have full access — same permissions as the owner (view, edit, upload, complete tasks) | Must Have |
| HM-003 | Free tier: 1 user; Premium: 2 users; Family: 5 users | Must Have |
| HM-004 | Owner can remove household members at any time | Must Have |
| HM-005 | If owner deletes account, household members lose access to that property | Must Have |

### 6.3 Account Deletion & Data Export

| Req ID | Requirement | Priority |
|--------|------------|----------|
| DEL-001 | Users can request account deletion from within the app | Must Have |
| DEL-002 | Before deletion begins, users are offered a full data export (all documents, photos, and structured data) | Must Have |
| DEL-003 | 30-day grace period after deletion request: account is deactivated but data retained | Must Have |
| DEL-004 | Users can reactivate during the 30-day grace period | Must Have |
| DEL-005 | After 30 days, all user data is permanently and irreversibly deleted | Must Have |
| DEL-006 | Deletion includes: documents, photos, profile data, maintenance history, emergency hub data | Must Have |
| DEL-007 | Deletion confirmation email sent with reactivation link and grace period end date | Must Have |

### 6.4 Subscription & Payments

| Req ID | Requirement | Priority |
|--------|------------|----------|
| PAY-001 | Three tiers: Free, Premium ($7.99/mo), Family ($14.99/mo) | Must Have |
| PAY-002 | Annual discount: Premium ($59.99/yr), Family ($119.99/yr) | Must Have |
| PAY-003 | In-app purchase via Apple/Google native payment systems | Must Have |
| PAY-004 | RevenueCat manages subscription state across platforms | Must Have |
| PAY-005 | 7-day free trial for Premium (no credit card required for free tier) | Must Have |
| PAY-006 | Upgrade prompts at feature limits (non-intrusive) | Must Have |
| PAY-007 | Downgrade preserves data but locks premium features | Must Have |

### 6.5 Home Health Score

| Req ID | Requirement | Priority |
|--------|------------|----------|
| HS-001 | Composite score (0–100) based on three pillars: Maintenance (50%), Documents (30%), Emergency (20%) | Must Have |
| HS-002 | Visual dashboard with three concentric rings representing each pillar | Must Have |
| HS-003 | Score updates automatically as users complete tasks, upload documents, and set up emergency info | Must Have |
| HS-004 | Color-coded thresholds: Green (71–100), Amber (40–70), Red (0–39) | Must Have |
| HS-005 | First 30 days: score displays "—" while user populates data | Must Have |
| HS-006 | Insights generated based on score drivers (e.g., "Upload your insurance policy to improve your score by 8%") | Should Have |
| HS-007 | Score visible on Home tab dashboard as the hero card | Must Have |
| HS-008 | Free feature — scores drive engagement and upsell via document completion percentage | Must Have |

### 6.6 Notifications

| Req ID | Requirement | Priority |
|--------|------------|----------|
| NOT-001 | Push notifications via Firebase Cloud Messaging (iOS and Android) | Must Have |
| NOT-002 | Notification categories: Maintenance Reminders, Expiration Alerts, Weather Alerts (v1.5), Financial Alerts (v1.5) | Must Have |
| NOT-003 | Users can configure notification preferences per category | Must Have |
| NOT-004 | All notification sends check user preferences before delivery | Must Have |
| NOT-005 | Batch notifications to avoid overwhelming users | Should Have |
| NOT-006 | Use local time zones for all scheduling — never UTC for user-facing times | Must Have |

---

## 7. Non-Functional Requirements

### 7.1 Performance

| Req ID | Requirement | Target |
|--------|------------|--------|
| PERF-001 | App cold start time | Under 3 seconds on 3-year-old devices |
| PERF-002 | Document search results | Under 2 seconds |
| PERF-003 | Emergency Hub load time (including offline) | Under 1 second |
| PERF-004 | Document upload (5MB image) | Under 10 seconds on 4G |
| PERF-005 | Screen transitions / navigation | Under 300ms |
| PERF-006 | Maintenance Calendar rendering | Under 1 second for 100+ tasks |
| PERF-007 | API response times (95th percentile) | Under 500ms |

### 7.2 Security

| Req ID | Requirement | Implementation |
|--------|------------|---------------|
| SEC-001 | Data at rest encryption | AES-256 (Supabase/AWS default) |
| SEC-002 | Data in transit encryption | TLS 1.3 |
| SEC-003 | API security | JWT tokens with Supabase RLS policies |
| SEC-004 | File access control | Signed URLs with expiration |
| SEC-005 | Row Level Security | Users can only access their own data (enforced at database level) |
| SEC-006 | Payment data | Never stored; handled entirely by RevenueCat/Stripe |
| SEC-007 | Document storage | User-isolated storage buckets with access policies |

### 7.3 Privacy & Compliance

| Req ID | Requirement | Priority |
|--------|------------|----------|
| PRIV-001 | CCPA-compliant from day one: right to know, right to delete, right to opt-out | Must Have |
| PRIV-002 | All user data stored on US-based servers | Must Have |
| PRIV-003 | Clear, plain-language privacy policy explaining what data is collected and why | Must Have |
| PRIV-004 | No selling of user data to third parties | Must Have |
| PRIV-005 | Data export available in standard formats (PDF, ZIP) on user request | Must Have |
| PRIV-006 | Third-party data sharing (Plaid, OCR) requires explicit user consent | Must Have |
| PRIV-007 | Analytics (PostHog) configured to anonymize PII | Must Have |

### 7.4 Reliability & Availability

| Req ID | Requirement | Target |
|--------|------------|--------|
| REL-001 | System uptime (cloud services) | 99.5% monthly |
| REL-002 | Emergency Hub availability (offline) | 100% — must work without any network |
| REL-003 | Data backup frequency | Daily automated backups with 30-day retention |
| REL-004 | Recovery time objective (RTO) | Under 4 hours |
| REL-005 | Recovery point objective (RPO) | Under 24 hours |
| REL-006 | Graceful degradation | Core features work if external APIs (OCR, weather, property data) are unavailable |

### 7.5 Scalability

| Scale Phase | Users | Infrastructure | Estimated Monthly Cost |
|------------|-------|---------------|----------------------|
| Phase 1: MVP | 0–10,000 | Single Supabase instance, Supabase Storage | $675–$2,400 |
| Phase 2: Growth | 10K–100K | Supabase + Upstash Redis, connection pooling | $2,400–$10,000 |
| Phase 3: Scale | 100K–1M+ | AWS RDS PostgreSQL + read replicas, ElastiCache, S3 | $10,000+ |

### 7.6 Accessibility

| Req ID | Requirement | Priority |
|--------|------------|----------|
| A11Y-001 | WCAG 2.1 AA compliance | Must Have |
| A11Y-002 | Screen reader support with semantic labels on all interactive elements | Must Have |
| A11Y-003 | Minimum touch target size: 44x44 points | Must Have |
| A11Y-004 | Color contrast ratios meeting AA standards (4.5:1 for text, 3:1 for large text) | Must Have |
| A11Y-005 | Support for system font size preferences (Dynamic Type on iOS, font scaling on Android) | Must Have |
| A11Y-006 | Emergency Hub: high-contrast mode for low-light emergency situations | Should Have |

### 7.7 Maintainability

| Req ID | Requirement | Priority |
|--------|------------|----------|
| MAINT-001 | Modular architecture: each feature is an independent module with clean interfaces | Must Have |
| MAINT-002 | Versioned database migrations with rollback scripts | Must Have |
| MAINT-003 | Feature flags (PostHog) for gradual rollouts and kill switches | Must Have |
| MAINT-004 | Comprehensive error tracking via Sentry with crash reporting | Must Have |
| MAINT-005 | Audit columns on all database tables: created_at, updated_at, deleted_at (soft deletes) | Must Have |

---

## 8. Technology Stack

*Technology decisions prioritize familiar tools with clear migration paths for scaling. No premature optimization — ship fast with Supabase, migrate to AWS as needed.*

### 8.1 Frontend

| Platform | Technology | Rationale |
|----------|-----------|-----------|
| Mobile (iOS & Android) | Flutter / Dart | Single codebase, excellent performance, strong ecosystem |
| Web | Next.js / React / TypeScript | Desktop-optimized UX, SEO support, server-side rendering |

> **Key Decision:** Mobile and web share the same backend API but have independent frontends. The web app is desktop-optimized, not a carbon copy of mobile.

### 8.2 Backend

| Component | Technology | Rationale |
|----------|-----------|-----------|
| Database | Supabase (PostgreSQL) | Managed PostgreSQL, built-in auth, real-time subscriptions, easy migration path to AWS RDS |
| Authentication | Supabase Auth | Integrated with database, supports OAuth, RLS integration |
| Serverless Functions | Supabase Edge Functions (Deno) | Handle external API calls, webhooks, OCR triggers, cron jobs |
| Real-time | Supabase Realtime | Cross-device sync for document and property updates |
| File Storage | Supabase Storage | User-isolated buckets with signed URL access, migration path to S3 |

### 8.3 Third-Party Services

| Service | Provider | Purpose |
|---------|----------|---------|
| Payments | RevenueCat + Stripe | Cross-platform subscription management |
| Analytics | PostHog | Product analytics, feature flags, session replay, A/B testing |
| Push Notifications | Firebase Cloud Messaging | Cross-platform push for reminders and alerts |
| OCR Processing | Google Cloud Vision API | Document text extraction for search |
| Error Tracking | Sentry | Crash reporting and performance monitoring |
| Email | Resend or SendGrid | Transactional emails and expiration reminders |
| Property Data (future) | ATTOM API | Home valuation estimates |
| Weather Data (v1.5) | NOAA/NWS API | Weather-triggered alerts (free) |
| Mortgage Data (v1.5) | Plaid Liabilities API | Automatic mortgage balance sync |
| Receipt OCR (v2.0) | AWS Textract or Google Document AI | Structured receipt data extraction |

### 8.4 Design System

| Element | Specification |
|---------|--------------|
| Brand Name | Keystona |
| Theme | Premium Home |
| Primary Color | Deep Navy (#1B2A4A) |
| Accent Color | Gold (#C9A84C) |
| Background | Warm Off-White (#FAF8F5) |
| Headline Font | Outfit (Bold) |
| Body Font | Plus Jakarta Sans (Regular) |
| Mobile Typography | SF Pro Display (headings), SF Pro Text (body) |
| Icon Style | Custom Keystona icon set |
| Design Principle | Clean, functional interfaces focused on practical utility over decoration |

---

## 9. Data Model (Core Tables)

*Primary database tables and their relationships. All tables use UUID primary keys, include audit columns (created_at, updated_at, deleted_at), and are protected by Row Level Security.*

| Table | Purpose | Key Relationships |
|-------|---------|------------------|
| profiles | User info, subscription tier | Extends Supabase auth.users |
| properties | Home details, address, purchase info | Belongs to user (user_id) |
| documents | Document metadata, file path, OCR text, expiration | Belongs to property |
| systems | HVAC, roof, water heater — major home systems | Belongs to property |
| appliances | Kitchen, laundry, other appliances | Belongs to property |
| maintenance_tasks | Scheduled and completed maintenance | Belongs to property, optionally linked to system |
| emergency_info | Shutoff locations, emergency contacts, insurance | Belongs to property |
| household_members | Users invited to a property | Links users to properties |

> **RLS Pattern:** Every table with user data enforces Row Level Security: users can only SELECT, INSERT, UPDATE, or DELETE rows where auth.uid() matches the user_id or where the property_id belongs to a property they own or are a household member of.

---

## 10. Release Plan & Success Metrics

### 10.1 Development Timeline

| Phase | Duration | Deliverables |
|-------|----------|-------------|
| Design & Planning | 2–3 weeks | Wireframes, data models, API contracts, technical architecture |
| MVP Core Build | 8–10 weeks | Document Vault, Home Profile, Maintenance Calendar, Auth |
| Emergency Hub | 2–3 weeks | Offline-capable emergency features, utility shutoff documentation |
| Testing & Polish | 2–3 weeks | Beta testing, bug fixes, performance optimization, App Store prep |
| MVP Launch | Week 16–20 | App Store release, initial marketing |
| v1.5 Features | 8–12 weeks | Weather alerts, Home Tour Checklist, Refinance Alerts, Plaid integration |
| v2.0 Features | 12–16 weeks | Home History Report, Account Transfer, Before/After Gallery, Receipt Scanner |

### 10.2 MVP Success Metrics (First 90 Days)

| Metric | Target | Why It Matters |
|--------|--------|---------------|
| Premium Conversion Rate | 5–10% | Monetization validation |
| Registered Users | 5,000 | Initial traction |
| Documents Uploaded per User | 10+ in first month | Core engagement |
| Emergency Hub Completion Rate | 70%+ | Differentiating value |
| Weekly Active Users (WAU) | 30%+ of registered | Retention signal |
| Maintenance Tasks Completed | 2+ per user/month | Habit formation |
| App Store Rating | 4.5+ stars | Quality indicator |
| NPS Score | 40+ | Product-market fit |

### 10.3 Monetization Targets

| Metric | Target |
|--------|--------|
| Free to Premium Conversion | 5–10% |
| Trial to Paid Conversion | 40%+ |
| Average Revenue Per User (ARPU) | $6–$8/month |
| Customer Lifetime Value (LTV) | $150–$200 |
| Monthly Churn Rate | <10% |

### 10.4 Retention Targets

| Metric | Target |
|--------|--------|
| Day 1 Retention | 50%+ (return day 2) |
| Day 7 Retention | 30%+ (return week 2) |
| Day 30 Retention | 20%+ (return month 2) |

---

## 11. Future Considerations (Not In Scope)

*These features are intentionally deferred. They may be built based on user feedback and demand, but are not committed to any release timeline.*

| Feature | Description | When to Revisit |
|---------|------------|----------------|
| Home Value Tracking | AVM-based home valuation, equity calculator, value history charts | When users ask for financial insights or when pursuing premium conversion levers |
| Smart Home Integration | IoT device monitoring for automated maintenance triggers | When smart home adoption reaches critical mass among our users |
| AI Maintenance Advisor | ML-based predictions for system failures and cost optimization | When we have enough maintenance data to train useful models |
| Neighborhood Intelligence | Area-specific maintenance tips, contractor ratings, community features | When user density in specific areas justifies the investment |
| Multi-Language Support | Spanish, French, and other language support | When international or non-English-speaking US market segments show demand |
| B2B / Enterprise | Property management company tools, real estate agent portal | When inbound interest from professionals reaches critical volume |
| v3.0 Smart Features | Predictive maintenance, automated service booking, contractor marketplace | 9–12+ months post-MVP at earliest |

> **Feature Philosophy:** HomeTrack ships core value first, then adds features users actually ask for. We don't build features because competitors have them or because they sound impressive in a pitch deck. Every feature must solve a real problem that real users have told us about.

---

## 12. Appendices

### 12.1 Appendix A: Pricing Tiers Detail

| Feature | Free | Premium ($7.99/mo) | Family ($14.99/mo) |
|---------|------|-------------------|-------------------|
| Properties | 1 | 1 | Up to 3 |
| Document Storage | 25 documents | Unlimited | Unlimited |
| OCR Search | Basic (name/category) | Full-text OCR | Full-text OCR |
| Maintenance Calendar | ✓ | ✓ | ✓ |
| Emergency Hub | ✓ | ✓ | ✓ |
| Household Members | 1 | 2 | 5 |
| Home Value Tracking | — | Future feature | Future feature |
| Weather Alerts (v1.5) | — | ✓ | ✓ |
| Home History Report (v2.0) | — | ✓ | ✓ |
| Priority Support | — | ✓ | ✓ |

### 12.2 Appendix B: System Lifespan Data (NAHB Standards)

| System / Appliance | Expected Lifespan |
|-------------------|------------------|
| Furnace (Gas) | 15–20 years |
| Central Air Conditioning | 10–15 years |
| Heat Pump | ~16 years |
| Water Heater (Tank) | 8–12 years |
| Water Heater (Tankless) | 20+ years |
| Asphalt Shingle Roof | 20–25 years |
| Dishwasher | 9–10 years |
| Refrigerator | ~13 years |
| Washer/Dryer | 10–13 years |
| Garbage Disposal | 8–15 years |
| Electrical Panel | 25–40 years |
| Windows | 15–30 years |

### 12.3 Appendix C: Document Retention Guidelines

| Document Category | Recommended Retention |
|------------------|----------------------|
| Ownership Documents | Entire ownership + 7 years after sale |
| Insurance Policies | Current + 3 years of prior policies |
| Warranties | Until expiration + 1 year |
| Maintenance Records | Entire ownership (valuable for resale) |
| Permits & Inspections | Permanent (transfers with property) |
| Financial / Tax | 7 years minimum (IRS guideline) |
| Appliance Manuals | Until appliance replaced |

---

**End of Software Requirements Specification**

*HomeTrack — The Smart Way to Manage Your Home*

Version 1.0 — February 2026
