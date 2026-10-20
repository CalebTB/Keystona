# Sprint 3 (Home profile) pre-flight

Read-only research done 2026-10-20 before building: what each of the 13 kit screens shows and edits, where the kit and the live database disagree, what is shared between systems and appliances, routes, the scan-label contract, and the proposed 3-track split. Build agents read the sections for their screens; decisions made from it are in FOLLOW_UPS.md.

---

# Sprint 3 (Home profile) research report, read-only

Sources: all 13 `design/source/*.dc.html`. HomeProfile, HomeEdit, HomeSystems, ScanFlow, SystemDetail and HomeLifespan PNGs viewed; the rest taken from the HTML only. Also read: Implementation_Notes, BUILD_ORDER Sprint 3, legacy code, live DB (enums, constraints, function sources), and `scan-label/index.ts`.

**Kit-wide facts**
- Every `.dc.html` is a static mock. HomeProfile has an empty `renderVals()`. Other screens only hard-code demo data (1428 Elm Hollow Ln, Furnace, Washer) and local state.
- The kit defines NO skeleton, empty, error or offline variant for any of the 13 screens. Notes only say offline dims Scan and Add task with a snackbar.
- Style rules: no tinted fills (outline, solid lime or solid coral only), coral = act now, cobalt `#2540D8` = action, amber `#B08A00` / text `#6B4F00`, lime `#ECF87F` / `#4A6604`, touch targets ≥ 44.
- Lifespan color bands used everywhere (HomeSystems, HomeAppliances, HomeLifespan):

| Life used (p) | Bar color | Status text |
|---|---|---|
| < 75 | cobalt | none |
| 75–89 | amber | "AGING" |
| 90–100 | amber | "AT END OF LIFE" |
| > 100 | coral `#FF3B62` (text `#B12347`) | "PAST EXPECTED LIFE" |

- Age labels: `<1 yr` shows "N mo", otherwise whole or half years like "28½ yrs", rounded to the nearest 0.5.

---

## 1. Per kit screen

### 2.15 HomeProfile (`HomeProfile.dc.html`, no state, one long scroll, height 2250)

Top bar
- "‹ Home" → `Tabbed` (the Home tab).
- "Edit" → HomeEdit.
- Cover photo, 16:9, with a "FRONT OF HOUSE" tag. Blueprint-grid placeholder when there is no photo.

Header
- Eyebrow: `YOUR HOME · OWNED SINCE MAR 2024`.
- H1: street address.
- Facts line: `SINGLE-FAMILY · BUILT 1998 · 2,140 SQ FT · 4 BD · 2.5 BA · ZONE 4A`.

Lifespan callout (coral/amber outlined card)
- Title: "Water heater is at the end of its life".
- Sub: `12 YRS OF ~12 · BUDGET ~$1,800 FOR 2027`.
- Taps to HomeLifespan.
- Presumably shows only when some item is at or past end of life. Not defined.

Home Health section
- Heading `HOME HEALTH · 82`, trailing text `UP 4 SINCE SEP`.
- Three ring tiles:

| Tile | Score | Destination |
|---|---|---|
| UPKEEP | 78 | `Tasks` |
| RECORDS | 91 | `DocsSearchLed` |
| EMERGENCY | 80 | `EmergencyHub` |

- Ring color is coral in the mock for all three. A 52px ring is drawn with `stroke-dasharray`.

Systems section
- Heading `SYSTEMS · 5`, trailing `1 AGING` (amber).
- 5 rows: icon, name, age (`12 YRS`, `28½ YRS`, `4 MO`) and a short bar.
- Only the Furnace row has a real href (`SystemDetail`). The others are `#`, but should all go to their system detail.
- Two pill buttons below the rows: "All systems" → HomeSystems, "5 appliances" → HomeAppliances.
- Row card "Around the house", sub `14 REMINDERS NOT TIED TO A SYSTEM · 2 OFF` → HomeReminders (2.23, already built).

Next 5 years
- Heading `NEXT 5 YEARS`. Link "How long things last" → HomeLifespan.
- Card (taps to HomeLifespan): big `~$4,400`, "to replace 3 things".
- Copy: "The water heater and dishwasher come first. Setting aside about $75 a month covers it."
- 5-year bar chart: `$2.6K` 2027, `—` 2028, `—` 2029, `$1.8K` 2030, `—` 2031.

Project in progress
- Heading `PROJECT IN PROGRESS`. Card → ProjectDetail.
- Card text: "Primary bath renovation", `PHASE 3 OF 5`, a 5-segment phase bar.
- Under the bar: `$8,420 OF $14,500` and `FIXTURES $620 OVER` (coral).

Recently
- 4 rows, each with icon, title and meta:
  - "Replaced HVAC air filter", `TASK · FURNACE · SEP 28` → TaskDetail
  - "Tile delivered, 2 boxes short", `NOTE · BATH RENOVATION · OCT 1` → ProjectNotes
  - "Added washer warranty", `DOCUMENT · WASHER · SEP 24` → DocDetail
  - "Central AC installed", `SYSTEM ADDED · JUN 14 · $6,450` → `#`

The property
- Heading `THE PROPERTY`, "Edit" → HomeEdit.
- Key/value rows: BOUGHT `Mar 2024 · $318,000`; LOT `0.31 acres`; STORIES `2 + basement`; GARAGE `Attached · 2 cars`; CLIMATE `Zone 4A · mixed-humid`.

Home History Report card (dark navy)
- 86% ring. Title "Home History Report".
- Copy: "Your home's record, ready to share when you sell. Add the roof's install receipt to finish it."
- Taps to ReportBuilder (Sprint 9, Premium). Present in the kit now.

Bottom tab bar, Home active.

### 2.16 HomeEdit (`HomeEdit.dc.html`, fullscreen form)

Top bar
- "Cancel" → HomeProfile, with no discard prompt. Title "Edit home".
- "Save": a disabled grey pill while clean. It becomes a cobalt pill once any field differs from its initial value (`dirty`).
- Save → HomeProfile.

Fields
- **PHOTO**: a thumbnail tile ("FRONT OF HOUSE", `COVER` badge) plus a dashed "ADD" tile. Implies several photos, one of them the cover.
- **ADDRESS**: STREET (required, red `*`), CITY, STATE, ZIP.
- **KIND OF HOME**: 4 radio buttons: Single-family, Townhouse, Condo, Manufactured. Selected = solid navy.
- **SIZE & AGE**: YEAR BUILT, SQUARE FEET, LOT (ACRES), GARAGE (text field showing "Attached · 2 cars").
- Steppers:

| Stepper | Range | Step |
|---|---|---|
| BEDROOMS | 0–9 | 1 |
| BATHROOMS | 1–8 | 0.5 |
| STORIES | 1–4 | 1 |

- **WHEN YOU BOUGHT IT** (right label `OPTIONAL · ONLY YOU SEE THIS`): DATE ("Mar 2024"), PRICE ("$318,000").
- **CLIMATE**: read-only locked card, "Zone 4A · mixed-humid".

Validation and help text
- YEAR help: if not `^\d{4}$` and 1700 < y ≤ 2026 → `FOUR DIGITS, LIKE 1998`. If valid but changed → `REMINDERS AND LIFESPANS WILL UPDATE`.
- ZIP changed → `NEW ZIP · WE'LL RECHECK THE ZONE WHEN YOU SAVE`. Otherwise → `SET FROM YOUR ZIP · CAN'T BE CHANGED BY HAND`.

### 2.17 HomeSystems (`HomeSystems.dc.html`)

Top bar
- "‹ Home profile" → HomeProfile.
- "+ Add" outlined pill → ScanFlow.

Header and controls
- Eyebrow `1428 ELM HOLLOW · 5 TRACKED · 1 AGING`. H1 "Systems".
- Filter chips (horizontal scroll): "All 5", "Heating & cooling", "Water", "Structure", "Electrical". The "All N" count is dynamic.
- Count text `{n} SHOWN`. Sort toggle "Oldest first" (default, by percent of life used descending) / "A–Z".

List card, one row per system
- Icon, name, `model · location`, age (bold, colored by band) and "of ~12 yrs".
- Progress bar (width = min(100, p)%).
- Bottom-left: status (AGING / AT END OF LIFE / PAST EXPECTED LIFE), else a warranty note like `WARRANTY ENDS DEC 9`, else `REPLACE ~2038` (the demo labels this "REPLACE ~{year}" in the screens).
- Bottom-right: `2 TASKS` / `1 TASK`.
- Row → SystemDetail. Only Furnace is wired in the mock.

Untracked suggestions
- Heading `COMMON IN A 1998 HOME, NOT TRACKED YET`. The year comes from `year_built`.
- 6 dashed "+" chips: Plumbing, Windows, Sump pump, Insulation, Siding, Garage door. The chips have no href in the mock; presumably they open AddSystem with category and name prefilled.
- Caption `TRACKING THEM ADDS THEIR UPKEEP REMINDERS`.
- Dashed button "Scan a label to add one" → ScanFlow.

### 2.3 ScanFlow (`ScanFlow.dc.html`, 2 states)

The PNG shows the `choose` state as a bottom sheet over a dimmed Home tab.

Choose state
- Handle, `SMART SCAN`, title "What are you scanning?".
- Copy: "Point at the label with the brand, model and serial number. We'll fill in the rest."
- X close → Home.
- Two cards:
  - "A system", "HVAC, water heater, electrical panel, roof, plumbing", `5 IN YOUR HOME`
  - "An appliance", "Fridge, washer, dryer, dishwasher, oven", `5 IN YOUR HOME`
- Text link "No label? Add it by hand" → `#`. Destination is undefined; presumably the blank AddSystem or AddAppliance.

Camera state
- Black viewfinder with title "Scan a system label" or "Scan an appliance label".
- Top: back chevron, and a System | Appliance segmented control that can be switched in-camera.
- Frame corner brackets turn lime when the label is found. Flash toggle ("Turn flash on" / "Turn flash off").
- Hint pill, three states:
  - initial: "Fit the rating plate inside the frame" (system) or "Fit the model & serial sticker inside the frame" (appliance)
  - after about 1.4s: "Label found · hold still" (lime)
  - after capture: "Label read · 5 details found" (system) or "Label read · 6 details found" (appliance)
- Shutter button before capture. After capture, a "Review details →" button → AddSystem or AddAppliance. Also a "Type it in instead" link → `#`.
- The "label found" auto-detect and the "details found" counts are simulated. There is no loading or error state drawn.

### 2.4 AddSystem (`AddSystem.dc.html`, fullscreen form)

Top bar: "Scan" → ScanFlow. Eyebrow `HOME PROFILE · NEW`. H1 "Add a system."

Scan banner
- "We read 5 fields from the label". "The ones edged in blue came from it — check them, then save."
- "Rescan" → ScanFlow.
- A field carries an inset 3px cobalt left edge ("from scan") while its value equals the scanned value. The edge disappears once edited.
- Scanned fields: brand, model, serial, month, year.

Fields
- **CATEGORY** (required): select with 10 options in this order: HVAC, Plumbing, Electrical, Exterior, Interior, Roofing, Climate, Safety, Water, Foundation.
- **NAME** (required): hint `YOUR NAME FOR IT — E.G. "MAIN FLOOR HVAC"`.
- **IDENTIFICATION** (OPTIONAL): BRAND, MODEL, SERIAL NUMBER (with a camera icon; hint `FIND ON UNIT LABEL`).
- **INSTALL & LIFESPAN**: INSTALLED = Month select + Year select (2026 down to 1980). EXPECTED LIFESPAN = number input with "N years".
- Selecting a category resets lifespan to a median:

| Category | Years |
|---|---|
| hvac | 15 |
| plumbing | 50 |
| electrical | 40 |
| exterior | 30 |
| interior | 20 |
| roofing | 25 |
| climate | 15 |
| safety | 10 |
| water | 12 |
| foundation | 50 |

- Lifespan help text: `TYPICAL FOR HVAC · PLAN TO REPLACE AROUND 2036`. With no install year: `TYPICAL FOR HVAC — ADD THE INSTALL YEAR TO SEE WHEN`.
- Switch "Add its maintenance tasks" (default ON). The meta text depends on category:

| Category | Meta |
|---|---|
| hvac | `FILTER CHANGES · ANNUAL TUNE-UP · 3 TASKS` |
| plumbing | `LEAK CHECKS · SHUTOFF TEST · 2 TASKS` |
| roofing | `SPRING & FALL INSPECTION · 2 TASKS` |
| water | `FLUSH SEDIMENT · ANODE CHECK · 2 TASKS` |
| safety | `MONTHLY TEST · BATTERY SWAP · 2 TASKS` |
| other | `ROUTINE CHECKS FOR THIS SYSTEM` |
| switch OFF | `OFF · YOU CAN ADD TASKS YOURSELF` |

- **PHOTOS** (OPTIONAL): LABEL thumbnail plus 2 empty add slots. Caption `FREE PLAN · 4 PHOTOS · THE LABEL PHOTO IS SAVED FOR YOU`.

Footer
- "Cancel" → Home. "Save system" is a cobalt pill linking to SystemDetail only while a name is present. Otherwise it is disabled.
- Footer note: `REQUIRED * · EVERYTHING ELSE CAN WAIT`.

The kit form has no fields for location, installer, purchase price, warranty, notes or status. It is create-only copy ("NEW"), but SystemDetail's "Edit" → this same screen.

### 2.12 SystemDetail (`SystemDetail.dc.html`)

Top bar: "‹ Systems" → HomeSystems. "Edit" → AddSystem.

Header
- Eyebrow `HVAC · SYSTEM` plus an outlined lime "✓ HEALTHY" chip. H1 "Furnace". Sub "Northline NF95-080B · Basement utility room".

Hero photo
- Grid placeholder with a "UNIT" tag.
- A "📷 4 PHOTOS" badge → ItemPhotos.

LIFESPAN card
- "5½ yrs old" and "OF ~15 YRS EXPECTED".
- Bar with a tick at 100%. Left `INSTALLED MAR 2021`, right `REPLACE AROUND 2036`.
- Copy: "About **9½ years left**. A furnace this size runs about $5,800–7,200 to replace — we'll start planning with you around 2033."
- The "start planning" year is replace-year minus 3.
- The cost may be a range.

NEXT UP · {n}
- Rows with a check circle (toggle done, line-through when done), name, meta (`HVAC · 15 MIN · $25`), optional "PRO" chip, date:
  - "Replace HVAC air filter" `OCT 7`: amber check, "soon" state. Row → TaskDetail.
  - "Service the furnace" `PRO` `OCT 28`.
- Date shows `DONE` when completed.
- The count drops as items are checked.
- Link "All 5 HVAC tasks ›" → ItemTasks.

WARRANTY
- Card: "10-year parts warranty", `NORTHLINE · UNTIL MAR 2031`, lime "ACTIVE" chip.

IDENTIFICATION
- Rows: BRAND Northline, MODEL NF95-080B, SERIAL 2103A47719 (copy icon, which flips to `COPIED` for 1.4s), FUEL Natural gas, OUTPUT `80,000 BTU · 95% AFUE`, FILTER `16 × 25 × 1 · MERV 8`.

HISTORY · 3 (right: `$5,189 SINCE 2021`)
- Timeline entries: date, title, who/note, cost:
  - `OCT 2025` "Annual tune-up" / "Summit Heating & Air · receipt saved" / `$129`
  - `FEB 2025` "Replaced the igniter" / "Summit Heating & Air · under warranty" / `$210`
  - `MAR 2021` "Installed" / "Summit Heating & Air" / `$4,850`. Hollow dot (install).
- Dashed button "+ Log a repair or service" → `#`.

DOCUMENTS · 3
- Rows: "Northline warranty" (`WARRANTY · PDF · UNTIL MAR 2031`, → DocDetail); "Install invoice" (`RECEIPT · MAR 2021 · $4,850`); "Tune-up report" (`SERVICE · OCT 2025`).

No delete or archive UI and no status control.

### 2.19 ItemTasks (`ItemTasks.dc.html`)

Top bar: "‹ Furnace" → SystemDetail. "Manage" → ItemReminders. Eyebrow `FURNACE · NORTHLINE NF95-080B`. H1 "Furnace tasks".

Segmented tabs: "Coming up · 5" | "Done · 12".

Coming up
- Cards with a check circle, name, date (`OCT 7`; soon items get an amber border), then `EVERY 3 MONTHS`, a DIY or PRO pill and meta (`15 MIN · $25`). Meta omits cost if none (e.g. `2 MIN`).
- Rows in the demo:
  - Replace HVAC air filter, `EVERY 3 MONTHS`, DIY, `Oct 7`, 15 MIN, $25 (amber)
  - Service the furnace, `EVERY FALL`, PRO, `Oct 28`, 1 HR, ~$129
  - Test the CO detector by the furnace, `EVERY MONTH`, DIY, `Nov 1`, 2 MIN
  - Vacuum return vents, `TWICE A YEAR`, DIY, `Jan 15`, 20 MIN
  - Flush the condensate line, `EVERY SPRING`, DIY, `Apr 10`, 15 MIN, $5
- Marking done toggles the row and does not remove it.
- Footer dashed button "+ Add a furnace task" → AddTask.

Done
- Summary line: `$408` `SPENT ON UPKEEP SINCE 2025 · 12 TIMES`, with a lime "ON SCHEDULE" chip.
- Rows with a done check, title, `JUL 6 · CALEB` and cost:
  - Replaced HVAC air filter, `JUL 6 · CALEB`, $22
  - Annual tune-up, `OCT 2025 · SUMMIT HEATING & AIR`, $129
  - Replaced HVAC air filter, `APR 4 · CALEB`, $22
  - Flushed condensate line, `MAR 30 · CALEB`, no cost
  - Replaced the igniter, `FEB 2025 · UNDER WARRANTY`, $210
- Footer link `+ 7 EARLIER · BACK TO MAR 2021`.

Only the first task has a real href (TaskDetail).

### 2.20 ItemPhotos (`ItemPhotos.dc.html`)

Top bar: "‹ Furnace" → SystemDetail. Position text `2 OF 4`. Eyebrow `FURNACE · NORTHLINE NF95-080B`. H1 "Photos".

Viewer
- Large image with a tag, e.g. `LABEL`.
- Prev and next buttons (wrap around).
- A "⛶" button (`#`, presumably opens PhotoViewer 8.4).
- Caption "Rating label" and meta `SEP 2026 · SCANNED · MODEL + SERIAL READ`.

Thumbnails and plan limit
- 4-up thumbnail grid with the selected one outlined and tag text on each.
- Free-plan row: "4 of 4 photos on Free", `PREMIUM KEEPS EVERY PHOTO · YOU'RE ON THE TRIAL`, with an "Add" button.
- Demo photos:

| Caption | Tag | Meta |
|---|---|---|
| The unit | UNIT | `MAR 2021 · FROM THE PREVIOUS OWNER` |
| Rating label | LABEL | `SEP 2026 · SCANNED · MODEL + SERIAL READ` |
| Filter slot | FILTER | `SEP 28 · 16×25×1 MERV 8` |
| New igniter | REPAIR | `FEB 2025 · SUMMIT HEATING & AIR` |

Guidance list "GOOD PHOTOS TO HAVE" (furnace-specific):
- "The rating label — model and serial in one shot"
- "The whole unit with space around it"
- "Where the filter goes, with the size showing"
- "The shutoff switch and gas valve nearby"

The copy shows the guidance is per item type.

### 2.22 ItemReminders (`ItemReminders.dc.html`)

Top bar: "‹ Furnace tasks" → ItemTasks. "Done" → ItemTasks. Eyebrow `FURNACE · NORTHLINE NF95-080B`. H1 "Furnace reminders".

Intro copy: "Turn off anything that doesn't fit your furnace, or change how often it comes up. Turned-off reminders don't count toward Home Health."

ON · {n} (`SHOWS IN YOUR TASKS`)
- Rows with a switch plus an inline "how often" select. Frequency options: Every month, Every 3 months, Twice a year, Every year, Every spring, Every fall, Every November.
- The current value is added if it is not in the list.
- Optional tag chip ("PRO"). Off rows show a reason text instead of the select.
- Demo rows:
  - Replace HVAC air filter, Every 3 months
  - Service the furnace, Every fall, PRO
  - Test the CO detector by the furnace, Every month
  - Vacuum return vents, Twice a year
  - Flush the condensate line, Every spring

TURNED OFF · {n} (`HIDDEN EVERYWHERE`), only if any
- Muted rows with a switch (off) and a reason:
  - Replace the humidifier pad, `OFF SINCE SEP 12 · NO WHOLE-HOUSE HUMIDIFIER`
  - Check the flue pipe for rust, `OFF SINCE SEP 12 · SUMMIT CHECKS IT AT THE TUNE-UP`
- Default reason when none: `YOU TURNED THIS OFF`.

Footer
- "Add your own furnace task" → AddTask.
- Caption `SUGGESTIONS COME FROM THE FURNACE TYPE, ITS AGE AND YOUR CLIMATE`.

Per the Notes, climate-generated reminders carry a reason tag (FREEZE / HUMID / STORMS), and user-created reminders get Edit and Delete instead of a switch. The kit shows only PRO tags. The Notes say the main place to manage reminders is "each parent's reminders screen". The existing `HomeRemindersScreen` (whole-house, 2.23) already implements the same pattern, so it can be reused or generalized.

### 2.18 HomeAppliances (`HomeAppliances.dc.html`)

Same shell as HomeSystems.
- "‹ Home profile" → HomeProfile. "+ Add" → ScanFlow.
- Eyebrow `1428 ELM HOLLOW · 5 TRACKED · 1 PAST ITS LIFE`. H1 "Appliances".
- Chips: "All 5", "Kitchen", "Laundry". These are data-driven categories. Sort "Oldest first" / "A–Z". `{n} SHOWN`.
- Rows are identical in structure to systems:

| Row | Detail |
|---|---|
| Dishwasher | `Brennan DW24 · Kitchen`, 11½ yrs of ~10, PAST EXPECTED LIFE (coral), 1 TASK |
| Refrigerator | `Brennan FR36-SxS`, 9½ of ~13 |
| Range | `Brennan GR30 gas`, 9½ of ~15 |
| Washer | `Halden HW45-FL2 · Laundry room`, 3 yrs of ~11, `WARRANTY ENDS DEC 9`, 2 TASKS. The only row linked → ApplianceDetail |
| Dryer | `Halden HD45-E`, 3 yrs of ~13, 1 TASK |

- Suggestions: `OFTEN FORGOTTEN`, chips Microwave, Garbage disposal, Water softener, Freezer. Caption `TRACKING THEM ADDS THEIR UPKEEP REMINDERS`.
- Dashed button "Scan a label to add one" → ScanFlow.

Legacy-only behavior not in the kit: a free-limit banner at 8 appliances (`_kFreeLimitWarningAt` in `appliances_screen.dart`).

### 2.5 AddAppliance (`AddAppliance.dc.html`)

Same shell and scan banner as AddSystem. Eyebrow `HOME PROFILE · NEW`, H1 "Add an appliance.", "We read 6 fields from the label".

Fields
- **CATEGORY** (required): Laundry, Kitchen, Climate, Cleaning, Outdoor, Bathroom. The enum also has `other`.
- **NAME** (required): hint `YOUR NAME FOR IT — E.G. "MAIN FRIDGE"`.
- **IDENTIFICATION** (OPTIONAL): BRAND, MODEL, SERIAL, COLOR.
- **PURCHASE** (OPTIONAL): PRICE ($), RETAILER, PURCHASE DATE (free text).
- Switch "It has a warranty" (hint `WE'LL TRACK THE EXPIRATION DATE`), default OFF. When ON:
  - PROVIDER, EXPIRES.
  - Button "Link the warranty from Docs" (`#`).
- **SPECIFICATIONS** (collapsible, label `3 SCANNED` / `HIDE`), default collapsed:
  - CAPACITY ("4.5" + "cu ft")
  - TYPE segmented: Front-load, Top-load, Stackable
  - Switch "ENERGY STAR certified" (`READ FROM THE LABEL`), default ON
- **PHOTOS**: same as AddSystem.
- Footer "Cancel" / "Save appliance" (required: name) → ApplianceDetail.

Scanned fields: brand, model, serial, cap, config. The scanned demo data is Halden HW45-FL2, serial HL3390218K, 4.5 cu ft, front-load. There is no lifespan field and no "add tasks" switch on this form, unlike AddSystem. There is no location field.

### 2.13 ApplianceDetail (`ApplianceDetail.dc.html`)

Top bar: "‹ Appliances" → HomeAppliances. "Edit" → AddAppliance.

Header
- `LAUNDRY · APPLIANCE`, "✓ HEALTHY" chip. H1 "Washer". Sub "Halden HW45-FL2 · Laundry room".

Warranty callout (coral/amber outlined), shown when the warranty ends soon
- Heading `WARRANTY ENDS IN 66 DAYS`, "Covered until Dec 9."
- Copy: "Any noise, leaks or slow draining? Get it looked at while repairs are still free."
- Button "Add a check before Dec 9". After tapping it becomes `✓ Added to Tasks · Nov 25`, and toggles back on a second tap.
- This creates a one-off task.

Other sections
- Hero photo and a "UNIT 3 PHOTOS" badge. The button is `#` here, with no ItemPhotos link.
- LIFESPAN card: "3 yrs old", "OF ~11 YRS EXPECTED", `BOUGHT DEC 2023` (not "INSTALLED"), `REPLACE AROUND 2034`. Copy: "About **8 years left**. Front-loaders last longest when the door is left open to dry and the drain filter stays clean." The copy is appliance-type-specific. The cost sentence is absent.
- NEXT UP · 2:
  - "Wipe the door gasket", `LAUNDRY · 5 MIN · DIY`, `OCT 19`
  - "Clean the drain filter", `LAUNDRY · 20 MIN · DIY`, `JAN 18`
  - Link "All 4 appliance tasks ›" → **TasksAllYear** (not ItemTasks, unlike SystemDetail).
- PURCHASE rows: PRICE $849, FROM Brightway Appliance, BOUGHT Dec 9, 2023, WARRANTY "Halden + Brightway Care" / `ENDS DEC 9, 2026`.
- IDENTIFICATION: BRAND, MODEL, SERIAL (copy), COLOR.
- SPECIFICATIONS · 5 (collapsible, default open; shows `HIDE` / `SHOW`): CAPACITY 4.5 cu ft, TYPE Front-load, SPIN SPEED 1,300 RPM, HOOKUP `Hot + cold · 120 V`, ENERGY STAR Certified (check).
- HISTORY · 2 (`$883 SINCE 2023`):
  - `JUN 2025` "Replaced the inlet hoses" / "Did it myself · steel-braided" / $34
  - `DEC 2023` "Bought & installed" / "Brightway Appliance · delivery included" / $849
  - "+ Log a repair or service" (`#`).
- DOCUMENTS · 3: "Washer warranty" (`WARRANTY · ENDS DEC 9`), "Receipt" (`BRIGHTWAY · DEC 2023 · $849`), "Owner's manual" (`MANUAL · PDF · 64 PAGES`).

### 2.21 HomeLifespan (`HomeLifespan.dc.html`)

Top bar: "‹ Home profile" → HomeProfile. Eyebrow `10 THINGS · SYSTEMS AND APPLIANCES`. H1 "How long things last".

Summary
- Big total (`$` sum of lowest-cost replacements for items ending before 2032, **respecting the current tab**), with sub "due in the next 5 years".
- Footnote: "Ages come from install dates and scanned labels. Expected lives are typical for your climate, not a promise."

Tabs and timeline
- Tabs: "All 10", "Systems", "Appliances" (counts dynamic).
- Timeline x-axis is fixed 2008–2042. Ticks 2010, 2020, 2040 plus a "TODAY" marker line.
- Per row: name, end text (`REPLACE ~2038`, or `PAST ITS LIFE · REPLACE ANY TIME` if p > 100, or `REPLACE ~{max(2027, year)}` if p ≥ 90), a bar spanning install to end year, filled up to today. A red hatched segment shows overrun past the end.
- Meta line: `INSTALLED 2021 · 5½ YRS OF ~15` (`SINCE 1998` if the install is before 2008).
- Cost on the right (`~$1,800` or a range `$5,800–7,200`).
- Rows sorted by percent used descending. Legend `PLENTY LEFT` / `LAST QUARTER` / `PAST EXPECTED LIFE`.
- The Furnace row links to SystemDetail and the Washer row to ApplianceDetail. The rest are `#`.

WHAT TO SET ASIDE (PREMIUM tag)
- Table of 2027–2031: year, what (item names uppercase, or `NOTHING EXPECTED`), amount (`$2,600`, or `—`), with an inline bar.
- Past-due items are bucketed into 2027.
- Footer: `ABOUT $73 A MONTH COVERS ALL OF IT · LOWEST-COST ESTIMATES` (total over 60 months).
- Not tab-filtered.

---

## 2. DATA GAPS

Ordered by how much UI depends on them. Schema verified live.

1. **Category taxonomy mismatch (breaks AddSystem, HomeSystems chips, scan mapping)**
   - DB `system_category` = hvac, plumbing, electrical, roofing, foundation, siding, windows_doors, insulation, garage, other.
   - The AddSystem select shows HVAC, Plumbing, Electrical, Exterior, Interior, Roofing, Climate, Safety, Water, Foundation. Exterior, Interior, Climate, Safety and Water do not exist. siding, windows_doors, insulation, garage and other are missing from the kit.
   - The HomeSystems filter chips (Heating & cooling / Water / Structure / Electrical) need a client-side map. Suggested: hvac→Heating & cooling, plumbing→Water, electrical→Electrical, roofing/foundation/siding/windows_doors/insulation/garage→Structure.
   - The lifespan medians table (exterior 30, interior 20, climate 15, safety 10, water 12) cannot be keyed to the enum. Either add enum values (migration) or remap the kit select.
   - The scan-label function returns the DB enum values for systems.
   - `appliance_category` (kitchen, laundry, climate, cleaning, outdoor, bathroom, other) matches the kit's AddAppliance chips (kit omits `other`).
2. **Item history ("Log a repair or service", HISTORY timeline, "SINCE 2021" totals) has no store.**
   - `task_completions.task_id` is NOT NULL and there is no linked_system_id on it. A completion can only reach the item via its parent task.
   - Needs a new table, e.g. `item_service_log(id, user_id, property_id, system_id, appliance_id, kind enum[installed,service,repair,purchased], service_date, title, provider, cost numeric, note, under_warranty bool, document_id)`.
   - Alternatively, a task+completion with `log_to_item_history=true`: that flag already exists, but the installed and purchase rows still need a source (from install_date / purchase_price).
   - Affects SystemDetail, ApplianceDetail, and the ItemTasks "Done" tab (which can be served by `task_completions` joined to `maintenance_tasks.linked_*_id`; it has service_cost, materials_cost, completed_by, contractor_company).
3. **Per-type extra identification and specs on systems (FUEL, OUTPUT, FILTER).**
   - `systems` has no `specifications jsonb` (appliances does). Needs `systems.specifications jsonb`.
   - Scan's `notes` for systems is one free sentence, so no structured fuel/output/filter. Appliance scan `notes` returns "Label: Value" lines. These must be parsed into `appliances.specifications` (CAPACITY, TYPE, SPIN SPEED, HOOKUP, ENERGY STAR).
4. **Lifespan data for appliances.**
   - `get_system_lifespan_overview(p_property_id)` covers **systems only**. HomeLifespan, HomeProfile "Next 5 years" and "~$4,400" need systems and appliances. The RPC needs an appliance UNION, or a new RPC `get_item_lifespan_overview` returning `kind`.
   - Appliances age from `purchase_date` (no `installation_date`). The row returns `install_date` only for systems.
   - The RPC uses `expected_lifespan_min/max`, with `lifespan_override` applied to both. Its status thresholds are aging ≥ 0.75×min and end_of_life ≥ max. The kit uses percent-of-single-life 75 / 90 / 100 bands. Compute in Dart, or add the percent and the "~N" single life. The kit's "REPLACE ~2038" is install + life, taking the midpoint or the override.
   - Appliances have `expected_lifespan_min/max` in the DB (confirmed via the column query) but the legacy `Appliance` model does not read them. The AddAppliance form has no lifespan field.
5. **Task counts per item (`2 TASKS`).** No view or aggregate. Needs a grouped query over `maintenance_tasks` by `linked_system_id` / `linked_appliance_id` (or an RPC/view `item_task_counts`).
6. **Home Health breakdown (Upkeep 78 / Records 91 / Emergency 80) and "UP 4 SINCE SEP".**
   - `get_home_health_score` returns JSON with `score, trend (string), total_tasks, completed, overdue, upcoming` (maintenance pillar only; `HomeHealthScore.fromRpc`).
   - No records or emergency sub-scores, and no numeric trend delta or history table (a monthly score snapshot table is needed for "since SEP").
   - Also affects the Home tab (Sprint 6).
7. **Recently feed** is derived from four tables: task_completions, project_journal_notes, documents and systems/appliances created. There is no activity or event table. A UNION RPC or an `activity_events` view is required. The "SYSTEM ADDED · JUN 14 · $6,450" row uses `systems.created_at` and `purchase_price`.
8. **Property gaps (HomeProfile, HomeEdit)**
   - Climate label "Zone 4A · mixed-humid": `climate_zone` is `smallint` (4 only). The "A/B/C" moisture subzone and "mixed-humid" name cannot be stored. Add `climate_zone_label text` or `climate_subzone char`, or derive from a static lookup table.
   - Recheck-on-ZIP-change is promised in copy. Existing climate lookup is unclear (only onboarding theme mentions "climate"). A ZIP→zone service/edge function is needed.
   - "2 + basement": `stories` is smallint, no basement flag. Add `has_basement boolean` (or `basement_type`).
   - "Attached · 2 cars" is one text field in the kit. DB has `garage_type` (text) + `garage_spaces`. A parse/format is needed.
   - Lot acres: `lot_size_sqft` int. Convert (0.31 ac ≈ 13,504 sq ft).
   - Multiple photos with a COVER badge ("ADD" tile): DB has a single `exterior_photo_path`. Either restrict to one photo or add a `property_photos` table. Bucket `property-photos` is public=true.
   - `property_type`: kit Single-family / Townhouse / Condo / Manufactured; legacy extension maps `single_family|condo|townhouse|multi_family|mobile`. There is no DB check constraint, so any text is accepted. Pick the strings: kit "Manufactured" = legacy `mobile`.
   - `county` exists in the schema but is not in the kit.
   - Purchase date: the kit's field is free text "Mar 2024". The column is `date`. Needs a month/year picker with a day default.
9. **Warranty detail on systems.** SystemDetail "10-year parts warranty / NORTHLINE · UNTIL MAR 2031" needs a warranty title. `systems` has `warranty_provider`, `warranty_expiration`, `linked_warranty_doc_id` only. Title could come from the linked doc name, or add `warranty_label text`.
   - ApplianceDetail: "Halden + Brightway Care" fits `warranty_provider`.
   - "Link the warranty from Docs" maps to `linked_warranty_doc_id` on appliances (legacy reads it), and likewise for systems.
10. **Warranty "Add a check before Dec 9" task.** The action is supported by `maintenance_tasks` (due_date). The "already added" state (`Added to Tasks · Nov 25`) needs a way to find the task, e.g. `tags` containing 'warranty-check' or a `task_origin` value.
11. **ItemPhotos fields.**
    - `photo_type` is free text NOT NULL with no check constraint. Kit tags UNIT / LABEL / FILTER / REPAIR differ from the legacy set (overview, model_label, location, condition, maintenance, other). Pick a mapping.
    - There is no "taken date" (only `created_at`) and no provenance. The meta line (`SEP 2026 · SCANNED · MODEL + SERIAL READ`) would have to be generated from caption + created_at + a type flag.
    - "4 photos on Free": enforce client-side via `isPremiumProvider`. No server limit.
12. **System/appliance location on the form.** The list and detail rows show "Basement utility room" / "Laundry room", and `location` exists in the DB. The kit's Add forms have no location input (legacy does).
    - Also absent from the kit forms: installer, purchase price and notes (systems); status (systems).
    - A product decision is needed (see Q).
13. **Suggestion chips** (`COMMON IN A 1998 HOME`, `OFTEN FORGOTTEN`) need a static template list keyed by year_built and a mapping to category and system_type. "Sump pump", "Water softener" and "Garbage disposal" have no direct enum category, so use `system_type` and `name` under plumbing or other.
14. **ItemReminders data.** Supported by `maintenance_tasks.notifications_enabled`, `notifications_off_at`, `notifications_off_reason`, `reminder_days_before`, `recurrence`, `tags`. Needs:
    - Reason strings like `NO WHOLE-HOUSE HUMIDIFIER`, stored in `notifications_off_reason`.
    - A way to flag PRO (`diy_or_pro` exists).
    - A "how often" choice mapped to recurrence enum plus season (Every spring/fall/November) — needs a check against the recurrence enum values and `season` text.
    - Suppressing off tasks from health is handled in the score RPC by the notes' rule. Verify that it excludes them.
15. **Project in progress card** uses `projects`, `project_phases` (`sync_phase_count`) and `get_project_budget_summary`. "FIXTURES $620 OVER" needs per-category over-budget from `project_budget_items`. Gap is minor.
16. **Home History Report card "86%"**: record-completeness score. No source until Sprint 9. Mock/placeholder.
17. **Destructive actions.**
    - `soft_delete_system(uuid)` and `soft_delete_appliance(uuid)` exist (SECURITY DEFINER style, check `user_id = auth.uid()`). Legacy `SystemsNotifier.deleteSystem` does a plain `.update({'deleted_at':...})`, which will fail with 42501. Must use `.rpc('soft_delete_system')`. Check the appliances provider and detail providers too.
    - The kit has no delete UI, so this only matters if the detail keeps its delete bar (legacy `_DeleteBar`, `_DeleteConfirmSheet`; kit has the `ConfirmDelete` screen).
    - `delete_system_photo` function and `system-photos` bucket also exist besides `item-photos`. Legacy uploads to `item-photos`.

**Legacy models reading or missing things vs schema**
- `HomeSystem` is missing `linkedWarrantyDocId`, `replacedBySystemId`, `deletedAt`. It reads all other columns correctly (`model` mapped to `modelNumber`).
- `Appliance` is missing `retailer`, `specifications`, `expectedLifespanMin/Max`, `replacedByApplianceId`. It reads `purchaseDate`, `color`, `warrantyProvider`, `linkedWarrantyDocId` (all exist).
- `Property` (`property.dart`) is missing lot_size_sqft, garage_type, garage_spaces, purchase_date, purchase_price, down_payment, county, address fields beyond line1/2. It declares `propertyType` as non-null `required String`, but the column is nullable. This is a crash risk. `bedrooms` is read as double, which is fine for smallint.
- `Property.climateZone` is read as `int?`, which is fine.
- The fetch in `home_profile_provider.dart` selects only a subset of property columns. HomeEdit needs the full set.
- `SystemLifespanEntry` matches the RPC columns. It leaves `lifespan_min/max` as smallint → int. It classifies with RPC `health_status` (`healthy|aging|end_of_life|unknown`), not the kit's 75/90/100 bands.
- `HomeProfileOverview`: `systemsNearingEndOfLife` is computed client-side as percent ≥ 0.75 of the avg, which conflicts with the RPC's rule (min × 0.75 vs max).
- `ItemPhoto` matches the table. The schema's CHECK allows exactly one of `system_id` / `appliance_id`.
- `LabelScanResult` (`services/label_scanner_service.dart`) matches the Edge Function JSON (adds category, lifespan, cost, notes).

---

## 3. Cross-screen sharing

**Same component for systems and appliances (one screen, parameterized by `systemId | applianceId`)**
- **ItemTasks, ItemPhotos, ItemReminders**: legacy `ItemTasksScreen(systemId?, applianceId?, itemName)` already takes both. ItemPhotos and ItemReminders are new and should do the same. In the kit only the system variant is drawn. Copy is parameterized by item name ("Furnace tasks", "Add a furnace task", "Add your own furnace task"). ItemPhotos guidance list and ItemReminders suggestion caption are type-specific content.
- **ScanFlow**: one screen with a System | Appliance toggle (`kind`). It outputs the same prefill to either form.
- **List screens (HomeSystems / HomeAppliances)**: structurally identical: eyebrow, H1, chips, "N SHOWN", sort, row card, suggestions chips, dashed "Scan a label to add one". They differ only in data, chip source, the "tracked" caption, and the suggestion set.
- **Forms (AddSystem / AddAppliance)**: same chrome (scan banner with "Rescan", from-scan edge, category select, name, Identification, Photos, footer). Differences: system has an Install & Lifespan + "Add its maintenance tasks" switch; appliance has Color, Purchase, Warranty switch, Specifications.
- **Detail shells (SystemDetail / ApplianceDetail)**: same hero, Lifespan card, Next up, Identification card, History, Documents. Appliance adds the warranty callout, Purchase card and collapsible Specifications. System adds the Warranty card.

**Shared widgets appearing 3+ times (candidates for shared feature widgets)**
1. **Lifespan band math + bar** (`LifespanReading`: age label, percent, band color, status text, replace-year): HomeSystems, HomeAppliances, HomeLifespan, SystemDetail, ApplianceDetail, HomeProfile systems rows and callout.
2. **Item row** (icon tile, name, model·location, age + "of ~N", bar, status/replace text, "N TASKS"): HomeSystems, HomeAppliances. A compact variant is on HomeProfile and a timeline variant on HomeLifespan.
3. **Filter chips + sort toggle**: HomeSystems, HomeAppliances. A tab-pill variant is on ItemTasks and HomeLifespan.
4. **Check-circle task row** (done toggle, strike-through, `PRO` chip, date): SystemDetail, ApplianceDetail, ItemTasks, HomeProfile "Recently". `AuroraTaskRow` already exists in `core/widgets/aurora/aurora_task_row.dart`.
5. **Switch row**: AddSystem, AddAppliance, ItemReminders, HomeEdit. `aurora_toggle_row.dart` exists.
6. **Grid-placeholder photo tile / hero** with a corner tag: HomeProfile, HomeEdit, SystemDetail, ApplianceDetail, ItemPhotos, AddSystem/AddAppliance photos.
7. **Key-value info card** (label left, value right, optional copy icon): HomeProfile "The property", SystemDetail Identification, ApplianceDetail Identification/Purchase/Specifications.
8. **History timeline card** + "Log a repair or service" dashed button: SystemDetail, ApplianceDetail.
9. **Documents list card**: SystemDetail, ApplianceDetail.
10. **Dashed suggestion chips** and a **dashed "Scan a label" button**: HomeSystems, HomeAppliances.
11. **Scan field edge** (inset 3px cobalt "from scan" decoration): AddSystem, AddAppliance.
12. **Mono-caps section label** (10px, tracked): every screen.
13. **Stepper row**: HomeEdit.
14. **Segmented control**: HomeEdit (kind of home), AddAppliance (type), ScanFlow (System | Appliance).

Existing legacy widgets: `system_card`, `appliance_card`, `lifespan_card`, `*_skeleton`, `*_empty_state`, `system_photo_strip`. They are old design; the kit has no empty state for the lists, so the empty states and skeleton shapes will need product input or reuse of `core/widgets/empty_state.dart` and `loading_skeleton_card.dart`.

---

## 4. Entry points and routes

**How each screen is reached (kit hrefs)**
- **HomeProfile**: from the Home tab (`Tabbed`) hero card ("Your home · 5 systems · 5 appliances · 1 AGING", visible in the ScanFlow PNG, which says the home-health card is tappable). The kit has no explicit href in this repo's files pointing to HomeProfile except back-links from HomeSystems / HomeAppliances / HomeLifespan / HomeEdit ("‹ Home profile"). It is also back-target of HomeEdit Cancel/Save.
- **HomeEdit**: HomeProfile top "Edit"; HomeProfile "THE PROPERTY › Edit".
- **HomeSystems**: HomeProfile "All systems".
- **HomeAppliances**: HomeProfile "5 appliances".
- **HomeLifespan**: HomeProfile callout, "How long things last", and the 5-year card.
- **ScanFlow**: HomeSystems and HomeAppliances "+ Add" and "Scan a label to add one"; AddSystem and AddAppliance "Scan" and "Rescan"; the Home tab "Scan" button (per Notes, dimmed offline).
- **AddSystem / AddAppliance**: ScanFlow "Review details"; the "type it in / by hand" links (undefined `#`); the HomeSystems / HomeAppliances suggestion chips (presumably); SystemDetail / ApplianceDetail "Edit" (edit mode).
- **SystemDetail**: HomeSystems rows; HomeProfile systems rows; HomeLifespan row; AddSystem Save; ItemTasks back.
- **ApplianceDetail**: HomeAppliances rows; HomeLifespan row; AddAppliance Save.
- **ItemTasks**: SystemDetail "All 5 HVAC tasks"; ItemReminders "Done" and back. ApplianceDetail does NOT link it (it links `TasksAllYear`).
- **ItemPhotos**: SystemDetail "4 PHOTOS" badge only.
- **ItemReminders**: ItemTasks "Manage".

**AppRoutes coverage**
- Existing in `lib/core/router/app_router.dart`:
  - `homeSystems` → `SystemsScreen`
  - `homeSystemsAdd` → `SystemFormScreen(extra: HomeSystem?)`, fullscreenDialog
  - `homeSystemDetail` → `SystemDetailScreen`
  - `homeSystemTasks` → `ItemTasksScreen(systemId, itemName from extra)`
  - `homeAppliances` / `homeAppliancesAdd` / `homeApplianceDetail` / `homeApplianceTasks`, same pattern
  - `homeEdit` (`/home/edit`) → `PropertyEditScreen`, fullscreenDialog
  - `homeLifespan` → `LifespanScreen`
  - `homeReminders` → `HomeRemindersScreen` (already built; not in the 13)
- **Missing routes**:
  - HomeProfile: `/home/profile` (`AppRoutes.homeProfile`) plus its screen file. It does not exist. Legacy `HomeScreen` (the Home tab, `/home`) links directly to systems/appliances/lifespan tiles and pushes `homeEdit` from the address row. HomeEdit's Cancel/Save/back must `pop` to HomeProfile.
  - ScanFlow: `/home/scan` (`AppRoutes.homeScan`), taking `kind` (system|appliance) and optionally returning a `ScanPrefill`. Today scanning is a `ScanLabelButton` inside each form (camera action sheet, then a confirmation sheet, then "Fill Form").
  - ItemPhotos: `/home/systems/:systemId/photos`, `/home/appliances/:applianceId/photos`.
  - ItemReminders: `/home/systems/:systemId/reminders`, `/home/appliances/:applianceId/reminders` (distinct from the existing `/home/reminders`).
  - Add routes carry edit extras (`HomeSystem?` / `Appliance?`). Adding a prefill needs a typed args object.
- Router wiring note: `ItemTasksScreen.itemName` comes from `state.extra as String?`, which falls back to 'System' on deep link. Better to load the name by id.
- The legacy `HomeScreen` is the Sprint 6 Home tab; do not edit it in Sprint 3 except for a link to HomeProfile.

---

## 5. Backend dependencies

`supabase/functions/scan-label/index.ts`
- POST, JSON. Auth via Bearer JWT (`auth.getUser(token)` with the service-role client). 401 plain text "Unauthorized" if invalid.
- Request: `{ imageBase64: string, mimeType: 'image/jpeg'|'image/png'|'image/heic'|'image/webp', formType?: 'system'|'appliance' }` (default = system prompt). 400 `{error}` if imageBase64 or mimeType is missing.
- Calls Anthropic `v1/messages`, model `claude-opus-4-8`, `max_tokens: 768`. Returns the parsed JSON directly.
- Response (200):
  - system: `{brand, modelNumber, serialNumber, name, manufactureDate ("YYYY-MM"|"YYYY"|null), estimatedYear, category (hvac|plumbing|electrical|roofing|foundation|siding|windows_doors|insulation|garage|other), estimatedLifespanYears, estimatedReplacementCostUsd, notes (one sentence|null)}`.
  - appliance: same, with `category` in kitchen|laundry|climate|cleaning|outdoor|bathroom|other, and `notes` as multi-line "Label: Value".
- Errors: 500 `{error}` for no API key or any thrown error (JSON.parse failure included, reported to Sentry). 502 `{error: "Vision API error"}` on Anthropic failure.
- Client: `LabelScannerService.scanImage(XFile, {isAppliance})` in `services/label_scanner_service.dart` returns `LabelScanResult` and throws on `{error}`. `fieldCount` counts brand, model, serial, name, category, lifespan, mfg.

What ScanFlow needs vs what the function gives
- Brand, model and serial are provided (kit reads 5 or 6 fields).
- Install month/year in the kit comes from `manufactureDate` or `estimatedYear`. That is the **manufacture** date, not the install date. The kit pre-fills "Installed Mar 2021" and tags it "from scan". This is a semantic mismatch (see Q).
- The kit's "6 details found" for appliances (brand, model, serial, capacity, type, Energy Star) requires parsing `notes` lines into specs. The function does not return a structured `type` (Front-load), `capacity` or `energyStar`, only lines in `notes`. Recommend changing the prompt to return a `specifications` object for appliances, and `fuelType`, `outputBtu` etc. for systems (FUEL/OUTPUT/FILTER).
- **Not producible**: "Label found · hold still" live auto-detect (needs on-device detection or is mocked; the function only runs after a shot), the confidence per field, and a bounding box. The system category ids from the function (siding, windows_doors, ...) do not match the kit's AddSystem select (see gap 1).
- The category lifespan defaults in the kit (client table) differ from the function's `estimatedLifespanYears` (AC 15, furnace 20, panel 35, roof 25, water heater 12). Decide which wins when the scan has both.
- The scanned label photo must be stored as an item photo (type "label") after save. `item-photos` bucket exists (private) and the `item_photos` insert policy is available. Legacy forms upload on save. The kit says "THE LABEL PHOTO IS SAVED FOR YOU".
- Max image size and HEIC handling: the client sends base64 of a picker image (`imageQuality 85`, `maxWidth 1600`). A loading/"Reading…" state exists only in the legacy `ScanLabelButton` ("Reading label...", error copy "Couldn't read any info from that label. Try a clearer photo." and "Something went wrong. Check your connection and try again."). The kit does not draw those states.
- Task generation after save: legacy calls the `generate-maintenance-tasks` Edge Function with `{property_id, system_id}`. The AddSystem "Add its maintenance tasks" switch should gate this. For appliances there is `generate-item-tasks`. Contracts for `generate-item-tasks`, `schedule-next-task` were not inspected.

**Other backend dependencies**
- New RPC or extension for lifespan on appliances (gap 4).
- Counts RPC/view for tasks per item (gap 5).
- Possibly new table `item_service_log` and `systems.specifications` (migration-writer skill).
- The Premium gating (`isPremiumProvider`, `UpgradeSheet`) exists in `core/widgets/upgrade_sheet.dart`.

---

## 6. Proposed split into 3 parallel tracks

All paths under `apps/keystona/lib/features/home_profile/` unless noted. Disjoint legacy files:

**Track A: Home overview, edit, lifespan (HomeProfile 2.15, HomeEdit 2.16, HomeLifespan 2.21)**
- Owns: `screens/property_edit_screen.dart`, `screens/lifespan_screen.dart`, NEW `screens/home_profile_screen.dart`, `providers/home_profile_provider.dart(+.g)`, `providers/lifespan_provider.dart(+.g)`, `models/property.dart(+gen)`, `models/home_profile_overview.dart`, `models/system_lifespan_entry.dart`, `widgets/lifespan_card.dart`, `widgets/lifespan_skeleton.dart`, `widgets/lifespan_empty_state.dart`.
- Plus DB: a migration extending lifespan to appliances (new RPC `get_item_lifespan_overview(p_property_id)` returning `kind`), and the property columns (`has_basement`, climate subzone label, optional `property_photos`).
- Reads (does not edit) shared providers from B/C for counts.

**Track B: Systems + scan (HomeSystems 2.17, ScanFlow 2.3, AddSystem 2.4, SystemDetail 2.12)**
- Owns: `screens/systems_screen.dart`, `screens/system_form_screen.dart`, `screens/system_detail_screen.dart`, `providers/systems_provider.dart`, `providers/system_detail_provider.dart` (+.g), `models/system.dart` (+gen), `models/system_detail.dart`, `widgets/system_card.dart`, `widgets/system_list_skeleton.dart`, `widgets/systems_empty_state.dart`, `widgets/system_photo_strip.dart`, `core/widgets/scan_label_button.dart` (to be superseded), `services/label_scanner_service.dart`, new `screens/scan_flow_screen.dart`, and `supabase/functions/scan-label/index.ts`.

**Track C: Appliances + shared item screens (HomeAppliances 2.18, AddAppliance 2.5, ApplianceDetail 2.13, ItemTasks 2.19, ItemPhotos 2.20, ItemReminders 2.22)**
- Owns: `screens/appliances_screen.dart`, `screens/appliance_form_screen.dart`, `screens/appliance_detail_screen.dart`, `screens/item_tasks_screen.dart`, new `item_photos_screen.dart`, `item_reminders_screen.dart`, `providers/appliances_provider.dart`, `providers/appliance_detail_provider.dart` (+.g), `models/appliance.dart` (+gen), `models/appliance_detail.dart`, `models/item_photo.dart` (+gen), `widgets/appliance_card.dart`, `widgets/appliance_list_skeleton.dart`, `widgets/appliances_empty_state.dart`.
- Plus new reminders glue that can reuse `features/maintenance/widgets/reminders/*` (do not edit; owned by the earlier sprint).
- Balance: Track C has 6 screens versus 4 / 3. If too heavy, move ItemTasks/ItemPhotos/ItemReminders to Track B (BUILD_ORDER 3.2e groups them with systems), which makes it 7 vs 3. Alternative: split item screens evenly.

**Minimal shared contracts (write first, as "step 0", by the lead before the tracks start)**
All new files, no legacy edits:
- `home_profile/lifespan/lifespan_reading.dart`
  ```dart
  enum LifespanBand { plenty, aging, endOfLife, past } // <75, 75-89, 90-100, >100
  class LifespanReading {
    final double? ageYears; final int? lifeYears; final double? percent;
    final LifespanBand? band; final int? replaceYear; final String ageLabel; // "5½ yrs" / "4 mo"
    static LifespanReading from({DateTime? start, int? lifeYears, int? override, DateTime? now});
  }
  ```
- `home_profile/widgets/shared/item_list_row.dart`: `ItemListRow({icon, name, subtitle, LifespanReading reading, String? warrantyNote, int taskCount, int? replaceYear, VoidCallback onTap})`.
- `home_profile/widgets/shared/item_filter_bar.dart`: `ItemFilterBar<T>({chips, selected, onSelect, sort, onSort, shownCount})`.
- `home_profile/widgets/shared/item_detail_sections.dart`: `ItemHero`, `ItemLifespanCard`, `ItemNextUpList`, `ItemKeyValueCard` (with copy), `ItemHistoryTimeline`, `ItemDocumentsCard`.
- `home_profile/widgets/shared/scan_prefill.dart`:
  ```dart
  enum ScanKind { system, appliance }
  class ScanPrefill { final ScanKind kind; final LabelScanResult result; final XFile photo; }
  ```
  Used as `extra` of the add routes via a small args class `ItemFormArgs { HomeSystem? / Appliance? existing; ScanPrefill? prefill; }`. This requires a single owner to change `app_router.dart`.
- `home_profile/widgets/shared/scan_field.dart`: input decoration with the inset cobalt edge (`ScanFieldBox`).
- `home_profile/providers/item_task_counts_provider.dart`: `itemTaskCountsProvider` returning `Map<String,int>`; a single author (A or lead).
- Routes in `app_router.dart` (one author, one commit): add `AppRoutes.homeProfile`, `homeScan`, `homeSystemPhotos`, `homeApplianceTasks` already, `homeSystemReminders`, `homeApplianceReminders`, `homeAppliancePhotos`, and stub screens so the tracks compile in parallel.
- Aurora widgets already exist for field, chip, toggle, sheet, task row (`core/widgets/aurora/*`). Do not duplicate.

**Order and risks**
- Order: (0) lead: shared contracts, router stubs, migration(s) (`systems.specifications`, optional `item_service_log`, lifespan RPC for appliances, property columns); (1) tracks A, B, C in parallel; (2) integrate (HomeProfile links, Scan returns into forms).
- Risks:
  - `app_router.dart` is shared: single editor.
  - Category taxonomy decision blocks AddSystem and HomeSystems chips (B), and the scan mapping.
  - Track A depends on the lifespan RPC and the appliance data from C; use the RPC contract with a stub.
  - Legacy `deleteSystem` plain UPDATE (will 42501) and `Property.propertyType` non-null crash.
  - `*.freezed.dart` / `*.g.dart` need `build_runner`; schedule regeneration per-track to avoid conflicts on shared models (`item_photo.dart` in C, `system.dart` in B).
  - ItemTasks currently reads `maintenanceTasksProvider` (global) and filters client-side. Check performance and the "Done" tab needs `task_completions`, which no provider exposes for items.
  - Three screens exist in `features/maintenance/` (`task_history_screen`, `tasks_all_year_screen`, `home_reminders_screen`) that overlap with ItemTasks and ItemReminders. Coordinate.

---

## 7. Product questions (ambiguities and contradictions)

1. **AddSystem category list vs DB enum** (gap 1). Change the enum (migration; adding Exterior, Interior, Climate, Safety, Water) or change the kit's select to the existing 10? Same for the HomeSystems filter-chip grouping.
2. **Does ScanFlow's Installed Mar 2021 come from the manufacture date?** The function returns `manufactureDate`. The kit labels it a scanned "installed" field. Use it as a default install date, or leave Installed blank?
3. **What does "No label? Add it by hand" and "Type it in instead" open?** Both are `#` in the kit. Assumed: blank AddSystem / AddAppliance for the chosen kind. Confirm.
4. **Edit vs Add**: SystemDetail and ApplianceDetail "Edit" link to AddSystem / AddAppliance, whose copy is "HOME PROFILE · NEW", "Add a system.", and which have a Scan banner and "Cancel/Save system". Is there an edit variant (heading "Edit …", no scan banner, includes location, installer, price, warranty, notes, status, and a delete)? The kit has none of those fields, yet the list/detail show location and warranty. Where is the system warranty entered?
5. **Delete/archive and "replaced"**: no UI in the kit (legacy has delete, `ItemStatus` incl. replaced/needs_repair/removed). Is delete via `ConfirmDelete` from Edit? How is "HEALTHY" derived (lifespan only, or status)? What do needs_repair/replaced look like?
6. **ApplianceDetail "All 4 appliance tasks" → TasksAllYear, while SystemDetail "All 5 HVAC tasks" → ItemTasks.** Intended? Also the ApplianceDetail photo badge has no destination (`#`); SystemDetail's goes to ItemPhotos. Presumably both should use the shared ItemTasks/ItemPhotos. ItemTasks and ItemReminders are only drawn for systems (Furnace).
7. **Appliance lifespan**: no lifespan field in AddAppliance, but the kit shows "~11 yrs" and "REPLACE AROUND 2034". Source is a type-based default (and maybe scan). Appliance age uses purchase date ("BOUGHT DEC 2023") while systems use install date. Confirm that appliances age from purchase_date and how a missing date renders (the legacy RPC shows 'unknown').
8. **Bands**: kit uses 75/90/100% of a single "~N yrs" life, while the RPC uses min/max (aging ≥ 0.75×min, end_of_life ≥ max). Which defines "1 AGING" on HomeProfile and "AT END OF LIFE"? HomeProfile shows the water heater "12 YRS OF ~12" as "at the end of its life", while the HomeSystems row also says "AT END OF LIFE" (p=100), consistent with 90–100.
9. **"Next 5 years ~$4,400 to replace 3 things" (HomeProfile) vs HomeLifespan total** (`$` of items with end < 2032, per tab) and the mock's sum. The mock computes "~$4,400" from the demo, but the kit's 5-year bars (`$2.6K` 2027, `$1.8K` 2030) don't total $4,400 (they total $4,400: 2.6 + 1.8, OK). However, "to replace 3 things" while the water heater, dishwasher (past life, bucketed 2027) are only 2 items in 2027 + 1 in 2030. Fine, but it is a count of items due in the window. Also the HomeLifespan dishwasher is 2025 in HomeAppliances ("REPLACE ~2025") vs the timeline ends. The dishwasher end year is 2025.3 + ... inconsistent labels between screens ("PAST ITS LIFE · REPLACE ANY TIME" vs "PAST EXPECTED LIFE"). Which copy wins?
10. **HomeProfile's Recently row "Central AC installed … $6,450" and ring colors**: all three rings are coral in the mock even though Notes say "coral only for act now", and 78/91/80 are not all alarming. Is ring color score-based?
11. **Home Health sub-scores and trend**: Records and Emergency pillars plus "UP 4 SINCE SEP" are not in the current RPC (gap 6). Build now (Sprint 3), or leave for Sprint 6 (Home tab)? HomeProfile also repeats the Home tab's ring metrics.
12. **HomeEdit**: (a) multiple photos with COVER, or one photo? (b) Garage is a single free-text "Attached · 2 cars". Make it a structured control? (c) Purchase date is free text "Mar 2024". Picker? (d) Is "Cancel" with unsaved changes silent? The kit does not show a discard prompt. (e) What happens on ZIP change: rechecking the climate zone, regenerating tasks ("REMINDERS AND LIFESPANS WILL UPDATE" shown for a year-built change)? (f) Property type label "Manufactured" vs the stored `mobile`. (g) Where are county, multi-family and down_payment edited (kit omits them).
13. **Free-plan photo limits**: "4 of 4 photos on Free … YOU'RE ON THE TRIAL" while "PREMIUM KEEPS EVERY PHOTO". Are the extra photos hidden or deleted after the trial? Legacy has an 8-appliance free warning; the kit shows no system or appliance limit.
14. **ItemReminders**: Turned-off reminders hidden "everywhere" and excluded from health. Notes also say user-created reminders get Edit/Delete rather than a switch and climate tags (FREEZE / HUMID / STORMS) should show. The kit mock shows neither. Do I implement them on the item screen? Is there any "Turn all on" action here (Notes mention it only for setup 2.30)?
15. **Long-press task menu**: Notes say every task row (including "a system's task list") has the long-press menu (Skip / Change how often / Open / Stop reminding me). The ItemTasks mock shows no such affordance and no snackbar. Confirm it is required here and whether the legacy ⋯/edit icons in `item_tasks_screen.dart` (it has `_IconBtn` edit and delete) should be removed per "No ⋯ buttons on task rows".
16. **Home History Report card on HomeProfile** is Premium and Sprint 9. Show it now (disabled or linking to a placeholder)? Same for "Project in progress" and "Recently" (cross-feature).
17. **ScanFlow presentation**: the PNG shows a bottom sheet over Home, while the camera state is full-screen. Is it a modal route (sheet → full-screen camera), and what happens with camera permission denial, offline (Notes: Scan dimmed offline with a snackbar), and failed or empty reads (no kit state)? Also should the camera segmented control change the form kind after a shot?
18. **Suggestion chips tap behavior** (HomeSystems "+ Plumbing" etc.): open AddSystem prefilled, or add directly? Caption "TRACKING THEM ADDS THEIR UPKEEP REMINDERS" suggests an immediate add with generated tasks.
19. **Task-count wording**: HomeProfile says `5 appliances` while the legacy Home tab uses counts. HomeSystems "5 TRACKED · 1 AGING" counts only items with a defined state. Do items with no install date count as tracked?
20. **Notes vs kit**: Notes say a system's task list "Manage" is the reminder screen (2.19 → 2.22) and the whole-house one is "Home profile → Around the house (2.23)". Consistent. However the kit's ItemReminders "Done" button returns to ItemTasks while the back chevron says "‹ Furnace tasks" (same destination).
