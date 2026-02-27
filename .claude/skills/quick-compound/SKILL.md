---
name: quick-compound
description: Quickly extract the key learnings from the last task completed. Use this after finishing any feature, bug fix, or significant work to document patterns, decisions, and lessons learned in a fast, concise format. Triggers on 'quick compound', 'fast compound', 'quick learning extraction', or when you need a rapid summary of what was learned from recent work.
---

# Quick Compound

Quickly extract the key learnings from the last task completed.

## Instructions

Do a fast extraction of learnings from the most recent work. Be concise but thorough.

### 1. Check Recent Changes
```bash
git log --oneline -5
git diff HEAD~1 --name-only
```

### 2. Extract & Output

Analyze the changes and output learnings in this exact format:

```markdown
# Quick Compound - [Date]

## What Was Done
[1-2 sentence summary]

## Patterns (copy to CLAUDE.md if new)
- **[Pattern Name]**: [Brief description] → See `[file path]`

## Decisions (document rationale)
- **[Decision]**: Chose [X] over [Y] because [reason]

## Lessons (prevent future issues)
- **[Issue]**: [What happened] → [How to prevent]

## Action Items
- [ ] [Specific documentation update needed]
- [ ] [Test to add]
- [ ] [Pattern to formalize]
```

### 3. Update CLAUDE.md Automatically

Read CLAUDE.md and append learnings to the appropriate sections:

1. Read the current CLAUDE.md file
2. For each pattern found, append to the `## Patterns` section:
   ```
   - **[Pattern Name]**: [Brief description] → See `[file path]`
   ```
3. For each decision made, append to the `## Decisions` section:
   ```
   - **[Decision]**: Chose [X] over [Y] because [reason]
   ```
4. For each lesson learned, append to the `## Lessons` section:
   ```
   - **[Issue]**: [What happened] → [How to prevent]
   ```

After updating CLAUDE.md, show the user what was added:

```markdown
✅ Updated CLAUDE.md with:
- [X] patterns
- [Y] decisions
- [Z] lessons
```

---

Keep it fast. Focus on the highest-value learnings that will compound.
