#!/bin/bash
#
# add-architecture-links.sh
#
# Adds RHIS Architecture documentation links to component repository READMEs
#
# Usage:
#   ./add-architecture-links.sh /path/to/rhis-builder-repo
#   ./add-architecture-links.sh --all   # Add to all rhis-builder-* repos in parent dir

set -euo pipefail

SNIPPET='## Architecture Documentation

This component is part of the [RHIS (Red Hat Infrastructure Standard)](https://github.com/parmstro/rhis-architecture) platform.

For comprehensive documentation:
- **[Architecture Overview](https://github.com/parmstro/rhis-architecture/blob/main/ARCHITECTURE.md)** - Complete system architecture and design
- **[Repository Inventory](https://github.com/parmstro/rhis-architecture/blob/main/REPOSITORIES.md)** - All RHIS components and relationships
- **[Deployment Guide](https://github.com/parmstro/rhis-architecture/blob/main/DEPLOYMENT.md)** - End-to-end deployment instructions
- **[Dependencies](https://github.com/parmstro/rhis-architecture/blob/main/DEPENDENCIES.md)** - Component dependencies and integration points
- **[Contributing](https://github.com/parmstro/rhis-architecture/blob/main/CONTRIBUTING.md)** - Development standards and workflow

---'

add_to_readme() {
    local repo_path="$1"
    local readme="${repo_path}/README.md"

    if [ ! -f "$readme" ]; then
        echo "⚠️  No README.md found in $repo_path"
        return 1
    fi

    # Check if already has architecture section
    if grep -q "RHIS (Red Hat Infrastructure Standard)" "$readme"; then
        echo "✓  Already has architecture links: $(basename "$repo_path")"
        return 0
    fi

    # Create backup
    cp "$readme" "${readme}.bak"

    # Find insertion point (after first heading and description)
    # Insert after the first section but before "## Requirements" or other sections

    # Simple approach: insert after first paragraph/section
    awk -v snippet="$SNIPPET" '
    BEGIN { inserted=0 }
    /^## / && !inserted && NR > 5 {
        print snippet
        print ""
        inserted=1
    }
    { print }
    END {
        if (!inserted) {
            print ""
            print snippet
        }
    }
    ' "${readme}.bak" > "$readme"

    echo "✓  Added architecture links: $(basename "$repo_path")"
    rm "${readme}.bak"
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <repo-path>"
    echo "   or: $0 --all"
    exit 1
fi

if [ "$1" = "--all" ]; then
    # Find all rhis-builder-* directories in parent directory
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    parent_dir="$(dirname "$script_dir")"
    parent_dir="$(dirname "$parent_dir")"  # Go up one more level from rhis-architecture

    echo "Scanning for rhis-builder-* repositories in: $parent_dir"
    echo ""

    count=0
    for repo in "$parent_dir"/rhis-builder-*/; do
        if [ -d "$repo" ]; then
            add_to_readme "$repo" || true
            ((count++))
        fi
    done

    echo ""
    echo "Processed $count repositories"
else
    add_to_readme "$1"
fi

echo ""
echo "Done! Review changes with 'git diff' before committing."
