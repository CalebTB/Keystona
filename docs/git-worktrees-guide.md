# Git Worktrees - Parallel Development Guide

Git worktrees allow you to work on multiple features simultaneously without switching branches in the same directory.

## Quick Start

### 1. Setup Worktrees for All Features

```bash
./scripts/setup-parallel-worktrees.sh
```

This creates three worktrees:
- `../Keystona-worktrees/system-registry` (Issue #7)
- `../Keystona-worktrees/appliance-tracking` (Issue #8)
- `../Keystona-worktrees/lifespan-indicators` (Issue #9)

Each worktree has its own branch branching from `main`.

### 2. Open Worktrees in Separate VSCode Windows

```bash
# Terminal 1: System Registry
cd ../Keystona-worktrees/system-registry
code .

# Terminal 2: Appliance Tracking
cd ../Keystona-worktrees/appliance-tracking
code .

# Terminal 3: Lifespan Indicators
cd ../Keystona-worktrees/lifespan-indicators
code .
```

### 3. Work on Each Feature Independently

Each worktree is a complete working copy:

```bash
# In system-registry worktree
cd ../Keystona-worktrees/system-registry/hometrack_mobile
flutter pub get
flutter run
# Make changes, commit, push

# In appliance-tracking worktree (different terminal)
cd ../Keystona-worktrees/appliance-tracking/hometrack_mobile
flutter pub get
flutter run
# Work independently without affecting system-registry
```

## Common Workflows

### List All Worktrees

```bash
./scripts/manage-worktrees.sh list
```

### Setup Flutter Dependencies in a Worktree

```bash
./scripts/manage-worktrees.sh flutter system-registry
```

### Commit and Push from a Worktree

```bash
cd ../Keystona-worktrees/system-registry
git add .
git commit -m "feat(systems): Add HVAC tracking model"
git push -u origin feature/system-registry
```

### Remove a Worktree When Done

```bash
./scripts/manage-worktrees.sh remove system-registry
```

This removes the worktree and optionally deletes the branch.

### Clean All Worktrees

```bash
./scripts/manage-worktrees.sh clean
```

**Warning:** This removes ALL worktrees and optionally deletes all feature branches.

## Benefits of Worktrees for Parallel Development

### 1. No Branch Switching Overhead
- Each feature has its own directory
- No need to stash or commit unfinished work
- No risk of accidentally mixing changes

### 2. Run Multiple Flutter Apps Simultaneously
- Test different features side-by-side
- Compare implementations
- Run tests in parallel

### 3. Independent Dependencies
- Each worktree has its own `flutter pub get`
- Different package versions don't conflict
- Clean build directories per feature

### 4. Cleaner Mental Model
- Physical directories = separate features
- Easy to see what's in progress
- Reduced cognitive load

## Workflow Example: Three Features in Parallel

**Day 1 Morning - System Registry:**
```bash
cd ../Keystona-worktrees/system-registry
# Implement SystemService and tests
git commit -m "feat(systems): Add SystemService with CRUD"
git push
```

**Day 1 Afternoon - Appliance Tracking:**
```bash
cd ../Keystona-worktrees/appliance-tracking
# Implement OCR integration
git commit -m "feat(appliances): Add OCR label extraction"
git push
```

**Day 2 Morning - Lifespan Indicators:**
```bash
cd ../Keystona-worktrees/lifespan-indicators
# Implement progress bar widget
git commit -m "feat(lifespan): Add LifespanProgressBar widget"
git push
```

**No branch switching needed!** All three features progress independently.

## Advanced Tips

### Shared Dependencies Across Worktrees

If you need to share code between worktrees (e.g., a common utility), commit it to `main` first:

```bash
cd /Users/calebbyers/Code/Keystona
git checkout main
# Add shared code
git commit -m "feat(core): Add shared utility"
git push

# Update each worktree
cd ../Keystona-worktrees/system-registry
git merge main

cd ../Keystona-worktrees/appliance-tracking
git merge main
```

### Run Tests in All Worktrees

```bash
# Create a script to run tests in all worktrees
for worktree in system-registry appliance-tracking lifespan-indicators; do
  echo "Testing $worktree..."
  cd ../Keystona-worktrees/$worktree/hometrack_mobile
  flutter test
done
```

### Sync All Worktrees with Main

```bash
# Pull latest main into all worktrees
cd /Users/calebbyers/Code/Keystona
git checkout main
git pull

for worktree in system-registry appliance-tracking lifespan-indicators; do
  cd ../Keystona-worktrees/$worktree
  git merge main
done
```

## Troubleshooting

### "fatal: 'branch' is already checked out"

A branch can only be checked out in one worktree at a time. If you need to switch:

```bash
./scripts/manage-worktrees.sh remove system-registry
cd /Users/calebbyers/Code/Keystona
git checkout feature/system-registry
```

### Worktree Path Issues

If you move the repository, worktrees break. To fix:

```bash
cd /Users/calebbyers/Code/Keystona
git worktree repair
```

### Deleting Worktrees Manually

If you delete a worktree directory manually (not recommended):

```bash
cd /Users/calebbyers/Code/Keystona
git worktree prune
```

## When NOT to Use Worktrees

- **Small changes:** For quick fixes, regular branch switching is faster
- **Single feature work:** If you're only working on one feature at a time
- **Disk space constraints:** Each worktree duplicates the repository

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `setup-parallel-worktrees.sh` | Create worktrees for all three features |
| `manage-worktrees.sh list` | Show all worktrees |
| `manage-worktrees.sh remove <name>` | Remove specific worktree |
| `manage-worktrees.sh clean` | Remove all worktrees |
| `manage-worktrees.sh flutter <name>` | Run flutter pub get in worktree |

## Integration with Claude Code

When working with Claude Code in a worktree:

```bash
# Start Claude Code in a specific worktree
cd ../Keystona-worktrees/system-registry
claude
```

Claude will operate in that worktree's context, keeping work isolated.

---

**Pro Tip:** Bookmark your worktree directories in Finder/Terminal for quick access!
