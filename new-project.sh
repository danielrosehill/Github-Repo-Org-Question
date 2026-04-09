#!/bin/bash
# Spin out a clean research project from this template.
# Usage: ./new-project.sh <project-name> [destination-dir]
#
# Example:
#   ./new-project.sh "ai-regulation-research" ~/repos/github/

set -euo pipefail

PROJECT_NAME="${1:?Usage: ./new-project.sh <project-name> [destination-dir]}"
DEST_DIR="${2:-.}"
TARGET="$DEST_DIR/$PROJECT_NAME"

if [ -d "$TARGET" ]; then
    echo "Error: $TARGET already exists"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy template structure
cp -r "$SCRIPT_DIR" "$TARGET"

# Clean out example files and git history
rm -rf "$TARGET/.git"
rm -f "$TARGET/prompts/run/initial/example-initial-prompt.md"
rm -f "$TARGET/prompts/run/subsequent/example-subsequent-prompt.md"
rm -f "$TARGET/new-project.sh"

# Reset the research brief to blank template
cat > "$TARGET/context/from-human/research-brief.md" << 'EOF'
# Research Brief

## Topic



## Scope



## Background



## Key Questions

1.
2.
3.

## Constraints



## Desired Output

EOF

# Initialise fresh git repo
cd "$TARGET"
git init
git add -A
git commit -m "Initialise research workspace: $PROJECT_NAME"

echo ""
echo "Research workspace created at: $TARGET"
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Edit context/from-human/research-brief.md"
echo "  3. Add your first prompt to prompts/run/initial/"
echo "  4. Open in Claude Code and start researching"
