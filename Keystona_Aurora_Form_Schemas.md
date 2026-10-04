# Keystona — Aurora Form Field Schemas

**Version 1.0 · June 2026 · Active**
**Status:** Canonical. Required reading for any agent building a Create or Edit screen.
**Consumes:** `Keystona_Aurora_Design_System.md` §6.8 (input fields) · `HomeTrack_Database_Schema.md` · `HomeTrack_API_Contract.md`
**Owners:** Flutter agent (renders forms) · Supabase agent (validates server-side) · Integration agent (cross-entity pickers)

---

## 1. How to read this doc

Every Create and Edit screen in Keystona uses the **same canonical form widget** established in `Keystona_Aurora_Design_System.md` §6.8 and demonstrated in the Add System mockup. The widget composes:

- `AuroraFormSection` — section eyebrow with optional "Optional" tag
- `AuroraTextField` — single-line text input
- `AuroraTextArea` — multi-line text input
- `AuroraSelectField` — dropdown / picker
- `AuroraDateField` — date picker (month/year or full date)
- `AuroraToggleRow` — full-width toggle with label and meta
- `AuroraPhotoGrid` — 4-up photo capture grid
- `AuroraSliderField` — value selector with discrete steps (lifespan years, etc.)
- `AuroraLinkPicker` — opens a picker sheet to select a related entity (e.g. "pick a document from the vault")
- `AuroraInlineAction` — small action icon embedded in a field (e.g. Smart Scan icon next to Serial)

What the agent needs from this doc per entity:

1. **Visual layout** — which sections appear, in what order, with what eyebrows.
2. **Field manifest** — every field: order, label, widget, db column, validation, help text, premium gate.
3. **Relationships** — what other entities this form picks from, links to, or auto-creates.
4. **Special behaviors** — Smart scan triggers, auto-task generation, conditional fields.

**Universal rules across all forms:**

- Title is `[Add | Edit] [singular noun].` with a period (Aurora editorial cadence).
- Eyebrow above title is `[Tab name] · [new | editing]` in mono uppercase with a cobalt dot (forms are action surfaces).
- Required fields display a coral asterisk after the label.
- Section headers use mono uppercase with a cobalt dot. If the section is entirely optional, append `Optional` tag in mono ink-tertiary right-aligned.
- The CTA pair is always `Cancel` (white secondary, `1.5px solid ink-border-strong`) and `Save [entity].` (cobalt primary, NOT coral — save is a confirm action). The exception is the `Delete` confirmation, which uses coral.
- On the Edit screen variant, the title becomes `Edit [singular noun].` and a third destructive button appears at the bottom of the form: `Delete` (ghost-style, coral text only, no fill, no border, full-width below the Save/Cancel row, with mono uppercase warning helper below: "REMOVES PERMANENTLY · 30-DAY UNDO IN SETTINGS").
- Smart scan icon (the coral scan glyph) appears inline on fields that support OCR auto-fill. Smart scan is Premium-only; on Free tier the icon renders in `ink-tertiary` with a small lock badge, and tapping shows the Premium upgrade sheet.
- Photo capacity: free tier capped at 4 photos per entity (matches mockup grid). Premium uncapped, paginated grid.
- Save button is disabled until all required fields are filled. Disabled state: `coral-dim` background, `coral` text, no shadow.

---

## 2. Entity index

| # | Entity | Form table | Sections | Required fields |
|---|---|---|---|---|
| 1 | System | `systems` | 4 | 2 (Category, Name) |
| 2 | Appliance | `appliances` | 5 | 2 (Category, Name) |
| 3 | Contact (emergency / contractor) | `emergency_contacts` | 4 | 2 (Name, Category) |
| 4 | Insurance policy | `insurance_policies` | 5 | 3 (Type, Carrier, Policy #) |
| 5 | Document (upload form) | `documents` | 3 | 3 (Name, Category, File) |
| 6 | Maintenance task (custom) | `maintenance_tasks` | 4 | 3 (Name, System link, Recurrence) |
| 7 | Project | `projects` | 4 | 2 (Name, Type) |
| 8 | Budget line item | `project_budget_items` | 2 | 3 (Name, Category, Estimated cost) |

---

## 3. Schema 1 — Add / Edit System

**Entity:** `systems` table.
**Reached from:** Home Profile → Systems list → `+` FAB, or Onboarding setup checklist.
**Title:** `Add a system.` (create) / `Edit [system name].` (edit)
**Eyebrow:** `Home profile · new` (create) / `Home profile · editing` (edit)

### Sections, in order

1. **(unlabeled header section)** — Category + Name. No section eyebrow — these are the primary identifiers.
2. **Identification** — Optional. Brand, Model, Serial.
3. **Install & lifespan** — Installed date, Expected lifespan, Auto-generate maintenance tasks toggle.
4. **Photos** — Optional. Photo grid.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Category | `AuroraSelectField` | `category` (enum) | ✅ | enum: hvac, plumbing, electrical, exterior, interior, roofing, climate, safety, water, foundation | — | Renders inline category icon in the input. Options list from `HomeTrack_API_Contract.md` §7.1. |
| 2 | Name | `AuroraTextField` | `name` | ✅ | 1–60 chars | YOUR REFERENCE NAME — E.G. "MAIN FLOOR HVAC" | First focused field on create. |
| 3 | Brand | `AuroraSelectField` (with free-text fallback) | `brand` | — | 0–40 chars | — | Pre-populated dropdown of common brands per category, plus "Other…" free text. |
| 4 | Model | `AuroraTextField` | `model_number` | — | 0–60 chars | — | Two-column row with Brand. |
| 5 | Serial number | `AuroraTextField` + `AuroraInlineAction` (Smart scan) | `serial_number` | — | 0–60 chars | FIND ON UNIT LABEL | Smart scan icon coral on Premium, locked on Free. |
| 6 | Installed | `AuroraDateField` (month/year) | `installation_date` | — | valid date, not in future | — | Two-column row with Lifespan. |
| 7 | Expected lifespan | `AuroraSliderField` or `AuroraSelectField` | `expected_lifespan_years` | — | int 1–50 | — | Default to category median (HVAC=15, Roofing=25, etc.). |
| 8 | Auto-generate maintenance tasks | `AuroraToggleRow` | (computes downstream) | — | bool | FILTER CHANGES · ANNUAL TUNE-UP (text changes per category) | Default ON. When ON, save triggers task generation per `HomeTrack_API_Contract.md` §7.7. |
| 9 | Photos | `AuroraPhotoGrid` (4-slot on Free) | `system_photos` (1:N table) | — | 0–4 photos Free / unlimited Premium | TAP TO CAPTURE OR PICK | Each photo ≤5MB, compressed to <500KB. |

### Relationships

- **On save:** if Auto-generate is ON, fires Edge Function to create recurring `maintenance_tasks` rows linked to this system via `linked_system_id`.
- **Edit screen extras:** below Save/Cancel/Delete, a small mono link in coral: `View linked tasks → 4 tasks` and `View linked documents → 2 documents`. Each links to the filtered Tasks list and Documents list with the system pre-filtered.

### Special behaviors

- Smart scan on Serial number field: opens camera, captures, OCR extracts model number + serial. On success, Brand/Model fields auto-fill if currently empty (user confirms before save).
- Category change after initial selection prompts: "Switching from HVAC to Plumbing will remove the auto-generated HVAC tasks. Continue?" — only when editing an existing system with linked tasks.

---

## 4. Schema 2 — Add / Edit Appliance

**Entity:** `appliances` table.
**Reached from:** Home Profile → Appliances list → `+` FAB.
**Title:** `Add an appliance.` / `Edit [appliance name].`
**Eyebrow:** `Home profile · new` / `Home profile · editing`

### Sections, in order

1. **(unlabeled)** — Category, Name.
2. **Identification** — Optional. Brand, Model, Serial. Color.
3. **Purchase** — Optional. Purchase price, Retailer, Purchase date, Warranty toggle (expands warranty fields when ON).
4. **Specifications** — Optional. Variable JSONB fields per category (capacity_cu_ft for fridge/freezer, configuration for HVAC, voltage/amperage for electric appliances). Renders as expandable accordion.
5. **Photos** — Optional. Photo grid.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Category | `AuroraSelectField` | `category` | ✅ | enum: kitchen, laundry, climate, cleaning, outdoor, bathroom | — | Drives spec fields in §4. |
| 2 | Name | `AuroraTextField` | `name` | ✅ | 1–60 chars | YOUR NAME FOR IT — E.G. "MAIN FRIDGE" | — |
| 3 | Brand | `AuroraSelectField` (free-text fallback) | `brand` | — | 0–40 chars | — | — |
| 4 | Model | `AuroraTextField` | `model_number` | — | 0–60 chars | — | Two-column with Brand. |
| 5 | Serial number | `AuroraTextField` + Smart scan | `serial_number` | — | 0–60 chars | — | — |
| 6 | Color | `AuroraTextField` | `color` | — | 0–30 chars | — | — |
| 7 | Purchase price | `AuroraTextField` (numeric, currency) | `purchase_price` | — | decimal ≥ 0 | — | Mono input. Prefix `$`. |
| 8 | Retailer | `AuroraTextField` | `retailer` | — | 0–60 chars | — | Two-column with Price. |
| 9 | Purchase date | `AuroraDateField` (full date) | `purchase_date` | — | valid date, not in future | — | — |
| 10 | Has warranty | `AuroraToggleRow` | (conditional gate) | — | bool | WE'LL TRACK THE EXPIRATION DATE | Default OFF. When ON, expands §4a below. |
| 10a | Warranty provider | `AuroraTextField` | `warranty_provider` | — (req if §10 ON) | 0–60 chars | — | Hidden when §10 OFF. |
| 10b | Warranty expires | `AuroraDateField` | `warranty_expiration` | — (req if §10 ON) | valid date, ≥ today | — | Hidden when §10 OFF. |
| 10c | Linked warranty doc | `AuroraLinkPicker` | `linked_warranty_doc_id` | — | uuid → documents | LINK PDF FROM VAULT | Picker filters documents.category = 'warranty'. |
| 11 | Specifications | `AuroraSpecAccordion` (custom) | `specifications` (JSONB) | — | per-category schema | — | Fields render based on Category — fridge: capacity_cu_ft, energy_star; HVAC: configuration, tonnage; etc. See §11 for category-spec map. |
| 12 | Photos | `AuroraPhotoGrid` | `item_photos` (1:N) | — | 0–4 / unlimited | — | — |

### Relationships

- Smart scan on Serial: same as Systems — extracts model + serial, optionally Brand and Energy Star rating.
- Warranty toggle ON: when saving, prompts to upload a warranty PDF if `linked_warranty_doc_id` is null.
- Auto-task generation: same as Systems §8, but the recurrence templates differ per category (fridge: clean coils every 6mo; dryer: clean lint quarterly).

### Specifications accordion contents (§11 per category)

| Category | Fields |
|---|---|
| Kitchen — Fridge / Freezer | Capacity (cu ft), Energy Star (toggle), Configuration (top-freezer / french-door / side-by-side) |
| Kitchen — Range / Oven | Fuel type (gas/electric/induction), Configuration (slide-in / freestanding / wall) |
| Laundry — Washer / Dryer | Capacity (cu ft), Configuration (front-load / top-load / stackable), Energy Star |
| Climate — Water heater | Capacity (gal), Fuel type (gas/electric/tankless), Anode-rod-replaceable (toggle) |
| Cleaning — Dishwasher | Energy Star, Configuration (built-in / portable) |
| Outdoor — Lawn mower | Type (push / self-propelled / riding), Fuel type |
| Bathroom — Generic | (no specifications fields) |

---

## 5. Schema 3 — Add / Edit Contact

**Entity:** `emergency_contacts` table — also serves as the shared contractor pool for Projects (see `Keystona_Agent_Definitions.md` cross-feature links).
**Reached from:** Emergency Hub → Contacts → `+` FAB, OR Project Detail → Contractors → `+` FAB.
**Title:** `Add a contact.` / `Edit [name].`
**Eyebrow:** `Emergency · new` (from Emergency Hub) / `Project · new contractor` (from Projects)

### Sections, in order

1. **(unlabeled)** — Name, Company, Category.
2. **Contact** — Phone primary, Phone secondary, Email.
3. **Availability** — Hours, 24/7 toggle, Favorite toggle.
4. **Notes** — Optional. Notes textarea.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Name | `AuroraTextField` | `name` | ✅ | 1–60 chars | — | Person or company contact name. |
| 2 | Company | `AuroraTextField` | `company` | — | 0–60 chars | — | If different from Name. |
| 3 | Category | `AuroraSelectField` | `category` | ✅ | enum: plumber, electrician, hvac, roofer, painter, contractor, insurance_agent, locksmith, other | — | — |
| 4 | Phone primary | `AuroraTextField` (tel) | `phone_primary` | — | E.164 format | TAP-TO-CALL FROM EMERGENCY HUB | tel: link on tap. Inline call icon. |
| 5 | Phone secondary | `AuroraTextField` (tel) | `phone_secondary` | — | E.164 format | — | — |
| 6 | Email | `AuroraTextField` (email) | `email` | — | RFC 5322 email | — | — |
| 7 | Hours | `AuroraTextField` | `availability_hours` | — | 0–60 chars | E.G. "MON-FRI 8-5" | — |
| 8 | Available 24/7 | `AuroraToggleRow` | `available_24_7` | — | bool | DISPLAYS BADGE IN EMERGENCY HUB | Default OFF. When ON, contact shows lime "24/7" badge in lists. |
| 9 | Pin to Emergency Hub | `AuroraToggleRow` | `is_favorite` | — | bool | SHOWS AT TOP OF CONTACTS LIST | Default OFF. When ON, contact appears in dashboard quick-contacts. Max 5 favorites — show inline error if user tries to favorite a 6th. |
| 10 | Notes | `AuroraTextArea` | `notes` | — | 0–500 chars | INSURANCE CLAIM NUMBER, ETC. | 3 rows visible, expandable. |

### Relationships

- Shared pool: a contact created from Emergency Hub appears in the Project contractor picker. A contact created from a Project appears in the Emergency Hub contacts list. The `project_contractors` link table carries project-specific fields (role, contract amount, paid amount, rating) — those don't live on `emergency_contacts`.
- When reached from a Project, after Save the form transitions directly into the Add-to-Project mini-form with: Role, Contract amount, Document link. See Schema 7 for Project context.

### Special behaviors

- Free tier limit: 10 contacts. 11th contact attempt opens Premium upgrade sheet.
- Phone field renders the country code chooser (default to user's locale) and a "validate" hint on blur.

---

## 6. Schema 4 — Add / Edit Insurance Policy

**Entity:** `insurance_policies` table.
**Reached from:** Emergency Hub → Insurance → `+` FAB.
**Title:** `Add a policy.` / `Edit [policy type] policy.`
**Eyebrow:** `Emergency · insurance · new`

### Sections, in order

1. **(unlabeled)** — Type, Carrier, Policy number.
2. **Coverage** — Coverage amount, Deductible, Annual premium.
3. **Dates** — Effective date, Renewal date.
4. **Agent** — Optional. Agent name, Agent phone, Claims phone.
5. **Linked document** — Optional. Pick policy PDF from vault.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Policy type | `AuroraSelectField` | `policy_type` | ✅ | enum: homeowners, flood, earthquake, umbrella, home_warranty, other | — | — |
| 2 | Carrier | `AuroraTextField` (free-text or pick) | `carrier` | ✅ | 1–60 chars | E.G. "STATE FARM" | — |
| 3 | Policy number | `AuroraTextField` + Smart scan | `policy_number` | ✅ | 1–40 chars | FIND ON DECLARATION PAGE | Mono input. Smart scan extracts from policy PDF. |
| 4 | Coverage amount | `AuroraTextField` (currency) | `coverage_amount` | — | decimal ≥ 0 | — | `$` prefix. |
| 5 | Deductible | `AuroraTextField` (currency) | `deductible` | — | decimal ≥ 0 | — | Two-column with Coverage. |
| 6 | Annual premium | `AuroraTextField` (currency) | `annual_premium` | — | decimal ≥ 0 | — | — |
| 7 | Effective date | `AuroraDateField` | `effective_date` | — | valid date | — | Two-column with Renewal. |
| 8 | Renewal date | `AuroraDateField` | `renewal_date` | — | valid date, > effective | DUE-SOON BADGE IF < 30 DAYS | When < 30 days from today, dashboard shows reminder. |
| 9 | Agent name | `AuroraTextField` | `agent_name` | — | 0–60 chars | — | — |
| 10 | Agent phone | `AuroraTextField` (tel) | `agent_phone` | — | E.164 | TAP-TO-CALL | — |
| 11 | Claims phone | `AuroraTextField` (tel) | `claims_phone` | — | E.164 | TAP-TO-CALL · USE IN EMERGENCY | Renders with coral phone icon (claims phones get the urgent treatment). |
| 12 | Linked policy document | `AuroraLinkPicker` | `linked_document_id` | — | uuid → documents | LINK PDF FROM VAULT | Picker filters `documents.category = 'insurance'`. |

### Relationships

- Renewal date < 30 days from today: triggers an entry in the dashboard's "Needs Attention" card.
- Linked document: enables "View policy" button on the Insurance detail screen which opens the PDF viewer.

---

## 7. Schema 5 — Upload Document (form)

**Entity:** `documents` table.
**Reached from:** Documents tab → FAB → "Upload" / "Scan", or from any feature's "Link a document" picker → "+ Upload new".
**Title:** `New document.` (always — no Edit version of *upload*; edits happen via Document Detail Edit form which has the same fields minus the file picker)
**Eyebrow:** `Docs · new`

### Sections, in order

1. **File** — File picker (camera / library / files app), shows thumbnail preview after capture.
2. **(unlabeled)** — Name, Category, Expiration date (conditional).
3. **Details** — Optional. Notes, Tags, Linked entity.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | File | `AuroraFilePicker` | `storage_path` (signed URL) | ✅ | PDF / JPG / PNG / HEIC ≤ 25MB | TAP TO SCAN, PICK, OR DROP | Shows file thumbnail + size after pick. Smart scan available inline on Premium. |
| 2 | Name | `AuroraTextField` | `name` | ✅ | 1–120 chars | AUTO-FILLED FROM SMART SCAN (if Premium) | On Premium with Smart scan: pre-fills from OCR title detection. On Free: empty placeholder "Document name". |
| 3 | Category | `AuroraSelectField` | `category` | ✅ | enum or custom (Premium) | — | Standard categories: insurance, warranty, maintenance, permit, receipt, contract, manual, inspection, tax, other. Premium users see "+ Custom category" option. |
| 4 | Has expiration | `AuroraToggleRow` | (conditional gate) | — | bool | WE'LL REMIND YOU 30 DAYS BEFORE | Default OFF for receipt/maintenance/manual/tax; ON for insurance/warranty/permit/contract/inspection. |
| 4a | Expires | `AuroraDateField` | `expiration_date` | — (req if §4 ON) | valid date, ≥ today | — | Hidden when §4 OFF. |
| 5 | Notes | `AuroraTextArea` | `notes` | — | 0–500 chars | — | 3 rows visible. |
| 6 | Tags | `AuroraTextField` (chip input) | `tags` (array) | — | each tag 1–24 chars, max 8 tags | E.G. "FURNACE, 2024 INSTALL" | Tag chips render below input as user types and presses comma or space. |
| 7 | Linked entity | `AuroraLinkPicker` | `linked_system_id` / `linked_appliance_id` / `linked_project_id` | — | uuid → respective table | LINK TO A SYSTEM, APPLIANCE, OR PROJECT | Picker shows tabs for Systems / Appliances / Projects. Multi-select disabled — one link only. The `linked_*_id` columns are mutually exclusive (only one populates per document). |

### Relationships

- Free tier: 50 documents total. 51st upload attempt opens Premium upgrade sheet.
- Smart scan on the File field: after capture, OCR extracts text. Premium-only. On Success, populates Name, suggests Category, extracts expiration date if found.
- Linked entity: if linked to a system/appliance/project, that entity's detail screen shows this document in its "Linked documents" section.

### Special behaviors

- "Has expiration" toggle default depends on Category. If user selects Category before toggle, the toggle pre-sets accordingly.
- Premium "+ Custom category" reaches the Custom Category manager (see screen #32 in inventory).

---

## 8. Schema 6 — Add / Edit Maintenance Task (custom)

**Entity:** `maintenance_tasks` table.
**Reached from:** Tasks tab → FAB → "Create custom task", OR from a system/appliance detail → "+ Task".
**Title:** `New task.` / `Edit task.`
**Eyebrow:** `Tasks · new` / `Tasks · editing`

### Sections, in order

1. **(unlabeled)** — Name, Linked system or appliance, Recurrence.
2. **Details** — Optional. Description textarea, Estimated time, Difficulty, DIY/Pro toggle.
3. **First occurrence** — First due date, Reminder lead time.
4. **Cost** — Optional. Estimated cost, Tools/supplies.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Task name | `AuroraTextField` | `name` | ✅ | 1–80 chars | E.G. "REPLACE HVAC AIR FILTER" | — |
| 2 | Linked item | `AuroraLinkPicker` | `linked_system_id` OR `linked_appliance_id` | ✅ | uuid → systems or appliances | TASK BELONGS TO WHICH SYSTEM? | Picker shows tabs for Systems / Appliances. Single select. Required because health score formula needs the link. |
| 3 | Recurrence | `AuroraSelectField` | `recurrence_type` + `recurrence_value` | ✅ | enum: once, monthly, every_3_months, every_6_months, annually, every_n_years, custom | — | Selecting `every_n_years` or `custom` reveals an `AuroraSliderField` for the integer value. Display labels per `Keystona_Aurora_Design_System.md` recurrence rule: "Every 3 months" not "Quarterly", "Twice a year" not "Biannually". |
| 4 | Description | `AuroraTextArea` | `description` | — | 0–500 chars | INSTRUCTIONS · MATERIALS · SAFETY NOTES | 3 rows visible. |
| 5 | Estimated time | `AuroraSelectField` | `estimated_time_min` | — | int (5/10/15/30/45/60/90/120/180/240 min) | — | Two-column with Difficulty. |
| 6 | Difficulty | `AuroraSelectField` | `difficulty` | — | enum: easy, medium, hard | — | — |
| 7 | DIY or Pro | `AuroraSelectField` | `method` | — | enum: diy, pro, either | — | Default "DIY". Pro tasks can link to a contractor from the shared pool. |
| 8 | First due | `AuroraDateField` | `first_due_date` | — | valid date | DEFAULTS TO TODAY | Required when creating; for edits this is read-only and the field is replaced with "Next due: [date]". |
| 9 | Reminder | `AuroraSelectField` | `reminder_days_before` | — | enum: 1, 3, 7, 14, 30 days | NOTIFICATION LEAD TIME | Default 7 days. |
| 10 | Estimated cost | `AuroraTextField` (currency) | `estimated_cost` | — | decimal ≥ 0 | — | `$` prefix. |
| 11 | Tools & supplies | `AuroraTextArea` | `tools_supplies` | — | 0–300 chars | — | 2 rows visible. |

### Relationships

- Required Linked item: cannot save without linking to a system or appliance.
- Completing this task triggers the next occurrence based on `recurrence_type` and `recurrence_value`.
- Pro tasks: when user marks done, prompts "Did you hire someone?" → option to link a contractor from the shared pool, which writes to the completion record.

### Special behaviors

- Recurrence options are intentionally curated (no SQL-flavored "biweekly") — `Keystona_Aurora_Design_System.md` recurrence display rule applies system-wide.
- If linked item has Auto-generate enabled, this custom task is added *alongside* the system-generated tasks, not in place of them.

---

## 9. Schema 7 — Add / Edit Project

**Entity:** `projects` table.
**Reached from:** Projects tab → FAB.
**Title:** `New project.` / `Edit [project name].`
**Eyebrow:** `Projects · new` / `Projects · editing`

### Sections, in order

1. **(unlabeled)** — Name, Type, Status.
2. **Dates** — Planned start, Planned completion.
3. **Budget** — Estimated budget, Project method.
4. **Cover** — Optional. Cover photo.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Project name | `AuroraTextField` | `name` | ✅ | 1–80 chars | E.G. "PRIMARY BATH RENOVATION" | — |
| 2 | Project type | `AuroraSelectField` | `project_type` | ✅ | enum: kitchen_remodel, bathroom_remodel, deck_build, roof_replace, hvac_replace, flooring, paint, landscaping, addition, basement, other | DRIVES PHASE TEMPLATE SUGGESTION | After save, if type is supported and project has no phases, show prompt: "Load default phases for [type]?" |
| 3 | Status | `AuroraSelectField` | `status` | — | enum: planning, in_progress, on_hold, completed, cancelled | — | Default `planning`. On Edit, only valid transitions shown (planning → in_progress / cancelled; in_progress → on_hold / completed / cancelled; etc.). |
| 4 | Planned start | `AuroraDateField` | `planned_start_date` | — | valid date | — | Two-column with Completion. |
| 5 | Planned completion | `AuroraDateField` | `planned_completion_date` | — | valid date, ≥ planned_start | — | — |
| 6 | Estimated budget | `AuroraTextField` (currency) | `estimated_budget` | — | decimal ≥ 0 | TOTAL BUDGET — LINE ITEMS COME LATER | `$` prefix. |
| 7 | Project method | `AuroraSelectField` | `method` | — | enum: diy, contractor, mixed | — | "Mixed" enables both budget-line-item methods and contractor linking. |
| 8 | Cover photo | `AuroraPhotoGrid` (1-slot) | `cover_photo_path` | — | 1 photo ≤ 5MB | TAP TO ADD A HERO IMAGE | Single slot, not a 4-up grid. Used as the Projects-list card image. |

### Relationships

- Free tier: 2 projects total. 3rd project attempt opens Premium upgrade sheet.
- Status `completed` triggers retrospective view routing (per the spec wrapper pattern). Status `cancelled` also routes to retrospective but with a different empty-state on photos/budget.
- After Save: if `project_type` has a phase template and no phases exist, show modal prompting to load defaults.

### Special behaviors

- The four sub-pages within a Project (Phases, Budget, Photos, Notes) are not in this form — they're their own screens reached from the Project Detail tabs. Their respective Add/Edit forms (line items, phases, notes) are listed separately.

---

## 10. Schema 8 — Add / Edit Budget Line Item

**Entity:** `project_budget_items` table.
**Reached from:** Project Detail → Budget tab → `+` button.
**Title:** `New line item.` / `Edit line item.`
**Eyebrow:** `[Project name] · budget · new`

### Sections, in order

1. **(unlabeled)** — Name, Category, Estimated cost.
2. **Actual** — Optional. Actual cost, Vendor, Paid toggle, Linked receipt.

### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Item name | `AuroraTextField` | `name` | ✅ | 1–80 chars | E.G. "TILE FOR MASTER SHOWER" | — |
| 2 | Category | `AuroraSelectField` | `category` | ✅ | enum: materials, labor, permits, fixtures, equipment_rental, design, other | — | — |
| 3 | Estimated cost | `AuroraTextField` (currency) | `estimated_cost` | ✅ | decimal ≥ 0 | — | `$` prefix. |
| 4 | Actual cost | `AuroraTextField` (currency) | `actual_cost` | — | decimal ≥ 0 | — | When set and ≠ estimated, project shows over/under badge. |
| 5 | Vendor | `AuroraTextField` | `vendor` | — | 0–60 chars | E.G. "HOME DEPOT" | Two-column with Actual cost. |
| 6 | Paid in full | `AuroraToggleRow` | `paid_in_full` | — | bool | — | Default OFF. Drives "Paid YTD" rollup on Budget overview. |
| 7 | Linked receipt | `AuroraLinkPicker` | `linked_document_id` | — | uuid → documents | LINK RECEIPT PDF FROM VAULT | Picker filters `documents.category IN ('receipt', 'invoice')`. |

### Relationships

- Saving updates the parent project's `actual_spent` via RPC (see `HomeTrack_API_Contract.md` §14.8).
- Linked receipt: if no matching document exists, picker shows "+ Upload new" which opens Schema 5 (Upload Document) with `category` pre-set to receipt and `linked_project_id` pre-set.

### Special behaviors

- When `actual_cost > estimated_cost`, the row in the budget list shows a coral "Over" badge. When `actual_cost < estimated_cost` and `paid_in_full = true`, shows a lime "Saved" badge with the delta. When equal, no badge.

---

## 11. Cross-cutting rules

### 11.1 Save behavior

- All Save buttons use cobalt (`#2540D8`). Never coral.
- Save is disabled until all required fields validate.
- On Save, the form posts to the relevant API endpoint, awaits success, then either:
  - Pops back to the list screen (default behavior), OR
  - Routes to a specific next screen (e.g. Add System with Auto-generate ON → System Detail with the generated tasks pre-loaded), OR
  - For mid-onboarding flows, advances to the next step.
- On Save failure (network or validation), the form stays open and shows an inline coral error banner at the top with the specific reason: "Couldn't save — [reason]". Banner has a dismiss icon and a "Try again" link.

### 11.2 Cancel behavior

- If no fields have been modified: pop back silently.
- If any field has been modified: show iOS-style confirmation sheet — "Discard changes?" / "Keep editing" / "Discard". Sheet uses Aurora confirmation modal pattern.

### 11.3 Delete behavior (Edit screens only)

- Delete button at the bottom of the form is a ghost-style button: coral text, no fill, no border, full-width, with mono uppercase helper below.
- Tapping Delete opens an Aurora confirmation modal: "Delete [entity name]?" with the entity's identifying name in the title. Modal body explains what happens to linked records.
- Soft-delete only (sets `deleted_at`). 30-day undo available in Settings → Recently deleted.

### 11.4 Auto-save (NOT supported)

- Aurora forms are explicit-save only. No autosave drafts. Cancel discards. This is intentional: explicit save matches the user's mental model of "I'm filling out a record," and autosave drafts complicate validation, conflict resolution, and the cross-entity link pickers (a draft system can't yet be linked to a draft task).

### 11.5 Smart scan integration

- Smart scan is a Premium feature. The inline action icon renders in `coral` (`#FF3B62`) on Premium tier and in `ink-tertiary` with a small lock badge on Free tier.
- Tapping the icon on Premium: opens camera with a frame outline matching the field (rectangular for serial labels, full-page for documents). On capture, OCR runs, results stream into the form. User must confirm before save.
- Tapping the icon on Free: opens Premium upgrade sheet (Screen #82 in inventory).

### 11.6 Photo capture

- All photo grids (`AuroraPhotoGrid`) use the same 4-up layout on Free tier.
- Tapping an empty slot: opens action sheet with "Take photo" and "Pick from library" options.
- Tapping a filled slot: opens photo viewer with options to set as cover, remove, or replace.
- Premium tier: photo grids paginate (4 per row, scroll for more). Upload count uncapped per entity.

### 11.7 Inline link pickers

- All `AuroraLinkPicker` widgets use the same modal sheet pattern: bottom sheet, 80% screen height, filter chips at top (when applicable), scrollable list of options, "Cancel" in top-left, "+ Add new" in top-right.
- Selecting an option pops the sheet and renders the selected entity in the field as a chip with the entity icon + name + small `×` to clear.

### 11.8 Required vs optional

- Required fields display a `coral asterisk` after the label.
- Optional sections display an `Optional` tag in mono ink-tertiary, right-aligned in the section eyebrow.
- The minimum-viable-record principle: every entity should be saveable with the smallest reasonable set of required fields. Add Appliance with just Category and Name should save successfully; everything else is enrichment.

### 11.9 Helper text rules

- Mono uppercase, 9.5px, `ink-tertiary` color.
- Always sentence-fragment, not full sentence (no period at end).
- Use to clarify *what* a field is for, not *how* to fill it: ✅ "YOUR REFERENCE NAME — E.G. 'MAIN FLOOR HVAC'" · ❌ "ENTER A REFERENCE NAME HERE BY TAPPING THE FIELD".
- Reserved for fields where the label alone is ambiguous (Name without context, Lifespan without unit guidance, Reminder without lead-time meaning). Most fields don't need helper text.

---

## 12. Build order recommendation

For the Flutter agent: build the form widgets first as a kit, then implement schemas in order of dependency frequency.

1. **Widget kit** — `AuroraForm`, `AuroraFormSection`, `AuroraTextField`, `AuroraTextArea`, `AuroraSelectField`, `AuroraDateField`, `AuroraToggleRow`, `AuroraPhotoGrid`, `AuroraSliderField`, `AuroraLinkPicker`, `AuroraInlineAction`. Roughly 800–1200 lines of Dart total.
2. **Schema 1 — System.** Simplest schema. Validates the kit.
3. **Schema 2 — Appliance.** Adds the conditional warranty toggle and JSONB specifications accordion. Validates the conditional-field pattern.
4. **Schema 3 — Contact.** Validates the dual-context behavior (Emergency Hub vs Project entry points).
5. **Schema 5 — Document.** Validates the file picker and Smart scan integration.
6. **Schema 6 — Task.** Validates the required-link picker pattern.
7. **Schema 7 — Project.** Validates the cover-photo single-slot pattern.
8. **Schema 4 — Insurance.** Most fields per form; saved for last because it tests every widget type.
9. **Schema 8 — Budget line item.** Smallest schema, but depends on Project being live to test linkage.

---

## 13. Sub-form appendix

These five forms are smaller (≤6 fields each), live inside a parent screen rather than as standalone Add/Edit screens, and follow the canonical form pattern at a reduced scale. Each is documented with the same three-layer structure as the main schemas, but condensed because the field counts are low and the relationships are simpler.

**What "sub-form" means here:** the form renders inside a parent screen (a modal sheet, an inline expandable section, or a slide-in panel) rather than pushing as a new full-screen route. The Cancel/Save behavior, validation rules, and field widgets are identical to the main schemas — only the *presentation* differs. A sub-form sheet still uses the cobalt Save button, still uses mono uppercase helper text, still uses the same `AuroraTextField` widgets.

**Sub-form presentation rules:**

- All sub-forms render as a **modal sheet** at 60–80% screen height (depending on field count), pulled up from the bottom edge.
- Sheet header: drag handle (4px tall, 36px wide, `ink-border-strong`, centered, 8px from top), then below it a row with `Cancel` (ghost button, left) and the title in `h3` style (centered) and `Save [entity]` (cobalt pill button, right).
- Sheet body uses the same field widgets, section eyebrows, and helper text styling as the main schemas.
- Required-field asterisks, Smart-scan integration, and link-picker behaviors are inherited.
- Closing the sheet (swipe down or Cancel) follows the same dirty-state confirmation rule as the main schemas (§11.2).

### 13.1 Sub-form A — Phase (within Project)

**Entity:** `project_phases` table.
**Reached from:** Project Detail → Phases tab → `+` button at the bottom of the phase list. Edit by tapping the kebab menu on any phase row → "Edit phase".
**Title:** `New phase.` / `Edit phase.`
**Presentation:** Modal sheet, ~60% screen height.

#### Sections, in order

1. **(unlabeled)** — Phase name, Description.
2. **Schedule** — Planned start, Planned completion.
3. **Status** — Status selector. Hidden on create (defaults to `scheduled`); visible on edit.

#### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Phase name | `AuroraTextField` | `name` | ✅ | 1–60 chars | E.G. "TILE & FIXTURES" | First focused field. |
| 2 | Description | `AuroraTextArea` | `description` | — | 0–300 chars | WHAT HAPPENS IN THIS PHASE | 2 rows visible. |
| 3 | Planned start | `AuroraDateField` | `planned_start_date` | — | valid date | — | Two-column with Completion. |
| 4 | Planned completion | `AuroraDateField` | `planned_completion_date` | — | valid date, ≥ planned_start | — | — |
| 5 | Status | `AuroraSelectField` | `status` | — | enum: scheduled, active, completed, skipped | — | Hidden on create. On edit, only valid transitions shown (scheduled → active / skipped; active → completed / skipped; completed → active for un-completion). |

#### Relationships

- Phases belong to a project via `project_id` (foreign key). When the parent project's status changes to `completed`, all `active` phases auto-transition to `completed` and trigger the project retrospective view.
- Setting a phase to `active` while another phase is already `active` prompts: "Set [previous phase] to completed?" — projects support multiple concurrent phases, but this confirmation guards against accidental drift.
- Deleting a phase (via the kebab menu, not from this form): budget line items and notes that link to this phase keep their `project_id` but have `phase_id` set to null. They don't get deleted.

#### Special behaviors

- The "Load default phases" prompt (triggered after creating a project per Schema 7 §9 Relationships) batch-creates phases without opening this sub-form. The sub-form is for custom phases only.
- Drag-to-reorder happens at the Phases list level, not inside this sub-form. The form does not have an `order` field — order is set by position in the list.

---

### 13.2 Sub-form B — Add contractor to project (link form)

**Entity:** `project_contractors` link table (the existing contact in `emergency_contacts` is not duplicated — this form creates the project-specific overlay).
**Reached from:** Project Detail → Contractors tab → `+` button → "Pick from contacts" picker → after selecting a contact, this sub-form appears for the project-specific fields. Also reached when creating a brand-new contact from a Project (Schema 3 transitions directly into this sub-form on save).
**Title:** `Add [contact name] to project.` / `Edit [contact name]'s role.`
**Presentation:** Modal sheet, ~55% screen height.

#### Sections, in order

1. **(unlabeled)** — Role, Contract amount, Amount paid.
2. **Documents** — Optional. Linked contract document.

#### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Role on project | `AuroraSelectField` (free-text fallback) | `role` | ✅ | enum: general_contractor, plumber, electrician, hvac, painter, tile_setter, designer, other | — | Pre-populated options from contact's `category`, plus "Other…" free text. |
| 2 | Contract amount | `AuroraTextField` (currency) | `contract_amount` | — | decimal ≥ 0 | TOTAL AGREED PRICE | `$` prefix. |
| 3 | Amount paid | `AuroraTextField` (currency) | `amount_paid` | — | decimal ≥ 0, ≤ contract_amount | RUNNING TOTAL PAID TO DATE | `$` prefix. Two-column with Contract amount. When equal to Contract amount, project shows lime "Paid in full" badge. |
| 4 | Linked contract | `AuroraLinkPicker` | `linked_document_id` | — | uuid → documents | LINK CONTRACT OR ESTIMATE PDF | Picker filters `documents.category IN ('contract', 'invoice', 'receipt')`. |

#### Relationships

- Read-only display above the form (not editable): the contact's name, company, category, and primary phone — pulled from `emergency_contacts`. Tapping this read-only block opens the contact's full edit form (Schema 3) in a stacked sheet.
- The contractor remains in the shared pool (`emergency_contacts`) — removing them from this project does NOT delete the contact, only the `project_contractors` link row.
- After the project is set to `completed`, this sub-form gains a new section §3 below (see Special behaviors).

#### Special behaviors

- **Post-completion rating:** when the parent project's status is `completed`, this form auto-expands a §3 "Rate this contractor" section with two fields: a 1–5 star rating (`AuroraSliderField` styled as stars) writing to `rating`, and a review notes textarea writing to `review_notes` (0–500 chars). These fields are hidden until the project completes — the rating prompt only appears post-completion to capture honest signal.
- **Brand-new contact entry path:** when this sub-form is reached after creating a brand-new contact from the Project tab (Schema 3 transition), the contact's name appears in the title and the contact rows are not editable from here.

---

### 13.3 Sub-form C — Project note (journal entry)

**Entity:** `project_notes` table.
**Reached from:** Project Detail → Notes tab → `+` button. Edit by tapping a note in the journal feed.
**Title:** `New note.` / `Edit note.`
**Presentation:** Modal sheet, ~70% screen height (content field is large).

#### Sections, in order

1. **(unlabeled)** — Title, Content, Note date, Phase link.

#### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Title | `AuroraTextField` | `title` | — | 0–80 chars | OPTIONAL — CAN START WITH JUST CONTENT | When blank, the journal feed displays the first 40 chars of `content` as the title. |
| 2 | Content | `AuroraTextArea` | `content` | ✅ | 1–4000 chars | THE NOTE BODY | 8 rows visible, expandable. Auto-expands as user types. |
| 3 | Note date | `AuroraDateField` | `note_date` | — | valid date | DEFAULTS TO TODAY | Allows back-dating for retroactive entries. |
| 4 | Linked phase | `AuroraLinkPicker` | `phase_id` | — | uuid → project_phases | OPTIONAL — ATTACH TO A PHASE | Picker shows phases for the parent project only. Single select with clear-icon to unlink. |

#### Relationships

- Notes belong to a project via `project_id` (foreign key, implicit from the parent screen — never user-editable).
- When linked to a phase, the note appears both in the global project journal AND in a "Notes" sub-section on the phase detail (when phases support sub-screens in a future release).
- Deleting a linked phase nulls the `phase_id` on this note but keeps the note attached to the project.

#### Special behaviors

- No `AuroraPhotoGrid` on notes — photos go in the Photos tab, notes are text-only by design. The Flutter agent should not add inline-image support to this sub-form.
- Markdown is NOT supported in the content field. Plain text only. If users want formatted notes, the answer is to upload a document.

---

### 13.4 Sub-form D — Utility shutoff setup

**Entity:** `utility_shutoffs` table.
**Reached from:** Emergency Hub → tap an un-configured shutoff card (Water / Gas / Electric) → opens this sub-form. Edit by tapping a configured shutoff card and selecting "Edit details".
**Title:** `Set up [utility] shutoff.` / `Edit [utility] shutoff.` (utility is one of: water, gas, electric)
**Presentation:** Modal sheet, ~85% screen height (photo section makes this taller).

#### Sections, in order

1. **(unlabeled)** — Location, Valve type, Turn direction.
2. **Tools & notes** — Optional. Tools required, Special instructions.
3. **Photos** — Location photo, Valve close-up photo. Two slots, both encouraged.

#### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Location description | `AuroraTextArea` | `location_description` | ✅ | 1–200 chars | WHERE TO FIND IT — E.G. "BASEMENT NEAR WATER HEATER" | 2 rows visible. **This is the most important field** — in a crisis, this text is what the user reads first. |
| 2 | Valve type | `AuroraSelectField` | `valve_type` | — | enum: ball_valve, gate_valve, knife_valve, lever, wheel, breaker_panel, push_button, other | — | Options shown depend on `utility_type`: water shows ball/gate/knife/lever/wheel; gas shows ball/lever; electric shows breaker_panel/push_button. |
| 3 | Turn direction | `AuroraSelectField` | `turn_direction` | — | enum: clockwise, counterclockwise, lift, push, flip_breaker | LEFTY-LOOSEY OR RIGHTY-TIGHTY | Hidden for electric `breaker_panel` valve type (flips are universal). |
| 4 | Tools required | `AuroraTextField` | `tools_required` | — | 0–120 chars | E.G. "WATER METER KEY · WRENCH" | — |
| 5 | Special instructions | `AuroraTextArea` | `special_instructions` | — | 0–500 chars | WARNINGS, MULTI-STEP PROCEDURES, RELIGHTING PILOT, ETC. | 3 rows visible. Critical for gas (relighting), often important for water (main vs zone valves). |
| 6 | Location photo | `AuroraPhotoGrid` (1-slot) | `location_photo_path` | — | 1 photo ≤ 500KB after compression | A WIDE SHOT SHOWING THE AREA | Single slot. Auto-compressed at upload time per `HomeTrack_API_Contract.md` §10.7 (offline-first sync). |
| 7 | Valve close-up photo | `AuroraPhotoGrid` (1-slot) | `valve_photo_path` | — | 1 photo ≤ 500KB after compression | A CLOSE SHOT OF THE VALVE ITSELF | Single slot. — |

#### Relationships

- One `utility_shutoffs` row per property per utility type (water, gas, electric) — there is no multi-shutoff support per utility per property at v1. (A future "Multi-zone shutoffs" feature might relax this — out of scope for now.)
- On save: marks the shutoff as `complete` if `location_description` is filled. The Emergency Hub home screen recalculates completion status. (Per Aurora design: complete shutoffs render with `lime-dim` background; incomplete with category-color tile.)
- Photos sync to local SQLite per `HomeTrack_SRS.md` §3.4.4 — this is the *only* place in Keystona where offline-first storage is required by design. The Flutter agent must implement the dual-write pattern (Supabase storage + local SQLite cache) for these two photos specifically.

#### Special behaviors

- The "Save" button label changes to `Mark as ready` (instead of `Save shutoff`) — this is the one place Aurora overrides the standard "Save [entity]" copy because "Mark as ready" reads as preparation language, which matches the Emergency Hub's protective-readiness framing.
- After saving, the Emergency Hub home screen scrolls to and briefly highlights the now-complete shutoff card (lime flash for ~600ms).
- **Offline mode:** this sub-form is one of the few surfaces in Keystona that must function fully offline. If a user is setting up shutoffs after just losing connectivity (an actual disaster scenario), the form saves to local SQLite immediately and syncs to Supabase when connectivity returns. No connectivity check, no error toast — just silent local save with a small mono "saved offline" indicator under the Mark as ready button.

---

### 13.5 Sub-form E — Custom category (Premium)

**Entity:** `custom_categories` table.
**Reached from:** Documents tab → tap the Category filter chips → scroll to end → "+ Custom category" pill (Premium-only). Also reached from any Document upload form (Schema 5 §4 Category select → "+ Custom category" option at the bottom of the dropdown).
**Title:** `New category.` / `Edit category.`
**Presentation:** Modal sheet, ~50% screen height (smallest sub-form).

#### Sections, in order

1. **(unlabeled)** — Name, Parent type, Icon, Color.

#### Field manifest

| Order | Label | Widget | DB column | Required | Validation | Helper text | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Category name | `AuroraTextField` | `name` | ✅ | 1–40 chars | E.G. "BOAT PAPERWORK" or "HOA DOCS" | First focused field. Validation: must be unique within the user's custom categories. |
| 2 | Group under | `AuroraSelectField` | `parent_category` | ✅ | enum: documents (v1) | — | At v1, only Documents supports custom categories. Field is read-only displayed as "Documents". Reserved for future expansion (custom task categories, custom appliance types). |
| 3 | Icon | `AuroraIconPicker` (grid) | `icon_name` | — | tabler icon name | — | Renders a 6×6 grid of 36 curated Tabler outline icons appropriate for document categorization (folder, file, gavel, anchor, key, etc.). Default selection: `ti-folder`. |
| 4 | Color | `AuroraColorPicker` (5-swatch row) | `color_token` | — | enum: coral, cobalt, lime, yellow, plum-aurora, teal-aurora | — | Renders five Aurora-compatible swatches as 32×32 circles. **Important:** because the spec collapses v1's nine colors onto Aurora's five (per `Keystona_Aurora_Design_System.md` §8), custom categories should NOT introduce off-system colors. The five options are: coral, cobalt, lime, yellow, and (for future palette expansion) plum-aurora and teal-aurora as reserved tokens that the Flutter agent should expose but not map to a fill until §8's deprecation is resolved. At v1, hide plum-aurora and teal-aurora; show coral / cobalt / lime / yellow only. |

#### Relationships

- Free tier: this sub-form is gated. Tapping "+ Custom category" on Free opens the Premium upgrade sheet (Screen #82). On Premium, the sub-form opens immediately.
- Custom categories appear in the Documents filter chip row alongside standard categories, and in the Document upload form's Category select. They sort alphabetically after the standard categories.
- Deleting a custom category prompts: "[N] documents are in this category. Where should they move?" — user picks a destination category. Documents are never orphaned.

#### Special behaviors

- Maximum 10 custom categories per user. The 11th attempt shows an inline coral error: "You've reached the 10-category limit. Edit or delete an existing one to add more." This is a real cap, not a Premium-tier upsell — it exists to prevent users from creating dozens of categories that fragment their document organization.
- The icon picker grid is hand-curated (36 icons) rather than exposing the full Tabler set (5800+). Showing all of them would be visual overload and most icons (`ti-rocket`, `ti-cat`, `ti-pizza`) make no sense for document categories. The curated list lives in a config file the Flutter agent can extend later.

---

## 14. Sub-form universal rules

These rules apply to all five sub-forms above and to any future sub-forms.

### 14.1 Modal sheet anatomy

```
┌─────────────────────────────────────┐
│              ━━━━━                  │  ← drag handle (4px × 36px, ink-border-strong)
│                                     │     centered, 8px from top
│  Cancel      Title.       Save xxx  │  ← title row (h3), buttons left + right
│  ─────────────────────────────────  │  ← 0.5px ink-border divider
│                                     │
│  [form sections...]                 │
│                                     │
└─────────────────────────────────────┘
```

- The sheet has rounded top corners (`radius-2xl`, 22px) and no rounded bottom corners (they meet the screen edge).
- The drag handle is interactive: dragging it down dismisses the sheet (with dirty-state confirmation if applicable).
- The Save button right-side is the same cobalt pill as the main schemas. Cancel left-side is a ghost button (coral text only, no fill, no border).
- The title row sits 12px below the drag handle and has 16px horizontal padding.
- Below the title row, a `0.5px solid ink-border` divider separates the header from the form body.

### 14.2 Sub-form height behavior

- The sheet auto-sizes to its content but caps at 90% of screen height. If content exceeds that, the form body scrolls; the header (drag handle + title row) stays pinned.
- Photo grids inside sub-forms (shutoff setup, etc.) push the sheet to the tall end of the range. Text-only sub-forms (project note, custom category) sit at the shorter end.

### 14.3 Stacked sheets

- When a sub-form triggers another modal (e.g. the link picker inside Phase form, or the Contact edit form from inside Add Contractor), the second sheet stacks on top of the first. The first sheet darkens to `rgba(7, 18, 56, 0.45)` overlay color but stays in place. Dismissing the second sheet returns to the first.
- Maximum stack depth: 2. If a third modal would be required (e.g. Premium upgrade sheet from inside a sub-form), the entire stack closes first and the Premium sheet opens fresh from the parent screen.

### 14.4 Save behavior in sub-forms

- Identical to main schemas (§11.1): cobalt button, disabled until required fields validate, on success the sheet dismisses.
- On dismiss, the parent screen refreshes the relevant section to show the new/edited record. No full screen reload — just the section.

### 14.5 Cancel behavior in sub-forms

- Identical to main schemas (§11.2). Dirty-state confirmation shows as an iOS-style action sheet *over* the modal sheet (above the stacked-modals system), not as a stacked sheet itself.

### 14.6 Delete in sub-forms

- Only the Edit variants of Phase, Project note, and Custom category support delete (these are the sub-forms where the record can exist independently of its parent screen as a meaningful unit).
- Add contractor's "delete" is "Remove from project" — it unlinks the contractor from the project but preserves the contact in the shared pool. This is the only sub-form where the delete copy changes meaningfully.
- Utility shutoff edit does NOT support delete — shutoffs are tied 1:1:1 to property×utility-type. Users can clear fields and save (which removes the "complete" status) but cannot delete the row.

### 14.7 Smart scan in sub-forms

- Smart scan is not available in any of the five sub-forms in §13. The integration adds visual complexity (frame outline, camera handoff) that's disruptive at sub-form scale, and none of these sub-forms have a clear OCR target (location descriptions are written by hand, phase names are user-chosen, note content is freeform).
- If a future sub-form has a clear scan target, the integration follows §11.5 rules unchanged.

---

## 15. Build order recommendation (updated)

The earlier §12 build order (for the eight main schemas) still applies. Sub-forms should be built **after** the main schemas, in this order:

10. **Sub-form A — Phase.** Validates the modal sheet pattern with a small form.
11. **Sub-form C — Project note.** Validates the auto-expanding textarea and date back-dating.
12. **Sub-form D — Utility shutoff setup.** Validates the dual-write offline pattern (Supabase + SQLite). This is the highest-stakes sub-form to get right.
13. **Sub-form B — Add contractor.** Validates the stacked-sheet pattern (link picker inside a sub-form, and Schema 3 transition into this form).
14. **Sub-form E — Custom category.** Validates the icon picker grid and the Free/Premium gate at the sub-form entry point.

By the time the Flutter agent reaches the sub-forms, the entire `AuroraForm*` widget kit from §12 is built and the patterns are proven. The sub-forms add: (a) the modal sheet container, (b) the stacked-sheets management, (c) the offline dual-write for shutoffs, and (d) the icon/color pickers (only used in custom category at v1, but reusable for future surfaces).

---

*End of Aurora form field schemas.*
