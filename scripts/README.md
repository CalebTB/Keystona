# Scripts Directory

Automation scripts for Keystona development workflows.

## Git Worktrees - Parallel Development

### Quick Start

```bash
# 1. Setup all worktrees
./scripts/setup-parallel-worktrees.sh

# 2. Load convenient aliases (optional)
source ./scripts/worktree-aliases.sh

# 3. Navigate to a worktree
wt-sys  # or: cd ../Keystona-worktrees/system-registry

# 4. Open in VSCode
wt-code-sys  # or: code ../Keystona-worktrees/system-registry
```

## Available Scripts

### 1. `setup-parallel-worktrees.sh`
**Purpose:** Create git worktrees for parallel feature development

**Usage:**
```bash
./scripts/setup-parallel-worktrees.sh
```

**What it does:**
- Creates three worktrees in `../Keystona-worktrees/`
- Each worktree has its own branch from `main`:
  - `feature/system-registry` (Issue #7)
  - `feature/appliance-tracking` (Issue #8)
  - `feature/lifespan-indicators` (Issue #9)
- Displays helpful instructions

**Output:**
```
🌳 Git Worktree Setup for Parallel Development
✓ Worktree created: system-registry
✓ Worktree created: appliance-tracking
✓ Worktree created: lifespan-indicators
```

### 2. `manage-worktrees.sh`
**Purpose:** Manage existing worktrees (list, remove, clean)

**Usage:**
```bash
# List all worktrees
./scripts/manage-worktrees.sh list

# Remove specific worktree
./scripts/manage-worktrees.sh remove system-registry

# Remove all worktrees (with confirmation)
./scripts/manage-worktrees.sh clean

# Setup Flutter dependencies in a worktree
./scripts/manage-worktrees.sh flutter system-registry
```

**Commands:**
- `list` - Show all worktrees with paths and branches
- `remove <name>` - Remove worktree and optionally delete branch
- `clean` - Remove all feature worktrees (interactive)
- `flutter <name>` - Run `flutter pub get` in specified worktree

### 3. `worktree-aliases.sh`
**Purpose:** Convenient shell aliases for worktree navigation

**Usage:**
```bash
# Load aliases (run in your current shell)
source ./scripts/worktree-aliases.sh
```

**Aliases:**

| Alias | Action |
|-------|--------|
| `wt-list` | List all worktrees |
| `wt-sys` | cd to system-registry |
| `wt-app` | cd to appliance-tracking |
| `wt-life` | cd to lifespan-indicators |
| `wt-main` | cd to main repository |
| `wt-code-sys` | Open system-registry in VSCode |
| `wt-code-app` | Open appliance-tracking in VSCode |
| `wt-code-life` | Open lifespan-indicators in VSCode |
| `wt-flutter-sys` | Run flutter pub get in system-registry |
| `wt-flutter-app` | Run flutter pub get in appliance-tracking |
| `wt-flutter-life` | Run flutter pub get in lifespan-indicators |

**Tip:** Add to your `.zshrc` or `.bashrc`:
```bash
source ~/Code/Keystona/scripts/worktree-aliases.sh
```

## Workflow Example

### Setting Up for Parallel Development

```bash
# 1. Create all worktrees
./scripts/setup-parallel-worktrees.sh

# 2. Setup Flutter in each worktree
./scripts/manage-worktrees.sh flutter system-registry
./scripts/manage-worktrees.sh flutter appliance-tracking
./scripts/manage-worktrees.sh flutter lifespan-indicators

# 3. Open in separate VSCode windows
code ../Keystona-worktrees/system-registry
code ../Keystona-worktrees/appliance-tracking
code ../Keystona-worktrees/lifespan-indicators
```

### Working on a Feature

```bash
# Navigate to worktree
cd ../Keystona-worktrees/system-registry/hometrack_mobile

# Run app
flutter run

# Make changes, commit
git add .
git commit -m "feat(systems): Add HVAC model"
git push -u origin feature/system-registry
```

### Cleaning Up

```bash
# When feature is merged
./scripts/manage-worktrees.sh remove system-registry

# Or clean all at once
./scripts/manage-worktrees.sh clean
```

## Benefits

**Why use worktrees?**
- Work on 3 features simultaneously without branch switching
- Run different features side-by-side for testing
- Independent Flutter pub get/build per feature
- Reduced risk of mixing changes
- Each feature has its own directory and VSCode window

**Directory Structure:**
```
Code/
├── Keystona/                    # Main repo (feature/home-profile-mvp)
│   ├── hometrack_mobile/
│   └── scripts/
└── Keystona-worktrees/
    ├── system-registry/         # Worktree 1 (feature/system-registry)
    │   └── hometrack_mobile/
    ├── appliance-tracking/      # Worktree 2 (feature/appliance-tracking)
    │   └── hometrack_mobile/
    └── lifespan-indicators/     # Worktree 3 (feature/lifespan-indicators)
        └── hometrack_mobile/
```

## Documentation

See [Git Worktrees Guide](../docs/git-worktrees-guide.md) for detailed documentation.

## Troubleshooting

**"Branch already exists"**
```bash
# If setup fails, clean first
./scripts/manage-worktrees.sh clean
./scripts/setup-parallel-worktrees.sh
```

**"Worktree path not found"**
```bash
# Repair worktree links
git worktree repair
```

**Need to switch main repo to different branch**
```bash
cd /Users/calebbyers/Code/Keystona
git checkout main
```

## Adding New Features

To add a new feature to the automation:

1. Edit `setup-parallel-worktrees.sh`
2. Add to `FEATURES` array:
   ```bash
   "feature/new-feature:10:Feature description"
   ```
3. Re-run setup script
