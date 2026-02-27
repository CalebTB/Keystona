---
name: auto-compound
description: Wrapper for compound-engineering:workflows:compound that automatically updates CLAUDE.md. Use this to get the best of both worlds - the comprehensive compound-engineering workflow plus automatic CLAUDE.md updates. Triggers on 'auto compound', 'workflows compound with updates', or when you want compound learning extraction that automatically documents to CLAUDE.md.
---

# Auto-Compound Wrapper

Runs the compound-engineering:workflows:compound skill and automatically updates CLAUDE.md with the results.

## Instructions

Follow these steps in order:

### Step 1: Run Compound Engineering Workflow

Invoke the compound-engineering workflow using the Skill tool:

```
Skill tool with:
- skill: "compound-engineering:workflows:compound"
```

Wait for the workflow to complete and capture its output.

### Step 2: Parse the Output

The compound-engineering:workflows:compound skill outputs learnings in a structured format. Extract:

1. **Patterns** - Look for sections labeled "Pattern:", "Code pattern:", "Architecture pattern:", etc.
2. **Decisions** - Look for sections labeled "Decision:", "Choice:", "Selected:", etc.
3. **Lessons** - Look for sections labeled "Lesson:", "Bug:", "Issue:", "Problem:", etc.

### Step 3: Update CLAUDE.md

Read the current CLAUDE.md file and append the extracted learnings:

**For Patterns:**
```markdown
- **[Pattern Name]**: [Brief description] → See `[file path]`
```

**For Decisions:**
```markdown
- **[Decision]**: Chose [X] over [Y] because [reason]
```

**For Lessons:**
```markdown
- **[Issue]**: [What happened] → [How to prevent]
```

Append to the appropriate sections:
- Patterns go in `## Patterns`
- Decisions go in `## Decisions`
- Lessons go in `## Lessons`

### Step 4: Confirm Updates

Show the user what was added:

```markdown
✅ Ran compound-engineering:workflows:compound
✅ Updated CLAUDE.md with:
- [X] patterns
- [Y] decisions
- [Z] lessons

## Summary of Updates

### Patterns Added:
- [Pattern 1]
- [Pattern 2]

### Decisions Added:
- [Decision 1]

### Lessons Added:
- [Lesson 1]
```

---

## Usage

Simply invoke:
```bash
/auto-compound
```

This runs the full compound-engineering workflow and automatically updates CLAUDE.md.

## When to Use

- After completing major features
- After fixing complex bugs
- End of sprint/week reviews
- When you want comprehensive analysis + automatic documentation

## Difference from /compound

- `/compound` - Your local skill, fast, Keystona-specific
- `/auto-compound` - Wraps compound-engineering plugin, more comprehensive, auto-updates CLAUDE.md
- `/workflows:compound` - Plugin only, no auto-update
