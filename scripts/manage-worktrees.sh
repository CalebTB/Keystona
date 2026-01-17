#!/bin/bash
# manage-worktrees.sh
# Manage git worktrees: list, remove, clean

set -e

REPO_ROOT="/Users/calebbyers/Code/Keystona"
WORKTREE_BASE="$REPO_ROOT/../Keystona-worktrees"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to display usage
usage() {
  echo -e "${BLUE}Git Worktree Manager${NC}\n"
  echo "Usage: $0 [command]"
  echo ""
  echo "Commands:"
  echo "  list           - List all worktrees"
  echo "  remove <name>  - Remove a specific worktree"
  echo "  clean          - Remove all feature worktrees"
  echo "  flutter <name> - Run flutter pub get in a worktree"
  echo "  help           - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 list"
  echo "  $0 remove system-registry"
  echo "  $0 flutter appliance-tracking"
  echo "  $0 clean"
}

# Function to list worktrees
list_worktrees() {
  echo -e "${BLUE}Current worktrees:${NC}\n"
  cd "$REPO_ROOT"
  git worktree list
}

# Function to remove a specific worktree
remove_worktree() {
  local name=$1
  if [ -z "$name" ]; then
    echo -e "${RED}Error: Please specify a worktree name${NC}"
    echo "Example: $0 remove system-registry"
    exit 1
  fi

  local worktree_path="$WORKTREE_BASE/$name"
  local branch_name="feature/$name"

  if [ ! -d "$worktree_path" ]; then
    echo -e "${RED}Error: Worktree '$name' not found at $worktree_path${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Removing worktree: $name${NC}"
  cd "$REPO_ROOT"

  # Remove worktree
  git worktree remove "$worktree_path"
  echo -e "${GREEN}✓ Worktree removed${NC}"

  # Ask if branch should be deleted
  read -p "Delete branch '$branch_name'? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch -D "$branch_name"
    echo -e "${GREEN}✓ Branch deleted${NC}"
  fi
}

# Function to clean all worktrees
clean_worktrees() {
  echo -e "${YELLOW}This will remove all worktrees in $WORKTREE_BASE${NC}"
  read -p "Are you sure? (y/n) " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
  fi

  cd "$REPO_ROOT"

  # Get all worktrees except main
  git worktree list | grep -v "^\[main\]" | awk '{print $1}' | while read -r path; do
    if [[ "$path" == "$WORKTREE_BASE"* ]]; then
      echo -e "${YELLOW}Removing: $path${NC}"
      git worktree remove "$path"
    fi
  done

  echo -e "${GREEN}✓ All worktrees cleaned${NC}"

  # Ask about branches
  read -p "Delete all feature branches? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch | grep "feature/" | xargs git branch -D
    echo -e "${GREEN}✓ Feature branches deleted${NC}"
  fi
}

# Function to run flutter pub get in a worktree
flutter_setup() {
  local name=$1
  if [ -z "$name" ]; then
    echo -e "${RED}Error: Please specify a worktree name${NC}"
    echo "Example: $0 flutter system-registry"
    exit 1
  fi

  local worktree_path="$WORKTREE_BASE/$name"
  local flutter_path="$worktree_path/hometrack_mobile"

  if [ ! -d "$flutter_path" ]; then
    echo -e "${RED}Error: Flutter project not found at $flutter_path${NC}"
    exit 1
  fi

  echo -e "${BLUE}Running flutter pub get in $name...${NC}"
  cd "$flutter_path"
  flutter pub get
  echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Main command handler
case "${1:-help}" in
  list)
    list_worktrees
    ;;
  remove)
    remove_worktree "$2"
    ;;
  clean)
    clean_worktrees
    ;;
  flutter)
    flutter_setup "$2"
    ;;
  help|*)
    usage
    ;;
esac
