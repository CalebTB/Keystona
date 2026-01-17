#!/bin/bash
# setup-parallel-worktrees.sh
# Automates git worktree creation for parallel feature development

set -e  # Exit on error

REPO_ROOT="/Users/calebbyers/Code/Keystona"
WORKTREE_BASE="$REPO_ROOT/../Keystona-worktrees"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌳 Git Worktree Setup for Parallel Development${NC}\n"

# Feature definitions: branch_name:issue_number:description
FEATURES=(
  "feature/system-registry:7:System Registry - HVAC, Water Heater, Roof tracking"
  "feature/appliance-tracking:8:Appliance Tracking with OCR label extraction"
  "feature/lifespan-indicators:9:Lifespan Indicators - Progress bars and alerts"
)

# Create base directory for worktrees
mkdir -p "$WORKTREE_BASE"

echo -e "${BLUE}Base worktree directory: ${YELLOW}$WORKTREE_BASE${NC}\n"

# Function to create a worktree
create_worktree() {
  local branch_name=$1
  local issue_num=$2
  local description=$3
  local worktree_path="$WORKTREE_BASE/${branch_name#feature/}"

  echo -e "${GREEN}Creating worktree for: ${YELLOW}$description${NC}"
  echo -e "  Branch: ${BLUE}$branch_name${NC}"
  echo -e "  Path: ${YELLOW}$worktree_path${NC}"

  # Check if worktree already exists
  if [ -d "$worktree_path" ]; then
    echo -e "  ${YELLOW}⚠️  Worktree already exists, skipping...${NC}\n"
    return
  fi

  # Create worktree from main branch
  cd "$REPO_ROOT"
  git worktree add -b "$branch_name" "$worktree_path" main

  echo -e "  ${GREEN}✓ Worktree created${NC}\n"
}

# Create worktrees for each feature
for feature in "${FEATURES[@]}"; do
  IFS=':' read -r branch issue desc <<< "$feature"
  create_worktree "$branch" "$issue" "$desc"
done

# Print summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Worktree Setup Complete!${NC}\n"

echo -e "${BLUE}Your worktrees:${NC}"
git worktree list

echo -e "\n${BLUE}To switch between features:${NC}"
echo -e "  ${YELLOW}cd $WORKTREE_BASE/system-registry${NC}"
echo -e "  ${YELLOW}cd $WORKTREE_BASE/appliance-tracking${NC}"
echo -e "  ${YELLOW}cd $WORKTREE_BASE/lifespan-indicators${NC}"

echo -e "\n${BLUE}To work on a feature:${NC}"
echo -e "  1. ${YELLOW}cd $WORKTREE_BASE/<feature-name>${NC}"
echo -e "  2. Make your changes"
echo -e "  3. ${YELLOW}git add . && git commit -m \"your message\"${NC}"
echo -e "  4. ${YELLOW}git push -u origin <branch-name>${NC}"

echo -e "\n${BLUE}To remove a worktree when done:${NC}"
echo -e "  ${YELLOW}cd $REPO_ROOT${NC}"
echo -e "  ${YELLOW}git worktree remove $WORKTREE_BASE/<feature-name>${NC}"
echo -e "  ${YELLOW}git branch -d <branch-name>${NC}"

echo -e "\n${BLUE}Pro tip:${NC} Open each worktree in a separate VSCode window for parallel development!"
echo -e "  ${YELLOW}code $WORKTREE_BASE/system-registry${NC}"
echo -e "  ${YELLOW}code $WORKTREE_BASE/appliance-tracking${NC}"
echo -e "  ${YELLOW}code $WORKTREE_BASE/lifespan-indicators${NC}"
