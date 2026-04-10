#!/usr/bin/env zsh
# ============================================================
# folder-structure.sh — Arun's Documents Folder Setup
# Creates a consistent workspace layout every time
# Run: zsh folder-structure.sh
# ============================================================

echo "📁  Setting up Documents folder structure..."

DOCS="$HOME/Documents"

# ── Main Categories ──────────────────────────────────────────
mkdir -p "$DOCS/office"
mkdir -p "$DOCS/personal"
mkdir -p "$DOCS/professional"

# ── Office Subfolders ────────────────────────────────────────
mkdir -p "$DOCS/office/projects"
mkdir -p "$DOCS/office/meetings"
mkdir -p "$DOCS/office/resources"
mkdir -p "$DOCS/office/archive"

# ── Personal Subfolders ──────────────────────────────────────
mkdir -p "$DOCS/personal/projects"
mkdir -p "$DOCS/personal/finance"
mkdir -p "$DOCS/personal/notes"
mkdir -p "$DOCS/personal/archive"

# ── Professional Subfolders ──────────────────────────────────
mkdir -p "$DOCS/professional/projects"
mkdir -p "$DOCS/professional/clients"
mkdir -p "$DOCS/professional/resources"
mkdir -p "$DOCS/professional/archive"

# ── Dev Workspace ────────────────────────────────────────────
# A dedicated spot for code — separate from docs
mkdir -p "$HOME/dev"
mkdir -p "$HOME/dev/office"
mkdir -p "$HOME/dev/personal"
mkdir -p "$HOME/dev/professional"
mkdir -p "$HOME/dev/sandbox"       # for experiments / throw-away projects

# ── Print the structure ──────────────────────────────────────
echo ""
echo "✅  Folder structure created:"
echo ""
echo "~/Documents/"
echo "  ├── office/"
echo "  │   ├── projects/"
echo "  │   ├── meetings/"
echo "  │   ├── resources/"
echo "  │   └── archive/"
echo "  ├── personal/"
echo "  │   ├── projects/"
echo "  │   ├── finance/"
echo "  │   ├── notes/"
echo "  │   └── archive/"
echo "  └── professional/"
echo "      ├── projects/"
echo "      ├── clients/"
echo "      ├── resources/"
echo "      └── archive/"
echo ""
echo "~/dev/"
echo "  ├── office/"
echo "  ├── personal/"
echo "  ├── professional/"
echo "  └── sandbox/"
echo ""
