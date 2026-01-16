# HomeTrack Skills Quick Reference

> Fast lookup for skill selection, commands, and code patterns

---

## 🎯 Skill Selection Matrix

| I need to... | Use Skill | Key Tool/Library |
|--------------|-----------|------------------|
| Create Word document | **DOCX** | docx-js (npm) |
| Edit existing Word doc | **DOCX** | unpack → XML → pack |
| Extract PDF text | **PDF** | pdfplumber |
| Extract PDF tables | **PDF** | pdfplumber + pandas |
| Create new PDF | **PDF** | reportlab |
| Merge/split PDFs | **PDF** | pypdf |
| Fill PDF forms | **PDF** | See FORMS.md |
| Create presentation | **PPTX** | html2pptx + PptxGenJS |
| Edit presentation | **PPTX** | unpack → XML → pack |
| Create spreadsheet | **XLSX** | openpyxl |
| Analyze spreadsheet | **XLSX** | pandas |
| Design UI components | **Frontend Design** | HTML/CSS/React |
| Create custom skill | **Skill Creator** | init_skill.py |
| Build API integration | **MCP Builder** | TypeScript SDK |

---

## 📄 DOCX Skill

### Quick Start
```javascript
const { Document, Packer, Paragraph, TextRun } = require('docx');

const doc = new Document({
  sections: [{
    properties: {
      page: { size: { width: 12240, height: 15840 } } // US Letter
    },
    children: [
      new Paragraph({ children: [new TextRun('Hello World')] })
    ]
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('document.docx', buffer);
});
```

### Critical Rules
- ✅ Always set page size explicitly (US Letter: 12240 x 15840 DXA)
- ✅ Use `LevelFormat.BULLET` for lists
- ❌ Never use unicode bullets (•, -, etc.)
- ✅ Set both table `columnWidths` AND cell `width`
- ✅ Use `ShadingType.CLEAR` for table backgrounds
- ❌ Never use `ShadingType.SOLID`
- ✅ `PageBreak` must be inside a `Paragraph`

### Tables Pattern
```javascript
new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  columnWidths: [4680, 4680], // Must set at table level
  rows: [
    new TableRow({
      children: [
        new TableCell({
          width: { size: 4680, type: WidthType.DXA }, // Must match columnWidths
          shading: { fill: 'E2E8F0', type: ShadingType.CLEAR },
          borders, margins: { top: 80, bottom: 80, left: 120, right: 120 },
          children: [new Paragraph({ children: [new TextRun('Cell')] })]
        })
      ]
    })
  ]
})
```

### Editing Existing Documents
```bash
# 1. Unpack
python scripts/unpack.py document.docx unpacked/

# 2. Edit XML files in unpacked/word/

# 3. Pack
python scripts/pack.py unpacked/ output.docx --original document.docx
```

---

## 📕 PDF Skill

### Extract Text
```python
import pdfplumber

with pdfplumber.open('document.pdf') as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        print(text)
```

### Extract Tables
```python
import pdfplumber
import pandas as pd

with pdfplumber.open('document.pdf') as pdf:
    tables = pdf.pages[0].extract_tables()
    df = pd.DataFrame(tables[0][1:], columns=tables[0][0])
    df.to_excel('output.xlsx', index=False)
```

### Merge PDFs
```python
from pypdf import PdfWriter, PdfReader

writer = PdfWriter()
for pdf_file in ['doc1.pdf', 'doc2.pdf']:
    reader = PdfReader(pdf_file)
    for page in reader.pages:
        writer.add_page(page)

with open('merged.pdf', 'wb') as out:
    writer.write(out)
```

### Split PDF
```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader('input.pdf')
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    with open(f'page_{i+1}.pdf', 'wb') as out:
        writer.write(out)
```

### OCR Scanned PDFs
```python
import pytesseract
from pdf2image import convert_from_path

images = convert_from_path('scanned.pdf')
text = ""
for image in images:
    text += pytesseract.image_to_string(image)
```

### Command Line Tools
```bash
# Extract text
pdftotext input.pdf output.txt
pdftotext -layout input.pdf output.txt  # Preserve layout

# Merge PDFs
qpdf --empty --pages doc1.pdf doc2.pdf -- merged.pdf

# Split pages
qpdf input.pdf --pages . 1-5 -- pages1-5.pdf

# Extract images
pdfimages -j input.pdf output_prefix
```

---

## 📊 PPTX Skill

### HTML to PPTX Workflow
```javascript
const pptxgen = require('pptxgenjs');
const { html2pptx } = require('./html2pptx');

const pptx = new pptxgen();
pptx.layout = 'LAYOUT_16x9';

// DO NOT call pptx.addSlide() - html2pptx handles it
await html2pptx('slide1.html', pptx);
await html2pptx('slide2.html', pptx);

await pptx.writeFile('output.pptx');
```

### Setup Requirements
```bash
# Extract html2pptx library
mkdir -p html2pptx
tar -xzf skills/public/pptx/html2pptx.tgz -C html2pptx

# Run conversion
NODE_PATH="$(npm root -g)" node your-script.js 2>&1
```

### Visual Validation (REQUIRED)
```bash
# Convert to PDF
soffice --headless --convert-to pdf output.pptx

# Convert to images
pdftoppm -jpeg -r 150 output.pdf slide
# Creates: slide-1.jpg, slide-2.jpg, etc.
```

### Critical Rules
- ✅ Read html2pptx.md and css.md BEFORE starting
- ✅ Use 960x540 pixels for 16:9 slides
- ❌ Do NOT call `pptx.addSlide()`
- ✅ Always validate visually before delivery
- ✅ Slides are 0-indexed in template workflows

### Template Workflow
```bash
# 1. Extract content
python -m markitdown template.pptx > content.md

# 2. Create thumbnails
python scripts/thumbnail.py template.pptx

# 3. Create inventory
# Document all slides with 0-based indexes

# 4. Apply replacements
python scripts/replace.py working.pptx replacements.json output.pptx
```

---

## 📈 XLSX Skill

### Create with Formulas
```python
from openpyxl import Workbook
from openpyxl.styles import Font

wb = Workbook()
sheet = wb.active

# Input cell (blue text)
sheet['B1'] = 10000
sheet['B1'].font = Font(color='0000FF')

# Formula cells (black text) - ALWAYS use formulas!
sheet['B2'] = '=B1*0.6'      # Costs
sheet['B3'] = '=B1-B2'       # Profit
sheet['B4'] = '=SUM(B1:B3)'  # Total

wb.save('model.xlsx')
```

### Recalculate Formulas (REQUIRED)
```bash
python recalc.py model.xlsx

# Output:
# {"status": "success", "total_errors": 0, "total_formulas": 42}
# or
# {"status": "errors_found", "error_summary": {"#REF!": {...}}}
```

### Data Analysis with pandas
```python
import pandas as pd

# Read
df = pd.read_excel('data.xlsx')
df = pd.read_excel('data.xlsx', sheet_name=None)  # All sheets

# Analyze
print(df.describe())
summary = df.groupby('category').sum()

# Write
df.to_excel('output.xlsx', index=False)
```

### Critical Rules
- ✅ ALWAYS use formulas, never hardcoded calculations
- ✅ Run `recalc.py` after any formula changes
- ✅ Verify zero formula errors before delivery
- ✅ Blue text for inputs, black for formulas
- ❌ Never open with `data_only=True` and save (loses formulas)
- ✅ Format years as text ('2024' not '2,024')
- ✅ Use parentheses for negatives: (123) not -123

### Color Standards (Financial Models)
| Color | Use For |
|-------|---------|
| Blue (0,0,255) | Hardcoded inputs |
| Black (0,0,0) | ALL formulas |
| Green (0,128,0) | Links from other sheets |
| Red (255,0,0) | External file links |
| Yellow bg | Assumptions needing attention |

---

## 🎨 Frontend Design Skill

### Design Thinking Questions
Before coding, answer:
1. **Purpose**: What problem does this solve?
2. **Tone**: What extreme aesthetic fits? (minimal, maximalist, brutalist, etc.)
3. **Differentiation**: What's the ONE thing someone will remember?
4. **Constraints**: Framework, performance, accessibility requirements?

### CSS Variables Pattern
```css
:root {
  /* Colors */
  --color-primary: #1E3A5F;
  --color-accent: #D4A574;
  --color-bg: #F5F7FA;
  
  /* Typography */
  --font-display: 'Playfair Display', serif;
  --font-body: 'Source Sans Pro', sans-serif;
  
  /* Spacing (4px base) */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 48px;
}
```

### Critical Rules
- ❌ NEVER use: Inter, Roboto, Arial, system fonts
- ❌ NEVER use: Purple gradients on white backgrounds
- ✅ Choose BOLD aesthetic direction
- ✅ Every design should be memorable
- ✅ Match implementation complexity to vision
- ✅ Minimalist = precision; Maximalist = elaboration

### Animation Priorities
1. **High impact**: Page load with staggered reveals
2. **Medium impact**: Scroll-triggered animations
3. **Subtle**: Hover states that surprise
4. Use CSS-only for HTML; Motion library for React

---

## 🛠️ Skill Creator

### Initialize New Skill
```bash
scripts/init_skill.py my-skill --path ./output

# Creates:
# my-skill/
# ├── SKILL.md
# ├── scripts/
# ├── references/
# └── assets/
```

### Package Skill
```bash
scripts/package_skill.py ./my-skill

# Validates and creates: my-skill.skill
```

### SKILL.md Structure
```yaml
---
name: my-skill
description: What it does AND when to use it. Include all trigger conditions here.
---

# Instructions

## Workflow
1. Step one
2. Step two

## References
- See [REFERENCE.md](references/REFERENCE.md) for details
```

### Critical Rules
- ✅ Keep SKILL.md under 500 lines
- ✅ Description is the primary triggering mechanism
- ✅ Test scripts by actually running them
- ❌ Don't create README.md, CHANGELOG.md, etc.
- ✅ Challenge each piece: "Does this justify its token cost?"

---

## 🔌 MCP Builder

### TypeScript Tool Pattern
```typescript
import { z } from 'zod';

server.registerTool({
  name: 'get_property_value',
  description: 'Get property valuation from ATTOM API',
  inputSchema: z.object({
    address: z.string().describe('Full property address')
  }),
  handler: async ({ address }) => {
    const data = await attomClient.getValuation(address);
    return { 
      content: [{ type: 'text', text: JSON.stringify(data) }] 
    };
  }
});
```

### Test with Inspector
```bash
npx @modelcontextprotocol/inspector
```

### Tool Annotations
```typescript
annotations: {
  readOnlyHint: true,      // Doesn't modify data
  destructiveHint: false,   // Doesn't delete data
  idempotentHint: true,    // Same input = same result
  openWorldHint: false     // Bounded set of results
}
```

### Critical Rules
- ✅ TypeScript recommended for best SDK support
- ✅ Use Zod for input/output schemas
- ✅ Provide concise tool descriptions
- ✅ Support pagination where applicable
- ✅ Create 10 evaluation questions after building

---

## 🔗 Skill Combinations for HomeTrack

### Home History Report
```
XLSX → DOCX → PDF
  │      │      │
  │      │      └── Final distributable
  │      └── Professional report with tables
  └── Data aggregation and analysis
```

### Investor Materials
```
XLSX (projections) ─┬── PPTX (pitch deck)
                    └── DOCX (executive summary)
```

### Document Vault Processing
```
PDF (extract) → Custom Skill (categorize) → MCP (search API)
     │                    │
     │                    └── Category detection + date parsing
     └── Text and table extraction
```

---

## 📁 File Locations

| Skill | Location |
|-------|----------|
| DOCX | `/mnt/skills/public/docx/SKILL.md` |
| PDF | `/mnt/skills/public/pdf/SKILL.md` |
| PPTX | `/mnt/skills/public/pptx/SKILL.md` |
| XLSX | `/mnt/skills/public/xlsx/SKILL.md` |
| Frontend Design | `/mnt/skills/public/frontend-design/SKILL.md` |
| Skill Creator | `/mnt/skills/examples/skill-creator/SKILL.md` |
| MCP Builder | `/mnt/skills/examples/mcp-builder/SKILL.md` |

---

## 🆘 Common Issues

### DOCX
| Issue | Solution |
|-------|----------|
| Lists show unicode bullets | Use `LevelFormat.BULLET` in numbering config |
| Table columns wrong width | Set both `columnWidths` AND cell `width` |
| Black table background | Use `ShadingType.CLEAR` not `SOLID` |

### PDF
| Issue | Solution |
|-------|----------|
| Can't extract scanned text | Convert to images first, then OCR |
| Tables not detected | Try different `table_settings` in pdfplumber |
| Form filling fails | See FORMS.md for correct approach |

### XLSX
| Issue | Solution |
|-------|----------|
| Formulas show as text | Run `recalc.py` after saving |
| #REF! errors | Check cell references are valid |
| Lost formulas after edit | Don't use `data_only=True` when loading |

### PPTX
| Issue | Solution |
|-------|----------|
| Slides not created | Don't call `pptx.addSlide()` with html2pptx |
| Text cutoff | Increase margins or reduce font size |
| Template fails | Check 0-indexed slide numbers |

---

*Generated for HomeTrack • January 2026*
