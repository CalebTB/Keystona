#!/bin/bash
# worktree-aliases.sh
# Source this file to add convenient aliases for worktree navigation
#
# Usage: source ./scripts/worktree-aliases.sh

WORKTREE_BASE="/Users/calebbyers/Code/Keystona-worktrees"

# Navigation aliases
alias wt-list='git worktree list'
alias wt-sys='cd $WORKTREE_BASE/system-registry'
alias wt-app='cd $WORKTREE_BASE/appliance-tracking'
alias wt-life='cd $WORKTREE_BASE/lifespan-indicators'
alias wt-main='cd /Users/calebbyers/Code/Keystona'

# Quick VSCode opener
alias wt-code-sys='code $WORKTREE_BASE/system-registry'
alias wt-code-app='code $WORKTREE_BASE/appliance-tracking'
alias wt-code-life='code $WORKTREE_BASE/lifespan-indicators'

# Flutter shortcuts
alias wt-flutter-sys='cd $WORKTREE_BASE/system-registry/hometrack_mobile && flutter pub get'
alias wt-flutter-app='cd $WORKTREE_BASE/appliance-tracking/hometrack_mobile && flutter pub get'
alias wt-flutter-life='cd $WORKTREE_BASE/lifespan-indicators/hometrack_mobile && flutter pub get'

echo "✓ Worktree aliases loaded!"
echo ""
echo "Navigation:"
echo "  wt-sys   - Go to system-registry worktree"
echo "  wt-app   - Go to appliance-tracking worktree"
echo "  wt-life  - Go to lifespan-indicators worktree"
echo "  wt-main  - Go to main repository"
echo "  wt-list  - List all worktrees"
echo ""
echo "Open in VSCode:"
echo "  wt-code-sys   - Open system-registry in VSCode"
echo "  wt-code-app   - Open appliance-tracking in VSCode"
echo "  wt-code-life  - Open lifespan-indicators in VSCode"
echo ""
echo "Flutter setup:"
echo "  wt-flutter-sys   - Run flutter pub get in system-registry"
echo "  wt-flutter-app   - Run flutter pub get in appliance-tracking"
echo "  wt-flutter-life  - Run flutter pub get in lifespan-indicators"
