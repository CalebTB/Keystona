# Home Profile
## Complete Feature Specification

**HomeTrack MVP — Core Feature #2**  
*Version 1.0 | January 2026*

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Property Information](#2-property-information)
3. [Systems Registry](#3-systems-registry)
4. [Appliances Registry](#4-appliances-registry)
5. [Lifespan Tracking](#5-lifespan-tracking)
6. [Photo Documentation](#6-photo-documentation)
7. [User Flows](#7-user-flows)
8. [UI/UX Specifications](#8-uiux-specifications)
9. [Integration Points](#9-integration-points)
10. [Data Model](#10-data-model)
11. [Success Metrics](#11-success-metrics)
12. [Implementation Phases](#12-implementation-phases)

---

## 1. Feature Overview

### 1.1 Purpose

The Home Profile is the central hub of HomeTrack—a comprehensive digital record of everything about your home. It captures property details, tracks every major system and appliance, monitors their age against expected lifespan, and provides visual documentation. Think of it as your home's permanent medical record.

### 1.2 Problem Statement

| Pain Point | Impact |
|------------|--------|
| Homeowners don't know their home's systems | Can't answer basic questions about HVAC age, roof type, water heater capacity |
| No central record of what's installed | Hours wasted searching for model numbers during service calls |
| Systems fail unexpectedly | No visibility into age = no proactive replacement planning |
| Lost when selling | Can't provide buyers with comprehensive home information |
| Service providers ask questions owners can't answer | Delayed repairs, wrong parts ordered |

### 1.3 Solution

A structured digital profile that:

- **Captures** all property details in one place
- **Catalogs** every system and appliance with full specifications
- **Tracks** age vs. expected lifespan with visual indicators
- **Documents** everything with photos
- **Connects** to maintenance records and warranties
- **Exports** beautifully for selling or insurance

### 1.4 Core Value Propositions

| Value | How We Deliver |
|-------|----------------|
| **Know your home inside out** | Complete catalog of every system and appliance |
| **Never be caught off guard** | Lifespan tracking shows what's aging |
| **Answer any question instantly** | Model numbers, install dates, specs at your fingertips |
| **Plan and budget proactively** | See what needs replacement in 1, 3, 5 years |
| **Impress buyers when selling** | Professional home profile exports |
| **Speed up service calls** | Share system info with contractors instantly |

### 1.5 Success Metrics

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Property details completion | 80%+ | Basic engagement |
| Systems registered (first 30 days) | 5+ | Core value adoption |
| Appliances registered | 8+ | Comprehensive usage |
| Photo documentation rate | 60%+ of items | Visual value realized |
| Profile views per month | 3+ | Ongoing utility |
| Lifespan alerts engagement | 40%+ click-through | Proactive planning |

---

## 2. Property Information

### 2.1 Overview

The foundation of the Home Profile—basic property details that every homeowner should know and have documented.

### 2.2 Property Details Fields

#### Basic Information

| Field | Type | Required | Source Options |
|-------|------|----------|----------------|
| **Street Address** | Text | Yes | Manual entry, GPS auto-detect |
| **Unit/Apt Number** | Text | No | Manual entry |
| **City** | Text | Yes | Auto-populated from address |
| **State** | Dropdown | Yes | Auto-populated from address |
| **ZIP Code** | Text | Yes | Auto-populated from address |
| **Country** | Dropdown | Yes | Default: United States |

#### Property Characteristics

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| **Property Type** | Dropdown | Yes | Single Family, Condo, Townhouse, Multi-Family (2-4), Manufactured, Other |
| **Year Built** | Number | Yes | 4-digit year, validated 1800-current |
| **Square Footage** | Number | Recommended | Living area, numeric only |
| **Lot Size** | Number + Unit | No | Acres or Square Feet |
| **Stories** | Dropdown | Recommended | 1, 1.5, 2, 2.5, 3, 3+, Split Level |
| **Bedrooms** | Number | Recommended | 0-20 range |
| **Bathrooms** | Number | Recommended | Supports half baths (1.5, 2.5, etc.) |
| **Garage** | Dropdown | No | None, 1-Car, 2-Car, 3-Car, 4+Car, Carport |
| **Basement** | Dropdown | No | None, Unfinished, Partially Finished, Fully Finished |
| **Foundation Type** | Dropdown | No | Slab, Crawl Space, Basement, Pier & Beam, Mixed |

#### Construction Details

| Field | Type | Required | Options |
|-------|------|----------|---------|
| **Exterior Material** | Multi-select | No | Vinyl Siding, Wood Siding, Brick, Stone, Stucco, Fiber Cement, Aluminum, Mixed |
| **Roof Type** | Dropdown | Recommended | Asphalt Shingle, Metal, Tile, Slate, Wood Shake, Flat/Built-Up, TPO/EPDM |
| **Roof Age** | Year or Age | Recommended | Year installed or "X years old" |
| **Window Type** | Dropdown | No | Single Pane, Double Pane, Triple Pane, Mixed |
| **Window Frame** | Dropdown | No | Wood, Vinyl, Aluminum, Fiberglass, Mixed |

#### Utilities & Services

| Field | Type | Required | Options |
|-------|------|----------|---------|
| **Water Source** | Dropdown | Recommended | Municipal, Well, Both |
| **Sewer Type** | Dropdown | Recommended | Municipal Sewer, Septic System, Cesspool |
| **Electric Provider** | Text | No | Company name |
| **Gas Provider** | Text | No | Company name, or "No Gas Service" |
| **Internet Provider** | Text | No | Company name |
| **Trash Service** | Text | No | Company name |
| **HOA Name** | Text | No | If applicable |
| **HOA Contact** | Phone/Email | No | If applicable |

#### Location & Lot Details

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| **Parcel Number** | Text | No | From property tax records |
| **Legal Description** | Text | No | From deed |
| **Zoning** | Text | No | Residential, Commercial, etc. |
| **Flood Zone** | Dropdown | No | X, A, AE, V, VE, Unknown |
| **Fire Zone** | Dropdown | No | Low, Moderate, High, Very High, Unknown |
| **Climate Zone** | Auto | Auto | IECC zone from ZIP code |

### 2.3 Property Photo Gallery

Exterior and property photos organized by view:

| Photo Type | Description | Recommended |
|------------|-------------|-------------|
| **Front Exterior** | Street-facing view of home | Yes |
| **Rear Exterior** | Backyard view | Yes |
| **Left Side** | Side view | No |
| **Right Side** | Side view | No |
| **Aerial/Drone** | Overhead view if available | No |
| **Lot/Landscaping** | Yard, gardens, outdoor features | No |
| **Garage/Driveway** | Parking and exterior storage | No |
| **Additional** | Pool, deck, outbuildings, etc. | No |

### 2.4 Auto-Population Options

To reduce data entry friction:

| Source | Data Available | Implementation |
|--------|----------------|----------------|
| **Address Lookup** | City, State, ZIP, County | Google Places API |
| **Public Records** | Year built, sq ft, beds, baths, lot size | ATTOM API |
| **Climate Zone** | IECC climate zone | ZIP code lookup table |
| **Flood Zone** | FEMA flood zone | FEMA API |
| **Previous Listing** | Property details from past sale | MLS data (future) |

**User Flow for Auto-Population:**

```
1. User enters address
2. System looks up available data
3. Modal appears: "We found some information about your property"
4. Display found data with checkboxes
5. User confirms/edits each field
6. "Confirm" saves all selected data
```

---

## 3. Systems Registry

### 3.1 Overview

Major home systems are the backbone of the property—HVAC, electrical, plumbing, roofing, and more. Each system has detailed tracking including specifications, installation info, warranty status, and lifespan monitoring.

### 3.2 System Categories

```
Home Systems
├── 🌡️ HVAC (Heating, Ventilation, Air Conditioning)
│   ├── Furnace / Heating System
│   ├── Air Conditioning
│   ├── Heat Pump
│   ├── Ductwork
│   ├── Thermostat
│   └── Air Quality (Humidifier, Dehumidifier, Air Purifier)
│
├── 💧 Plumbing
│   ├── Water Heater
│   ├── Water Softener
│   ├── Water Filtration
│   ├── Sump Pump
│   ├── Well Pump
│   ├── Septic System
│   ├── Main Water Line
│   └── Sewer/Drain Line
│
├── ⚡ Electrical
│   ├── Electrical Panel
│   ├── Generator
│   ├── Solar Panel System
│   ├── Battery Storage
│   └── EV Charger
│
├── 🏠 Structure
│   ├── Roof
│   ├── Foundation
│   ├── Siding/Exterior
│   ├── Windows
│   ├── Exterior Doors
│   ├── Garage Door
│   └── Deck/Patio
│
├── 🔒 Safety & Security
│   ├── Smoke Detectors
│   ├── Carbon Monoxide Detectors
│   ├── Security System
│   ├── Fire Sprinklers
│   └── Radon Mitigation
│
└── 🌊 Pool & Spa (if applicable)
    ├── Pool Equipment
    ├── Pool Heater
    └── Hot Tub / Spa
```

### 3.3 System Detail Fields

#### Universal Fields (All Systems)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| **System Name** | Auto + Custom | Yes | Auto-generated, user can customize |
| **Category** | Dropdown | Yes | From system categories |
| **System Type** | Dropdown | Yes | Specific type within category |
| **Status** | Dropdown | Yes | Active, Inactive, Needs Repair, Replaced |
| **Installation Date** | Date/Year | Recommended | Month/Year or just Year |
| **Expected Lifespan** | Auto + Override | Auto | Pre-populated, user can adjust |
| **Location** | Text | No | "Basement", "Garage", "Attic", etc. |
| **Notes** | Text | No | Free-form notes |

#### HVAC Systems

**Furnace / Heating System:**

| Field | Type | Notes |
|-------|------|-------|
| Fuel Type | Dropdown | Gas, Electric, Oil, Propane, Wood, Geothermal |
| Brand | Text + Autocomplete | Common brands suggested |
| Model Number | Text | From unit label |
| Serial Number | Text | From unit label |
| BTU Rating | Number | Heating capacity |
| AFUE Rating | Number | Efficiency percentage |
| Installation Date | Date | Month/Year |
| Installer/Contractor | Text | Company name |
| Warranty Expiration | Date | Link to warranty document |

**Air Conditioning:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Central, Window, Mini-Split, Portable |
| Brand | Text + Autocomplete | |
| Model Number | Text | |
| Serial Number | Text | |
| Tonnage | Dropdown | 1.5, 2, 2.5, 3, 3.5, 4, 5 tons |
| SEER Rating | Number | Efficiency rating |
| Refrigerant Type | Dropdown | R-410A, R-22, R-32 |
| Installation Date | Date | |
| Condenser Location | Text | "Side yard", "Backyard", etc. |

**Heat Pump:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Air Source, Ground Source, Ductless Mini-Split |
| Brand | Text | |
| Model Number | Text | |
| Tonnage | Dropdown | |
| SEER Rating | Number | Cooling efficiency |
| HSPF Rating | Number | Heating efficiency |
| Installation Date | Date | |

**Thermostat:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Manual, Programmable, Smart |
| Brand | Text | Nest, Ecobee, Honeywell, etc. |
| Model | Text | |
| Smart Home Integration | Multi-select | Google Home, Alexa, Apple HomeKit |
| Installation Date | Date | |

#### Plumbing Systems

**Water Heater:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Tank (Gas), Tank (Electric), Tankless (Gas), Tankless (Electric), Heat Pump, Solar |
| Brand | Text | |
| Model Number | Text | |
| Serial Number | Text | |
| Capacity | Number + Unit | Gallons (tank) or GPM (tankless) |
| Energy Factor | Number | Efficiency rating |
| First Hour Rating | Number | For tank units |
| Location | Text | Garage, Basement, Utility Closet, etc. |
| Venting Type | Dropdown | Atmospheric, Power Vent, Direct Vent, N/A |
| Installation Date | Date | |
| Anode Rod Last Replaced | Date | Maintenance tracking |

**Water Softener:**

| Field | Type | Notes |
|-------|------|-------|
| Brand | Text | |
| Model | Text | |
| Grain Capacity | Number | Softening capacity |
| Regeneration Type | Dropdown | Timer, Demand-Initiated |
| Salt Type | Dropdown | Pellets, Crystals, Block |
| Installation Date | Date | |

**Sump Pump:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Submersible, Pedestal |
| Brand | Text | |
| Horsepower | Dropdown | 1/4, 1/3, 1/2, 3/4, 1 HP |
| Backup Battery | Boolean | Yes/No |
| Backup Type | Dropdown | Battery, Water-Powered, None |
| Location | Text | |
| Installation Date | Date | |

**Septic System:**

| Field | Type | Notes |
|-------|------|-------|
| Tank Material | Dropdown | Concrete, Fiberglass, Plastic |
| Tank Capacity | Number | Gallons |
| Drain Field Type | Dropdown | Conventional, Chamber, Mound, etc. |
| Last Pumped | Date | |
| Pumping Interval | Dropdown | Every 1/2/3/4/5 years |
| Installation Date | Date | |
| Septic Company | Text | Service provider |

#### Electrical Systems

**Electrical Panel:**

| Field | Type | Notes |
|-------|------|-------|
| Brand | Text | |
| Amperage | Dropdown | 100, 150, 200, 400 amps |
| Panel Type | Dropdown | Main Breaker, Main Lug, Sub-Panel |
| Number of Spaces | Number | Available breaker slots |
| Location | Text | |
| Age/Installation Date | Date | |
| Known Issues | Text | Federal Pacific, Zinsco, etc. |

**Generator:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Portable, Standby (Natural Gas), Standby (Propane), Standby (Diesel) |
| Brand | Text | |
| Model | Text | |
| Wattage | Number | Power output |
| Fuel Type | Dropdown | |
| Automatic Transfer Switch | Boolean | |
| Installation Date | Date | |
| Last Service Date | Date | |

**Solar Panel System:**

| Field | Type | Notes |
|-------|------|-------|
| System Size | Number | kW |
| Number of Panels | Number | |
| Panel Brand | Text | |
| Inverter Brand | Text | |
| Inverter Type | Dropdown | String, Micro, Power Optimizer |
| Ownership | Dropdown | Owned, Leased, PPA |
| Installation Date | Date | |
| Installer | Text | |
| Monitoring System | Text | App/portal name |
| Annual Production | Number | kWh estimate |

#### Structure Systems

**Roof:**

| Field | Type | Notes |
|-------|------|-------|
| Material | Dropdown | Asphalt Shingle, Metal, Tile, Slate, Wood Shake, Flat/TPO/EPDM |
| Brand/Product | Text | GAF Timberline, Owens Corning, etc. |
| Color | Text | |
| Layers | Dropdown | 1, 2 (re-roofed over existing) |
| Installation Date | Date | |
| Warranty Type | Dropdown | Manufacturer, Workmanship, Extended |
| Warranty Length | Number | Years |
| Warranty Transferable | Boolean | |
| Installer | Text | |
| Square Footage | Number | Roof area |
| Last Inspection | Date | |

**Windows:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Single Pane, Double Pane, Triple Pane |
| Frame Material | Dropdown | Wood, Vinyl, Aluminum, Fiberglass, Composite |
| Brand | Text | |
| Gas Fill | Dropdown | None, Argon, Krypton |
| Low-E Coating | Boolean | |
| Approximate Count | Number | Total windows |
| Installation Date | Date | Or "Original to home" |
| Warranty Expiration | Date | |

**Garage Door:**

| Field | Type | Notes |
|-------|------|-------|
| Material | Dropdown | Steel, Wood, Aluminum, Fiberglass, Composite |
| Insulated | Boolean | |
| Brand | Text | |
| Size | Text | "16x7", "9x7", etc. |
| Opener Brand | Text | |
| Opener Model | Text | |
| Smart Enabled | Boolean | |
| Installation Date | Date | |

#### Safety Systems

**Smoke Detectors:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Battery, Hardwired, Hardwired + Battery Backup |
| Detection Type | Dropdown | Ionization, Photoelectric, Dual |
| Brand | Text | |
| Smart/Connected | Boolean | |
| Number Installed | Number | |
| Installation Date | Date | |
| Last Battery Replacement | Date | |
| Interconnected | Boolean | All alarms sound together |

**Security System:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Professional Monitored, Self-Monitored, Local Alarm Only |
| Provider | Text | ADT, SimpliSafe, Ring, etc. |
| Panel Brand | Text | |
| Installation Date | Date | |
| Components | Multi-select | Door Sensors, Motion Sensors, Glass Break, Cameras, Doorbell |
| Smart Home Integration | Multi-select | |

### 3.4 System Status Indicators

| Status | Badge | Meaning |
|--------|-------|---------|
| **Active** | 🟢 | System is operational |
| **Needs Attention** | 🟡 | Approaching end of life or service needed |
| **Needs Repair** | 🟠 | Known issue requiring repair |
| **Inactive** | ⚪ | System not currently in use |
| **Replaced** | 🔵 | Archived - replaced by newer system |

---

## 4. Appliances Registry

### 4.1 Overview

Track every major appliance in the home with full specifications, purchase info, warranty status, and maintenance needs.

### 4.2 Appliance Categories

```
Home Appliances
├── 🍳 Kitchen
│   ├── Refrigerator
│   ├── Freezer (Standalone)
│   ├── Range/Oven
│   ├── Cooktop
│   ├── Wall Oven
│   ├── Microwave
│   ├── Dishwasher
│   ├── Garbage Disposal
│   ├── Range Hood
│   ├── Trash Compactor
│   └── Wine Cooler
│
├── 🧺 Laundry
│   ├── Washing Machine
│   ├── Dryer
│   └── Washer/Dryer Combo
│
├── 🧊 Climate & Comfort
│   ├── Portable AC
│   ├── Dehumidifier
│   ├── Humidifier
│   ├── Air Purifier
│   └── Space Heater
│
├── 🧹 Cleaning
│   ├── Central Vacuum
│   ├── Robot Vacuum
│   └── Vacuum Cleaner
│
├── 💨 Outdoor
│   ├── Grill (Built-in)
│   ├── Outdoor Refrigerator
│   └── Outdoor Kitchen Equipment
│
└── 🏠 Other
    ├── Water Dispenser
    ├── Ice Maker (Standalone)
    ├── Safe
    └── Custom Appliance
```

### 4.3 Appliance Detail Fields

#### Universal Fields (All Appliances)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| **Appliance Name** | Auto + Custom | Yes | "Kitchen Refrigerator", "Master Bath Washer" |
| **Category** | Dropdown | Yes | Kitchen, Laundry, etc. |
| **Appliance Type** | Dropdown | Yes | Specific type |
| **Brand** | Text + Autocomplete | Recommended | Common brands suggested |
| **Model Number** | Text | Recommended | From label/tag |
| **Serial Number** | Text | Recommended | From label/tag |
| **Color/Finish** | Dropdown | No | Stainless, Black, White, Custom |
| **Purchase Date** | Date | Recommended | |
| **Purchase Price** | Currency | No | For insurance/records |
| **Retailer** | Text | No | Where purchased |
| **Warranty Expiration** | Date | Recommended | Link to warranty doc |
| **Location** | Text | Recommended | "Kitchen", "Garage", "Basement" |
| **Status** | Dropdown | Yes | Active, Needs Repair, Replaced, Stored |
| **Notes** | Text | No | Free-form |

#### Kitchen Appliances

**Refrigerator:**

| Field | Type | Notes |
|-------|------|-------|
| Configuration | Dropdown | French Door, Side-by-Side, Top Freezer, Bottom Freezer, Counter-Depth |
| Capacity | Number | Cubic feet |
| Ice Maker | Dropdown | None, Built-in, External |
| Water Dispenser | Boolean | |
| Smart Features | Boolean | WiFi connected |
| Dimensions (H×W×D) | Text | For reference |
| Energy Star | Boolean | |
| Installation Date | Date | If different from purchase |

**Range/Oven:**

| Field | Type | Notes |
|-------|------|-------|
| Fuel Type | Dropdown | Gas, Electric, Dual Fuel, Induction |
| Configuration | Dropdown | Freestanding, Slide-in, Drop-in |
| Oven Type | Dropdown | Conventional, Convection, Steam, Combo |
| Burners/Elements | Number | Count |
| Oven Capacity | Number | Cubic feet |
| Self-Cleaning | Dropdown | None, Self-Clean, Steam Clean |
| Double Oven | Boolean | |

**Dishwasher:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Built-in, Portable, Drawer |
| Capacity | Dropdown | Standard, Compact |
| Decibel Rating | Number | Noise level |
| Cycles | Number | Number of wash cycles |
| Third Rack | Boolean | |
| Energy Star | Boolean | |

**Garbage Disposal:**

| Field | Type | Notes |
|-------|------|-------|
| Horsepower | Dropdown | 1/3, 1/2, 3/4, 1, 1.25 HP |
| Feed Type | Dropdown | Continuous, Batch |
| Brand | Text | InSinkErator, Moen, etc. |

#### Laundry Appliances

**Washing Machine:**

| Field | Type | Notes |
|-------|------|-------|
| Type | Dropdown | Top Load, Front Load |
| Capacity | Number | Cubic feet |
| Steam Feature | Boolean | |
| WiFi Connected | Boolean | |
| Energy Star | Boolean | |
| Stacked/Stackable | Dropdown | Standalone, Stacked, Stackable |

**Dryer:**

| Field | Type | Notes |
|-------|------|-------|
| Fuel Type | Dropdown | Electric, Gas |
| Capacity | Number | Cubic feet |
| Venting | Dropdown | Vented, Ventless (Condenser), Ventless (Heat Pump) |
| Steam Feature | Boolean | |
| WiFi Connected | Boolean | |
| Energy Star | Boolean | |

### 4.4 Quick-Add Templates

For common appliances, offer pre-configured templates:

```
┌─────────────────────────────────────────────────────────────────┐
│  Quick Add Appliance                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  KITCHEN ESSENTIALS                                             │
│  [+ Refrigerator] [+ Range/Oven] [+ Dishwasher] [+ Microwave]  │
│                                                                 │
│  LAUNDRY                                                        │
│  [+ Washer] [+ Dryer] [+ Washer/Dryer Combo]                   │
│                                                                 │
│  OTHER COMMON                                                   │
│  [+ Garbage Disposal] [+ Water Heater] [+ Garage Door Opener]  │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  [+ Custom Appliance]                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.5 Barcode/Model Lookup (Future Enhancement)

- Scan barcode or model number label
- Auto-populate brand, model, specifications
- Link to manual PDF if available
- Pull expected lifespan data

---

## 5. Lifespan Tracking

### 5.1 Overview

The Lifespan Tracking system is a **key differentiator**—it transforms passive inventory into proactive planning. Users see at a glance what's aging, what's approaching end-of-life, and can budget for replacements.

### 5.2 Expected Lifespan Data

Based on NAHB (National Association of Home Builders) research and industry standards:

#### HVAC Systems

| System | Expected Lifespan | Factors Affecting Lifespan |
|--------|-------------------|---------------------------|
| Furnace (Gas) | 15-20 years | Maintenance, usage, quality |
| Furnace (Electric) | 20-30 years | Less mechanical wear |
| Central AC | 10-15 years | Climate, maintenance |
| Heat Pump | 10-15 years | Usage intensity |
| Ductwork | 25-40 years | Material, maintenance |
| Thermostat | 10-15 years | Type (smart may be less) |
| Humidifier (Whole-home) | 10-15 years | Water quality |

#### Plumbing Systems

| System | Expected Lifespan | Factors Affecting Lifespan |
|--------|-------------------|---------------------------|
| Water Heater (Tank) | 8-12 years | Water quality, maintenance |
| Water Heater (Tankless) | 20+ years | Water quality, descaling |
| Water Softener | 10-15 years | Water hardness, usage |
| Sump Pump | 7-10 years | Usage frequency |
| Well Pump | 10-15 years | Usage, water quality |
| Septic Tank | 25-30 years | Material, maintenance |
| Copper Pipes | 50+ years | Water chemistry |
| PEX Pipes | 40-50 years | UV exposure, chlorine |

#### Electrical Systems

| System | Expected Lifespan | Factors Affecting Lifespan |
|--------|-------------------|---------------------------|
| Electrical Panel | 25-40 years | Load, quality |
| Wiring (Copper) | 50-70 years | Insulation condition |
| Standby Generator | 20-30 years | Maintenance, usage |
| Solar Panels | 25-30 years | Quality, environment |
| Solar Inverter | 10-15 years | Type, quality |
| EV Charger | 15-25 years | Usage |

#### Structure

| System | Expected Lifespan | Factors Affecting Lifespan |
|--------|-------------------|---------------------------|
| Asphalt Shingle Roof | 20-30 years | Climate, quality, ventilation |
| Metal Roof | 40-70 years | Material, coating |
| Tile Roof | 50-100 years | Type, installation |
| Vinyl Siding | 40-60 years | UV exposure, climate |
| Wood Siding | 20-40 years | Maintenance, climate |
| Windows (Vinyl) | 20-40 years | Quality, exposure |
| Windows (Wood) | 30+ years | Maintenance |
| Exterior Door | 20-30 years | Material, exposure |
| Garage Door | 15-30 years | Material, usage |
| Deck (Pressure Treated) | 10-15 years | Climate, maintenance |
| Deck (Composite) | 25-30 years | Quality |

#### Appliances

| Appliance | Expected Lifespan | Factors Affecting Lifespan |
|-----------|-------------------|---------------------------|
| Refrigerator | 10-15 years | Usage, maintenance |
| Freezer | 10-20 years | Usage |
| Range (Gas) | 15-17 years | Usage |
| Range (Electric) | 13-15 years | Usage |
| Dishwasher | 9-11 years | Usage, water quality |
| Microwave | 9-10 years | Usage |
| Garbage Disposal | 10-12 years | Usage, what's disposed |
| Range Hood | 14 years | Usage |
| Washing Machine | 10-14 years | Usage |
| Dryer (Electric) | 13-14 years | Usage |
| Dryer (Gas) | 13-14 years | Usage |

### 5.3 Lifespan Status Calculation

```
Remaining Life % = (Expected Lifespan - Current Age) / Expected Lifespan × 100

Status Thresholds:
├── 🟢 Healthy      : >50% life remaining
├── 🟡 Aging        : 25-50% life remaining  
├── 🟠 End of Life  : 0-25% life remaining
└── 🔴 Past Due     : <0% (exceeded expected lifespan)
```

### 5.4 Lifespan Display

#### Individual Item View

```
┌─────────────────────────────────────────────────────────────────┐
│  🌡️ Furnace (Gas)                                    🟡 Aging  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Lennox XC21 • Installed March 2015                             │
│                                                                 │
│  AGE: 10 years, 10 months                                       │
│                                                                 │
│  ████████████████████░░░░░░░░░░  65% of expected life           │
│                                                                 │
│  Expected Lifespan: 15-20 years                                 │
│  Estimated Replacement: 2030-2035                               │
│  Estimated Cost: $4,000-8,000                                   │
│                                                                 │
│  [View Details] [Schedule Service] [Link Warranty]              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Progress Bar Visualization

```
Healthy (>50%)
██████████████████████████████████████░░░░░░░░░░░░  75%
└── Green fill

Aging (25-50%)
██████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░  40%
└── Yellow fill

End of Life (0-25%)
████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  15%
└── Orange fill

Past Due (<0%)
██████████████████████████████████████████████████  110%
└── Red fill, exceeds bar
```

### 5.5 Lifespan Dashboard

Aggregate view of all systems and appliances by status:

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Lifespan Tracker                                     ⚙️       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  OVERVIEW                                                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │   12    │ │    4    │ │    2    │ │    1    │               │
│  │ 🟢      │ │ 🟡      │ │ 🟠      │ │ 🔴      │               │
│  │ Healthy │ │ Aging   │ │End Life │ │Past Due │               │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘               │
│                                                                 │
│  🔴 NEEDS ATTENTION (1)                            [View All →] │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 💧 Water Heater           12 years old (8-12 expected)  │    │
│  │    █████████████████████████████████████████ 120%       │    │
│  │    Consider replacement soon                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🟠 APPROACHING END OF LIFE (2)                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🍳 Dishwasher             8 years old (9-11 expected)   │    │
│  │    ██████████████████████████████████░░░░░░ 80%         │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🧺 Washing Machine        10 years old (10-14 expected) │    │
│  │    █████████████████████████████░░░░░░░░░░ 75%          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  🟡 AGING (4)                                      [View All →] │
│  └── Furnace, AC Unit, Refrigerator, Range                      │
│                                                                 │
│  🟢 HEALTHY (12)                                   [View All →] │
│  └── All other systems and appliances                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.6 Replacement Cost Estimates

Provide ballpark replacement costs to help with budgeting:

| Item | Typical Replacement Cost Range |
|------|-------------------------------|
| Furnace | $3,000 - $8,000 |
| Central AC | $3,500 - $7,500 |
| Heat Pump | $4,500 - $10,000 |
| Water Heater (Tank) | $800 - $2,500 |
| Water Heater (Tankless) | $1,500 - $4,500 |
| Asphalt Roof (avg home) | $8,000 - $15,000 |
| Windows (whole home) | $10,000 - $30,000 |
| Refrigerator | $1,000 - $3,500 |
| Washer/Dryer Set | $1,500 - $3,500 |
| Dishwasher | $500 - $1,500 |
| Garage Door + Opener | $1,000 - $3,000 |

*Displayed as ranges with disclaimer: "Costs vary by region, brand, and complexity. Get quotes for accurate pricing."*

### 5.7 5-Year Replacement Forecast

```
┌─────────────────────────────────────────────────────────────────┐
│  5-Year Replacement Forecast                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Based on current age and expected lifespans, you may need      │
│  to budget for these replacements:                              │
│                                                                 │
│  2026 (This Year)                          Est: $1,500-3,000    │
│  ├── 💧 Water Heater (overdue)             $800-2,500           │
│                                                                 │
│  2027                                      Est: $1,000-2,500    │
│  ├── 🍳 Dishwasher                         $500-1,500           │
│  └── 🧺 Washing Machine                    $500-1,000           │
│                                                                 │
│  2028                                      Est: $0              │
│  └── No items expected                                          │
│                                                                 │
│  2029                                      Est: $1,000-3,500    │
│  └── 🍳 Refrigerator                       $1,000-3,500         │
│                                                                 │
│  2030                                      Est: $3,000-8,000    │
│  └── 🌡️ Furnace                            $3,000-8,000         │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  5-YEAR TOTAL ESTIMATE              $6,500 - $17,000            │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  💡 Tip: Set aside ~$2,000/year for home maintenance            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Photo Documentation

### 6.1 Overview

Photos are essential for insurance, service calls, and selling. The Home Profile makes it easy to capture and organize photos of systems, appliances, labels, and locations.

### 6.2 Photo Types per Item

| Photo Type | Purpose | Example |
|------------|---------|---------|
| **Overview** | Show full unit/system | Full water heater in context |
| **Model Label** | Capture specifications | Close-up of model/serial plate |
| **Location** | Document where it is | Show it's in garage, basement, etc. |
| **Condition** | Current state | Any wear, damage, issues |
| **Installation** | Document install work | Permits, contractor work |
| **Maintenance** | Service documentation | Filter changes, repairs |

### 6.3 Photo Capture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Add Photo to: Water Heater                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  What type of photo?                                            │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │     📷      │  │     🏷️      │  │     📍      │              │
│  │  Overview   │  │ Model Label │  │  Location   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │     🔍      │  │     🔧      │  │     📄      │              │
│  │ Condition   │  │ Maintenance │  │   Other     │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                 │
│  [📷 Take Photo]  [🖼️ Choose from Library]                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Model Label Capture

Specialized flow for capturing model/serial labels:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                         │    │
│  │                    [ CAMERA VIEW ]                      │    │
│  │                                                         │    │
│  │         ┌─────────────────────────────┐                 │    │
│  │         │   Position label in box    │                 │    │
│  │         │                             │                 │    │
│  │         │   MODEL: ___________        │                 │    │
│  │         │   SERIAL: ___________       │                 │    │
│  │         │                             │                 │    │
│  │         └─────────────────────────────┘                 │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  💡 Tip: Make sure text is clear and in focus                   │
│                                                                 │
│                      [ 📷 Capture ]                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

After Capture:
┌─────────────────────────────────────────────────────────────────┐
│  We detected the following information:                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Brand:         Rheem         [Edit]                            │
│  Model:         XG50T06EC36U1 [Edit]                            │
│  Serial:        R1234567890   [Edit]                            │
│                                                                 │
│  [✓ Looks Good]  [Retake Photo]                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.5 Photo Gallery View

Each system/appliance has a photo gallery:

```
┌─────────────────────────────────────────────────────────────────┐
│  Water Heater Photos (4)                              [+ Add]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │         │  │         │  │         │  │         │            │
│  │   📷    │  │   🏷️    │  │   📍    │  │   🔧    │            │
│  │         │  │         │  │         │  │         │            │
│  ├─────────┤  ├─────────┤  ├─────────┤  ├─────────┤            │
│  │Overview │  │ Label   │  │Location │  │Service  │            │
│  │Jan 2024 │  │Jan 2024 │  │Jan 2024 │  │Mar 2024 │            │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.6 Photo Best Practices (Shown to Users)

Display tips when user takes photos:

**Overview Photos:**
- Step back to show full unit in context
- Include surrounding area for reference
- Good lighting, no flash if possible

**Label Photos:**
- Get close but keep text sharp
- Ensure all text is visible
- Avoid glare from flash
- Include model AND serial number

**Location Photos:**
- Show how to access the unit
- Include reference points (door, window)
- Helpful for service technicians

---

## 7. User Flows

### 7.1 Initial Setup Flow (Onboarding)

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: ADD YOUR HOME                                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                       │
│                                                                 │
│  What's your home address?                                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🔍 Enter address...                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  📍 Or use current location                                     │
│                                                                 │
│                                                   [Continue →]  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: CONFIRM PROPERTY DETAILS                               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                       │
│                                                                 │
│  We found some information about your property:                 │
│                                                                 │
│  ☑️ Year Built: 1995                                            │
│  ☑️ Square Feet: 2,450                                          │
│  ☑️ Bedrooms: 4                                                 │
│  ☑️ Bathrooms: 2.5                                              │
│  ☑️ Property Type: Single Family                                │
│  ☐ Lot Size: 0.25 acres                                        │
│                                                                 │
│  [Edit Details]                                                 │
│                                                                 │
│                         [Skip for Now]        [Confirm →]       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: ADD KEY SYSTEMS                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                       │
│                                                                 │
│  Let's add your major home systems. This helps us track         │
│  maintenance and warn you before things need replacement.       │
│                                                                 │
│  Which systems does your home have?                             │
│                                                                 │
│  ☑️ HVAC (Heating & Cooling)                                    │
│  ☑️ Water Heater                                                │
│  ☐ Solar Panels                                                 │
│  ☐ Pool / Spa                                                   │
│  ☐ Septic System                                                │
│  ☐ Well Water                                                   │
│  ☐ Security System                                              │
│  ☐ Generator                                                    │
│                                                                 │
│                         [Skip for Now]        [Continue →]      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: HVAC QUICK SETUP                                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                       │
│                                                                 │
│  When was your HVAC system installed?                           │
│                                                                 │
│  [    ] Year installed (or approximate)                         │
│                                                                 │
│  Don't know? That's okay - you can add details later.           │
│                                                                 │
│  📷 Add a photo of the model label?                             │
│  [Take Photo]  [Skip]                                           │
│                                                                 │
│                                       [Skip System]  [Save →]   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  🎉 YOUR HOME PROFILE IS READY!                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  🏠 123 Main Street                                     │    │
│  │  Built 1995 • 2,450 sq ft • 4 bed / 2.5 bath           │    │
│  │                                                         │    │
│  │  Systems: 2    Appliances: 0    Documents: 0           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  NEXT STEPS:                                                    │
│  □ Add your major appliances                                    │
│  □ Upload a warranty or receipt                                 │
│  □ Set up emergency info                                        │
│                                                                 │
│                            [Explore Home Profile →]             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Add System Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Add System                                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  What type of system?                                           │
│                                                                 │
│  🌡️ HVAC                                                        │
│  ├── Furnace / Heating                                          │
│  ├── Air Conditioning                                           │
│  ├── Heat Pump                                                  │
│  ├── Thermostat                                                 │
│  └── [See All HVAC →]                                           │
│                                                                 │
│  💧 PLUMBING                                                    │
│  ├── Water Heater                                               │
│  ├── Water Softener                                             │
│  ├── Sump Pump                                                  │
│  └── [See All Plumbing →]                                       │
│                                                                 │
│  ⚡ ELECTRICAL                                                  │
│  ├── Electrical Panel                                           │
│  ├── Generator                                                  │
│  ├── Solar System                                               │
│  └── [See All Electrical →]                                     │
│                                                                 │
│  🏠 STRUCTURE                                                   │
│  ├── Roof                                                       │
│  ├── Windows                                                    │
│  ├── Garage Door                                                │
│  └── [See All Structure →]                                      │
│                                                                 │
│  [+ Other System]                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ← Water Heater                                      [Save]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BASIC INFO                                                     │
│  ─────────────────────────────────────────────────              │
│  Type                    [Tank (Gas)            ▼]              │
│  Brand                   [Rheem                   ]              │
│  Model Number            [XG50T06EC36U1           ]              │
│  Serial Number           [                        ]              │
│                                                                 │
│  📷 Scan model label to auto-fill                               │
│                                                                 │
│  SPECIFICATIONS                                                 │
│  ─────────────────────────────────────────────────              │
│  Capacity                [50          ] gallons                 │
│  Location                [Garage                 ▼]              │
│                                                                 │
│  INSTALLATION                                                   │
│  ─────────────────────────────────────────────────              │
│  Installed               [March 2018        📅]                 │
│  Installer               [ABC Plumbing          ]               │
│                                                                 │
│  WARRANTY                                                       │
│  ─────────────────────────────────────────────────              │
│  Warranty Expires        [March 2024        📅]                 │
│  [📎 Link Warranty Document]                                    │
│                                                                 │
│  PHOTOS                                                         │
│  ─────────────────────────────────────────────────              │
│  [+ Add Photo]                                                  │
│                                                                 │
│  NOTES                                                          │
│  ─────────────────────────────────────────────────              │
│  [                                              ]               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.3 Add Appliance Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Add Appliance                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  QUICK ADD                                                      │
│  ─────────────────────────────────────────────────              │
│  [🍳 Refrigerator] [🍳 Range] [🍳 Dishwasher] [🍳 Microwave]    │
│  [🧺 Washer] [🧺 Dryer] [+ More...]                             │
│                                                                 │
│  ─────────────────────────────────────────────────              │
│                                                                 │
│  Or browse by room:                                             │
│                                                                 │
│  🍳 KITCHEN                                          [8 types]  │
│  🧺 LAUNDRY                                          [3 types]  │
│  🧊 CLIMATE                                          [5 types]  │
│  💨 OUTDOOR                                          [3 types]  │
│  🏠 OTHER                                            [4 types]  │
│                                                                 │
│  ─────────────────────────────────────────────────              │
│  [+ Custom Appliance]                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ← Refrigerator                                      [Save]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BASIC INFO                                                     │
│  ─────────────────────────────────────────────────              │
│  Name                    [Kitchen Refrigerator    ]             │
│  Brand                   [Samsung              ▼]               │
│  Model Number            [RF28R7551SR             ]             │
│  Serial Number           [                        ]             │
│                                                                 │
│  📷 Scan label to auto-fill                                     │
│                                                                 │
│  DETAILS                                                        │
│  ─────────────────────────────────────────────────              │
│  Configuration           [French Door          ▼]               │
│  Capacity                [28          ] cu ft                   │
│  Color/Finish            [Stainless Steel      ▼]               │
│  Location                [Kitchen              ▼]               │
│                                                                 │
│  PURCHASE INFO                                                  │
│  ─────────────────────────────────────────────────              │
│  Purchase Date           [June 2022         📅]                 │
│  Purchase Price          [$              2,499]                 │
│  Retailer                [Home Depot            ]               │
│                                                                 │
│  WARRANTY                                                       │
│  ─────────────────────────────────────────────────              │
│  Warranty Expires        [June 2024         📅]                 │
│  [📎 Link Warranty Document]                                    │
│                                                                 │
│  PHOTOS                                                         │
│  ─────────────────────────────────────────────────              │
│  [+ Overview] [+ Model Label] [+ Receipt]                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.4 View/Edit Item Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ←                                         ✏️ Edit    ⋮         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  PHOTOS                                    [+ Add]      │    │
│  │  ┌──────┐ ┌──────┐ ┌──────┐                             │    │
│  │  │  📷  │ │  🏷️  │ │  📍  │                             │    │
│  │  └──────┘ └──────┘ └──────┘                             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  💧 Water Heater                                                │
│  Tank (Gas) • Rheem XG50T06EC36U1                               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  LIFESPAN                                               │    │
│  │  ████████████████████████████████████████░░░░ 85%       │    │
│  │  6 years old • Expected: 8-12 years                     │    │
│  │  🟠 Approaching end of expected life                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  DETAILS                                                        │
│  ├── Capacity              50 gallons                           │
│  ├── Location              Garage                               │
│  ├── Installed             March 2018                           │
│  └── Installer             ABC Plumbing                         │
│                                                                 │
│  WARRANTY                                        🔴 Expired     │
│  ├── Warranty Expires      March 2024                           │
│  └── 📄 Water Heater Warranty.pdf                               │
│                                                                 │
│  LINKED DOCUMENTS                                               │
│  ├── 📄 Installation Receipt                                    │
│  └── 📄 Annual Service Record 2023                              │
│                                                                 │
│  MAINTENANCE HISTORY                                            │
│  ├── Mar 2024 - Anode rod replaced                              │
│  ├── Mar 2023 - Annual flush                                    │
│  └── Mar 2022 - Annual flush                                    │
│                                                                 │
│  NOTES                                                          │
│  └── "Expansion tank installed above unit. Drain valve          │
│       is stiff - may need replacement."                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  [📤 Share]  [🔧 Log Service]  [📄 Add Document]  [🗑️ Delete]  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. UI/UX Specifications

### 8.1 Home Profile Home Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  Home Profile                                          ⚙️       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  📷                          123 Main Street            │    │
│  │  [Home Photo]                Anytown, CA 90210          │    │
│  │                              Built 1995 • 2,450 sq ft   │    │
│  │                              4 bed • 2.5 bath           │    │
│  │                                        [View Details →] │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐                     │
│  │   SYSTEMS        │  │   APPLIANCES     │                     │
│  │       8          │  │       12         │                     │
│  │  ⚠️ 2 aging      │  │  ⚠️ 1 aging      │                     │
│  └──────────────────┘  └──────────────────┘                     │
│                                                                 │
│  LIFESPAN ALERTS                                   [View All →] │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🔴 Water Heater            Exceeded expected life       │    │
│  │    12 years old • Expected 8-12 years      [View →]     │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 🟠 Dishwasher              Approaching end of life      │    │
│  │    8 years old • Expected 9-11 years       [View →]     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  SYSTEMS                                           [View All →] │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │
│  │  🌡️    │ │  💧    │ │  ⚡    │ │  🏠    │ │   +    │  →     │
│  │ HVAC   │ │Plumbing│ │Electric│ │  Roof  │ │  Add   │        │
│  │  (3)   │ │  (2)   │ │  (1)   │ │  (1)   │ │        │        │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        │
│                                                                 │
│  APPLIANCES                                        [View All →] │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │
│  │  🍳    │ │  🍳    │ │  🍳    │ │  🧺    │ │   +    │  →     │
│  │ Fridge │ │ Range  │ │Dishwshr│ │ Washer │ │  Add   │        │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Systems List View

```
┌─────────────────────────────────────────────────────────────────┐
│  ← All Systems (8)                               [+ Add]  🔍    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🌡️ HVAC                                                   (3)  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Furnace (Gas)                                  🟡 65%   │    │
│  │ Lennox XC21 • Installed 2015                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Air Conditioning                               🟢 40%   │    │
│  │ Carrier 24ACC6 • Installed 2020                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Thermostat                                     🟢 35%   │    │
│  │ Nest Learning • Installed 2021                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  💧 PLUMBING                                               (2)  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Water Heater                                  🔴 120%   │    │
│  │ Rheem XG50T06EC36U1 • Installed 2012                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Water Softener                                 🟢 30%   │    │
│  │ Culligan HE • Installed 2022                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ⚡ ELECTRICAL                                             (1)  │
│  🏠 STRUCTURE                                              (2)  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.3 Card Designs

**System/Appliance Card:**

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────┐                                                       │
│  │ 📷   │   System/Appliance Name              [Status Badge]   │
│  │      │   Brand Model • Type                                  │
│  └──────┘   Installed YYYY                                      │
│   Photo                                                         │
│   or Icon   ████████████████░░░░░░░░░░  XX% life remaining      │
└─────────────────────────────────────────────────────────────────┘

Specifications:
- Card height: 88pt
- Thumbnail: 60x60pt, rounded 8pt
- Primary text: 16pt semibold
- Secondary text: 14pt regular, gray
- Progress bar: 4pt height, full width minus padding
- Touch target: Full card
```

**Property Card:**

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────────┐                                            │
│  │                 │    123 Main Street                         │
│  │   [Home Photo]  │    Anytown, CA 90210                       │
│  │                 │                                            │
│  │                 │    Built 1995 • 2,450 sq ft                │
│  └─────────────────┘    4 bed • 2.5 bath • Single Family        │
│                                                                 │
│                                              [View Details →]   │
└─────────────────────────────────────────────────────────────────┘
```

### 8.4 Status Colors

| Status | Hex Code | Usage |
|--------|----------|-------|
| Healthy (>50%) | #4CAF50 | Progress bar, badge |
| Aging (25-50%) | #FFC107 | Progress bar, badge |
| End of Life (0-25%) | #FF9800 | Progress bar, badge |
| Past Due (<0%) | #F44336 | Progress bar, badge |
| Inactive | #9E9E9E | Badge |
| Replaced | #2196F3 | Badge |

### 8.5 Empty States

**No Systems:**
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                          🏠                                     │
│                                                                 │
│              No Systems Added Yet                               │
│                                                                 │
│     Track your HVAC, water heater, roof, and other major        │
│     systems to monitor their age and plan for maintenance.      │
│                                                                 │
│              [+ Add Your First System]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**No Appliances:**
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                          🍳                                     │
│                                                                 │
│              No Appliances Added Yet                            │
│                                                                 │
│     Keep track of all your appliances - refrigerator, washer,   │
│     dryer, dishwasher, and more. Never lose a warranty again.   │
│                                                                 │
│              [+ Add Your First Appliance]                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Integration Points

### 9.1 Document Vault Integration

| Integration | Description |
|-------------|-------------|
| **Link Warranty** | Attach warranty document from vault to system/appliance |
| **Link Receipt** | Attach purchase receipt to appliance |
| **Link Manual** | Attach product manual to system/appliance |
| **Link Service Record** | Attach maintenance invoices |
| **Auto-Categorize** | When uploading warranty, suggest linking to matching appliance |

**Flow: Link Document to Appliance**

```
From Appliance Detail:
[📎 Link Document] → Document Vault picker → Select document → Linked

From Document Vault:
Upload warranty → "Link to appliance?" prompt → Select appliance → Linked
```

### 9.2 Maintenance Calendar Integration

| Integration | Description |
|-------------|-------------|
| **Auto-Generate Tasks** | Create maintenance tasks based on systems (HVAC filter, water heater flush) |
| **Task-to-System Link** | Maintenance tasks link back to system/appliance |
| **Log Service** | Quick action to log service from system detail |
| **Service History** | Display maintenance timeline on system detail |

**Example: Water Heater Creates Tasks**
```
When water heater added:
├── Create task: "Flush water heater" (Annual)
├── Create task: "Check anode rod" (Annual)
└── Create task: "Inspect T&P valve" (Annual)
```

### 9.3 Emergency Hub Integration

| Integration | Description |
|-------------|-------------|
| **Utility Locations** | System locations (water heater, electrical panel) referenced in emergency shutoff guides |
| **Quick Access** | Emergency hub links to key system details |
| **Photos** | System location photos useful during emergencies |

### 9.4 Home Value Integration (Future)

| Integration | Description |
|-------------|-------------|
| **Improvement Tracking** | Major system upgrades can impact home value |
| **Age-Based Adjustments** | Newer systems = higher value |
| **Selling Report** | Include system ages in home history report |

---

## 10. Data Model

### 10.1 Property Object

```javascript
Property {
  id: string (UUID)
  userId: string (owner)
  
  // Address
  address: {
    street: string
    unit: string | null
    city: string
    state: string
    zipCode: string
    county: string
    country: string (default: "US")
  }
  
  // Basic Details
  propertyType: enum (SINGLE_FAMILY, CONDO, TOWNHOUSE, MULTI_FAMILY, MANUFACTURED, OTHER)
  yearBuilt: number (4-digit year)
  squareFootage: number | null
  lotSize: { value: number, unit: 'sqft' | 'acres' } | null
  stories: string | null
  bedrooms: number | null
  bathrooms: number | null (supports decimals)
  
  // Construction
  garage: enum (NONE, ONE_CAR, TWO_CAR, THREE_CAR, FOUR_PLUS, CARPORT) | null
  basement: enum (NONE, UNFINISHED, PARTIAL, FINISHED) | null
  foundationType: enum (SLAB, CRAWL_SPACE, BASEMENT, PIER_BEAM, MIXED) | null
  exteriorMaterial: [string] // multi-select
  roofType: string | null
  roofYear: number | null
  windowType: string | null
  
  // Utilities
  waterSource: enum (MUNICIPAL, WELL, BOTH) | null
  sewerType: enum (MUNICIPAL, SEPTIC, CESSPOOL) | null
  providers: {
    electric: string | null
    gas: string | null
    internet: string | null
    trash: string | null
  }
  
  // HOA
  hoa: {
    name: string | null
    contact: string | null
    dues: number | null
    frequency: string | null
  } | null
  
  // Location Data
  parcelNumber: string | null
  legalDescription: string | null
  zoning: string | null
  floodZone: string | null
  fireZone: string | null
  climateZone: string (auto from ZIP)
  
  // Photos
  photos: [{
    id: string
    url: string
    thumbnailUrl: string
    type: enum (FRONT, REAR, LEFT, RIGHT, AERIAL, LOT, GARAGE, OTHER)
    caption: string | null
    uploadedAt: date
  }]
  
  // Metadata
  createdAt: date
  updatedAt: date
}
```

### 10.2 System Object

```javascript
System {
  id: string (UUID)
  propertyId: string
  userId: string
  
  // Classification
  category: enum (HVAC, PLUMBING, ELECTRICAL, STRUCTURE, SAFETY, POOL, OTHER)
  systemType: string (specific type)
  name: string (display name)
  
  // Status
  status: enum (ACTIVE, NEEDS_ATTENTION, NEEDS_REPAIR, INACTIVE, REPLACED)
  
  // Identification
  brand: string | null
  model: string | null
  serialNumber: string | null
  
  // Installation
  installationDate: date | null
  installationYear: number | null
  installer: string | null
  location: string | null
  
  // Lifespan
  expectedLifespanYears: { min: number, max: number }
  expectedLifespanOverride: number | null (user can adjust)
  
  // Type-Specific Fields (varies by systemType)
  specifications: {
    // HVAC examples
    fuelType: string
    btuRating: number
    seerRating: number
    tonnage: number
    // Plumbing examples
    capacity: number
    capacityUnit: string
    // Electrical examples
    amperage: number
    // etc.
  }
  
  // Warranty
  warrantyExpiration: date | null
  linkedWarrantyDocId: string | null
  
  // Photos
  photos: [{
    id: string
    url: string
    thumbnailUrl: string
    type: enum (OVERVIEW, MODEL_LABEL, LOCATION, CONDITION, MAINTENANCE, OTHER)
    caption: string | null
    uploadedAt: date
  }]
  
  // Links
  linkedDocuments: [string] (document IDs)
  linkedMaintenanceTasks: [string] (task IDs)
  
  // Notes
  notes: string | null
  
  // Audit
  createdAt: date
  updatedAt: date
  replacedBySystemId: string | null (if replaced)
}
```

### 10.3 Appliance Object

```javascript
Appliance {
  id: string (UUID)
  propertyId: string
  userId: string
  
  // Classification
  category: enum (KITCHEN, LAUNDRY, CLIMATE, CLEANING, OUTDOOR, OTHER)
  applianceType: string (specific type)
  name: string (display name)
  
  // Status
  status: enum (ACTIVE, NEEDS_REPAIR, REPLACED, STORED)
  
  // Identification
  brand: string | null
  model: string | null
  serialNumber: string | null
  color: string | null
  
  // Purchase Info
  purchaseDate: date | null
  purchasePrice: number | null
  retailer: string | null
  
  // Location
  location: string | null (room)
  
  // Lifespan
  expectedLifespanYears: { min: number, max: number }
  expectedLifespanOverride: number | null
  
  // Type-Specific Fields
  specifications: {
    // Refrigerator examples
    configuration: string
    capacityCuFt: number
    hasIceMaker: boolean
    hasWaterDispenser: boolean
    // Washer examples
    loadType: string
    capacityCuFt: number
    // etc.
  }
  
  // Warranty
  warrantyExpiration: date | null
  linkedWarrantyDocId: string | null
  
  // Photos
  photos: [{
    id: string
    url: string
    thumbnailUrl: string
    type: enum (OVERVIEW, MODEL_LABEL, LOCATION, CONDITION, RECEIPT, OTHER)
    caption: string | null
    uploadedAt: date
  }]
  
  // Links
  linkedDocuments: [string]
  linkedMaintenanceTasks: [string]
  
  // Notes
  notes: string | null
  
  // Audit
  createdAt: date
  updatedAt: date
  replacedByApplianceId: string | null
}
```

### 10.4 Indexes Required

```
Properties:
- userId (list user's properties)
- address.zipCode (climate zone lookup)

Systems:
- propertyId + category (filter by category)
- propertyId + status (filter active)
- userId + warrantyExpiration (expiration tracking)
- propertyId + installationDate (age queries)

Appliances:
- propertyId + category (filter by category)
- propertyId + status (filter active)
- userId + warrantyExpiration (expiration tracking)
- propertyId + purchaseDate (age queries)
```

---

## 11. Success Metrics

### 11.1 Adoption Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Property details completed | 80%+ | Required fields filled |
| Systems added (first 30 days) | 5+ per user | Count per user |
| Appliances added (first 30 days) | 8+ per user | Count per user |
| Photos added | 60%+ of items have photos | Items with photos / total |
| Profile completeness score | 70%+ average | Weighted completion % |

### 11.2 Engagement Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Profile views per month | 3+ | Sessions with profile view |
| Items edited/updated | 2+ per month | Edits per user |
| Lifespan dashboard views | 1+ per month | Dashboard opens |
| Documents linked to items | 30%+ of items | Items with linked docs |

### 11.3 Value Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Lifespan alerts viewed | 40%+ click-through | Clicks / alerts shown |
| Systems marked as replaced | Track | Replacement events |
| Profile shared with contractor | 5%+ of users | Share events |
| Profile data exported | Track | Export events |

### 11.4 Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Add system completion rate | 90%+ | Completed / started |
| Add appliance completion rate | 90%+ | Completed / started |
| Photo upload success rate | 98%+ | Success / attempts |
| Model label OCR accuracy | 85%+ | Correct extractions |

---

## 12. Implementation Phases

### Phase 1: Property Foundation (Weeks 1-2)

**Goal:** Users can create their property profile with basic details.

- [ ] Property creation flow
- [ ] Address entry with auto-complete
- [ ] Basic property fields (year, sqft, beds, baths)
- [ ] Property type selection
- [ ] Property photo upload (exterior)
- [ ] Property detail view/edit
- [ ] Public records data lookup (ATTOM API)

**Exit Criteria:** User can create property with basic details and photo.

### Phase 2: Systems Registry (Weeks 3-4)

**Goal:** Users can add and manage home systems.

- [ ] System category structure
- [ ] Add system flow for all categories
- [ ] System detail fields by type
- [ ] System list view
- [ ] System detail view
- [ ] System edit functionality
- [ ] System photo capture
- [ ] Model label photo with OCR

**Exit Criteria:** User can add HVAC, plumbing, electrical systems with details.

### Phase 3: Appliances Registry (Weeks 5-6)

**Goal:** Users can add and manage appliances.

- [ ] Appliance category structure
- [ ] Quick-add templates
- [ ] Add appliance flow
- [ ] Appliance detail fields by type
- [ ] Appliance list view
- [ ] Appliance detail view
- [ ] Appliance photo capture
- [ ] Brand/model autocomplete

**Exit Criteria:** User can add kitchen and laundry appliances with details.

### Phase 4: Lifespan Tracking (Week 7)

**Goal:** Users see age vs. lifespan for all items.

- [ ] Lifespan data for all system/appliance types
- [ ] Age calculation logic
- [ ] Status determination (healthy/aging/end of life)
- [ ] Progress bar visualization
- [ ] Lifespan dashboard
- [ ] 5-year forecast view
- [ ] Replacement cost estimates

**Exit Criteria:** Users see lifespan status for all items with dashboard view.

### Phase 5: Integration & Polish (Weeks 8-9)

**Goal:** Connect to other features, polish experience.

- [ ] Link documents to systems/appliances
- [ ] Link maintenance tasks (bi-directional)
- [ ] Service history display
- [ ] Onboarding flow optimization
- [ ] Empty states
- [ ] Share system info with contractor
- [ ] Export property profile
- [ ] Performance optimization

**Exit Criteria:** Home Profile fully integrated with Document Vault and Maintenance.

### Phase 6: Testing & Launch (Weeks 10-11)

**Goal:** Production-ready feature.

- [ ] Comprehensive testing
- [ ] Accessibility audit
- [ ] Error handling edge cases
- [ ] Analytics integration
- [ ] Beta feedback incorporation
- [ ] Documentation
- [ ] Launch readiness

**Exit Criteria:** Home Profile ready for public launch.

---

## Appendix A: Brand Autocomplete List

Common brands for autocomplete suggestions:

**HVAC:**
Carrier, Lennox, Trane, Rheem, Goodman, Bryant, American Standard, York, Daikin, Mitsubishi, Fujitsu, LG, Bosch

**Water Heaters:**
Rheem, A.O. Smith, Bradford White, Rinnai, Navien, Noritz, Takagi, State, GE, Whirlpool

**Appliances:**
Samsung, LG, Whirlpool, GE, Frigidaire, KitchenAid, Maytag, Bosch, Miele, Sub-Zero, Viking, Wolf, Thermador, Electrolux, Kenmore, Amana, Haier, Café, Monogram

**Garage Doors:**
Chamberlain, LiftMaster, Genie, Craftsman, Ryobi, Skylink

**Thermostats:**
Nest, Ecobee, Honeywell, Emerson, Lux, Carrier, Lennox

---

## Appendix B: Climate Zone Reference

IECC Climate Zones for US ZIP codes:

| Zone | Description | Example Cities |
|------|-------------|----------------|
| 1 | Very Hot-Humid | Miami, Key West |
| 2 | Hot-Humid/Dry | Houston, Phoenix, Tampa |
| 3 | Warm-Humid/Dry | Atlanta, Dallas, Las Vegas |
| 4 | Mixed-Humid/Dry | St. Louis, NYC, Seattle |
| 5 | Cool-Humid/Dry | Chicago, Boston, Denver |
| 6 | Cold-Humid/Dry | Minneapolis, Milwaukee |
| 7 | Very Cold | Duluth, International Falls |
| 8 | Subarctic | Fairbanks, Barrow |

---

## Appendix C: Default Lifespan Override Rules

Users can override default lifespans. Suggested guardrails:

| Item Type | Min Override | Max Override |
|-----------|--------------|--------------|
| HVAC | 5 years | 40 years |
| Water Heater | 3 years | 30 years |
| Roof | 10 years | 100 years |
| Appliances | 3 years | 30 years |
| Windows | 10 years | 60 years |

---

*End of Home Profile Feature Specification*
