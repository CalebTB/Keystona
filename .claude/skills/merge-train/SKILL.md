---
name: merge-train
description: Merge parallel worktrees into main one at a time in dependency order. Use this after parallel development across multiple worktrees to bring everything back to main safely. Triggers on 'merge train', 'merge worktrees', 'merge parallel branches', 'merge all worktrees', or when the user wants to land parallel work without conflicts.
---

# Merge Train

## Your Role

You land parallel branches into main one at a time, in dependency order, with a quality gate and user approval between each merge.

Nothing in this skill is hardcoded. Every project value — repo, quality gate command, issue tracker, merge strategy — is discovered at runtime from the repository itself.

---

## Step 1 — Discover Project Context

Run these commands and record the results. Everything downstream depends on them.

### 1a — GitHub repo slug

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

Fall back to parsing `git remote get-url origin` if `gh` is unavailable.

### 1b — Main branch name

```bash
git remote show origin | grep "HEAD branch" | awk '{print $NF}'
```

Fall back to `main` if this fails.

### 1c — Quality gate command

Walk the root of the primary worktree and detect the project type:

| File found | Quality gate command |
|---|---|
| `pubspec.yaml` | `flutter analyze` |
| `package.json` with `"test"` script | `npm test` |
| `package.json` without `"test"` | `npm run lint` |
| `Makefile` with `lint` target | `make lint` |
| `Gemfile` | `bundle exec rubocop` |
| `pyproject.toml` | `python -m pytest` |
| `go.mod` | `go vet ./...` |

If `pubspec.yaml` is in a subdirectory (not repo root), detect that subdirectory as the **app root**:
```bash
find . -name "pubspec.yaml" -not -path "*/.*" -not -path "*/build/*" | head -5
```

All quality gate commands run from the app root within whichever directory is active.

If nothing is detected, ask the user for the command.

### 1d — Issue tracker

```bash
gh issue list --repo {repo_slug} --limit 1 --json number 2>/dev/null
```

If this succeeds, use GitHub Issues for dependency resolution. Otherwise fall back to manual ordering.

---

## Step 2 — Discover Branches

```bash
git worktree list --porcelain
```

Parse all worktree entries. For each:
- Skip the main branch worktree
- Skip detached HEAD worktrees
- Skip branches already merged into main:
  ```bash
  git branch -r --merged origin/{main_branch} | grep {branch_name}
  ```
- Skip prunable entries (gitdir points to non-existent location)

For each remaining branch, extract an issue number from the branch name:
1. Any number in the branch: `feature/doc-upload-21` → `21`
2. `issue-N`, `fix/N-`, `feat/N-` patterns
3. No number → mark `?`, ask the user

For branches checked out in **worktrees**, the "checkout" is already done — the worktree directory IS the checkout. Note the worktree path for running the quality gate.

For branches NOT in a worktree (only on remote or in local branch list), check them out:
```bash
git checkout {branch_name}
```

---

## Step 3 — Build Dependency Graph

For each branch with a known issue number:
```bash
gh issue view {issue_number} --repo {repo_slug} --json title,body,labels
```

Scan body for:
- `Depends on #N`
- `Blocked by #N`
- `Requires #N`
- `After #N`

Build a DAG, topological sort: no-dep items first, ties broken by ascending issue number.

If GitHub Issues unavailable, ask: `"Please tell me the merge order (e.g. '21, 25, 22, 23')"`

---

## Step 4 — Present Merge Plan

Show the full plan before touching anything:

```
Merge Train — {repo_slug}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Repo:           {repo_slug}
Main branch:    {main_branch}
Quality gate:   {command}  (from {app_root})
Merge strategy: merge into main locally, squash commit

Merge order:
  1. #{N} — {title}
       branch: {branch}
       location: {worktree_path or "will checkout"}
       deps: (none)

  2. #{N} — {title}
       branch: {branch}
       location: {worktree_path or "will checkout"}
       deps: #{dep} (position 1 — will be in main before this runs)

Excluded:
  - {branch}  (already merged)
  - {branch}  (prunable orphan)

Ready to begin? (y to start)
```

Wait for `y` / `yes` / `go` / `start` before proceeding.

---

## Step 5 — Merge Loop

For each item in the sorted order, run this exact sequence. Stop on any failure.

### 5a — Navigate to the branch

If the branch has a worktree, announce the path so the user knows where to look:
```
🔀 Switching to #{issue_number} — {title}
   Location: {worktree_path}
   Branch:   {branch_name}
```

If the branch does NOT have a worktree, check it out in the main repo:
```bash
git checkout {branch_name}
```

### 5b — Merge main into the branch first

Before running the quality gate, bring in any changes that landed on main from previous merges in this train:
```bash
git -C {branch_location} merge {main_branch} --no-edit
```

This ensures the branch is tested against the cumulative state of main, not a stale snapshot.

If merge conflicts occur:
```
⚠️  Conflict merging main into #{issue_number}.

Conflicting files:
{git status output in branch_location}

Fix the conflicts in {branch_location}, run 'git merge --continue',
then run /merge-train again to resume from this item.
```
Stop.

### 5c — Quality gate

```bash
cd {branch_location}/{relative_app_root} && {quality_gate_command}
```

If it fails:
```
❌ Quality gate failed for #{issue_number}.

{command output}

Fix all issues in {branch_location}, then run /merge-train again to resume.
```
Stop.

### 5d — Await user approval (run compound in parallel)

Announce the branch is ready for testing, then immediately invoke the `/compound issue {issue_number}` skill on the **just-merged** state of main while the user tests. This uses the wait time productively.

```
✅ Quality gate passed for #{issue_number} — {title}

Branch is at: {branch_location}
Test it now. Running /compound on the previous merge in the background.

When ready, enter:
  'y'    — approve and merge into main
  'skip' — skip this branch (leave it unmerged)
  'stop' — end the train here
```

**While the user tests**, run the compound skill for the previously merged issue (i.e. the one that was JUST squashed into main before this quality gate ran). Pass the issue number as the argument:

```
/compound issue {previously_merged_issue_number}
```

This extracts patterns, decisions, and lessons from the merged work and updates CLAUDE.md — all while the user is testing the next branch. Do NOT run compound for the current branch being tested (it hasn't merged yet).

For the very first item in the train (no previous merge), skip compound and just wait.

Wait for user input before proceeding.

### 5e — Merge into main

Switch to main and merge the approved branch:
```bash
git checkout {main_branch}
git merge --squash {branch_name}
git commit -m "{issue_title} (#{issue_number})"
```

If the commit fails (nothing to commit, or conflict):
- Report the exact error
- Stop the train

### 5f — Push main

```bash
git push origin {main_branch}
```

### 5g — Close the GitHub issue and any open PR

Close the issue for the branch just merged:
```bash
gh issue close {issue_number} --repo {repo_slug} --comment "Merged in squash commit {short_hash}"
```

Check for any open PR for the merged branch and close it:
```bash
gh pr list --repo {repo_slug} --head {branch_name} --state open --json number --jq '.[0].number'
```

If a PR number is returned:
```bash
gh pr close {pr_number} --repo {repo_slug} --comment "Closed — squash merged into {main_branch} as {short_hash}"
```

If no open PR exists, skip silently.

### 5h — Report and move to next

```
✅ #{issue_number} — {title} merged into main.
   Commit: {short_hash}
   Issue #issue_number closed.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next: #{next_issue} — {next_title}
  Location: {next_worktree_path}
  Will merge main into it before quality gate.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Continuing...
```

Then go to Step 5a for the next item. The next item's Step 5b will merge the updated main in, giving it all the changes from this merge.

---

## Step 6 — Final Report

Run `/compound issue {last_merged_issue_number}` for the final merged item (it had no "next branch testing" window to compound during).

Then print the summary:

```
🚀 Merge train complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Merged ({count}):
  ✅ #{N} — {title}   {commit}
  ✅ #{N} — {title}   {commit}

Skipped:
  ⏭  #{N} — {title}

main is now at: {hash}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then clean up prunable worktree metadata:
```bash
git worktree prune
```

Ask before deleting local worktree directories:
```
Remove local worktree directories for merged branches?
  1. {path}
  2. {path}
Enter 'y' to remove all, 'n' to keep, or specify numbers (e.g. "1, 3").
```

---

## Resuming After Failure

On re-invocation:
1. `git worktree list` — see what's still around
2. `git log --oneline {main_branch}` — see what's already been merged in this session
3. Rebuild the remaining list from the original order minus already-merged items
4. Show resume plan and wait for `y`

---

## Rules

- **Never merge out of dependency order.**
- **Always merge main into the branch before the quality gate** — test against the real cumulative state.
- **Never proceed past a failing quality gate.**
- **Always wait for explicit user approval before merging into main.**
- **Always squash when merging into main** — keeps history linear.
- **Never force-push main.**
- **Stop on any failure** — never land broken code.
- **Never assume paths, commands, or conventions** — discover everything.
