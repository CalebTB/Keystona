# Compound Learnings Extraction

Extract and document patterns, decisions, and failures from recently completed work to make future development easier.

## Instructions

Analyze the recent work done in this codebase and extract learnings that should be documented. Follow this systematic process:

### Step 1: Identify Recent Changes

First, examine what was recently worked on:

```bash
# Check recent commits
git log --oneline -20

# See files changed in last commit
git diff HEAD~1 --name-only

# View the actual changes
git diff HEAD~1
```

### Step 2: Extract Patterns

Look for any NEW patterns that were established or discovered:

- **Code patterns**: New ways of structuring code, components, or modules
- **Architecture patterns**: How systems were connected or organized
- **Testing patterns**: New approaches to testing specific functionality
- **State management patterns**: How data flow was handled
- **API patterns**: New endpoint structures or data formats

For each pattern found, document it in this format:

```markdown
## Pattern: [Descriptive Name]

**When to use:** [Situations where this pattern applies]

**Implementation:**
[Code example or description]

**File reference:** [Path to example implementation]

**Related patterns:** [Any connected patterns]
```

### Step 3: Extract Decisions

Identify any significant DECISIONS that were made:

- **Technology choices**: Libraries, APIs, or tools selected
- **Architecture decisions**: How components were structured
- **Trade-off decisions**: Performance vs. readability, speed vs. completeness
- **Convention decisions**: Naming, file organization, code style

For each decision, document it in this format:

```markdown
## Decision: [What was decided]

**Context:** [The situation that required a decision]

**Options considered:**
1. [Option A] - [Pros/Cons]
2. [Option B] - [Pros/Cons]
3. [Option C] - [Pros/Cons]

**Chosen:** [Which option and why]

**Consequences:** [Trade-offs accepted, future implications]

**Date:** [When this decision was made]
```

### Step 4: Extract Failures & Lessons

Identify any FAILURES, bugs, or problems encountered and what was learned:

- **Bugs fixed**: What went wrong and why
- **Approaches that didn't work**: What was tried and abandoned
- **Performance issues**: Bottlenecks discovered
- **Integration problems**: Issues connecting systems
- **Edge cases discovered**: Unexpected scenarios

For each failure/lesson, document it in this format:

```markdown
## Lesson: [What went wrong or was discovered]

**Symptom:** [What was observed / the error or problem]

**Root cause:** [The actual underlying issue]

**Fix:** [How it was resolved]

**Prevention:** [How to avoid this in future work]

**Detection:** [How to catch this earlier next time]
```

### Step 5: Update Documentation

After extracting learnings, suggest where they should be documented:

1. **CLAUDE.md** (root) - Project-wide patterns and conventions
2. **Feature-specific docs** - Patterns specific to a feature area
3. **AGENTS.md** - Guidance for AI agents working on the code
4. **Code comments** - Only if the code isn't self-explanatory
5. **Test cases** - Turn bugs into regression tests

### Step 6: Summary Report

Provide a summary of what was extracted:

```markdown
# Compound Learnings Report - [Date]

## Work Analyzed
[Brief description of the task/feature completed]

## Patterns Extracted: [count]
- [Pattern 1 name]
- [Pattern 2 name]

## Decisions Documented: [count]
- [Decision 1]
- [Decision 2]

## Lessons Learned: [count]
- [Lesson 1]
- [Lesson 2]

## Recommended Documentation Updates
- [ ] Add [pattern] to CLAUDE.md
- [ ] Create test case for [lesson]
- [ ] Update [file] with decision rationale
```

---

## Usage Examples

**After completing a feature:**
```
/compound "Just finished implementing the document upload feature with OCR"
```

**After fixing a bug:**
```
/compound "Fixed the maintenance reminder notification timing bug"
```

**After a refactor:**
```
/compound "Refactored the home value tracking service"
```

**Weekly review:**
```
/compound "Review all work from this week"
```

---

## Keystona-Specific Areas to Watch

When analyzing Keystona work, pay special attention to:

- **Supabase patterns**: RLS policies, Edge Functions, real-time subscriptions
- **Flutter patterns**: Riverpod state management, offline-first data handling
- **Keystona design system**: New components, color usage, spacing decisions
- **API integrations**: ATTOM, OCR, Weather API patterns
- **Cross-platform considerations**: Differences between mobile and web implementations

Always reference the existing project documentation:
- `Keystona_TechnicalArchitecture.md`
- Feature specs in `/mnt/project/`
- `Keystona_PremiumHome_Theme.md`
