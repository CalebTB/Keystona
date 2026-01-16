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

### 3. Suggest CLAUDE.md Updates

If any patterns or lessons are significant, draft the exact text to add to CLAUDE.md:

```markdown
<!-- Add to CLAUDE.md -->

## [Section Name]

[Exact text to add]
```

---

Keep it fast. Focus on the highest-value learnings that will compound.
