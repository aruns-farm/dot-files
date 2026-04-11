#!/usr/bin/env zsh
# ============================================================
# folder-structure.sh — Arun's Documents + Dev Folder Setup
# Run: zsh folder-structure.sh
# ============================================================

echo "📁  Setting up folder structure..."

DOCS="$HOME/Documents"
DEV="$HOME/dev"

# ── Documents ────────────────────────────────────────────────
mkdir -p "$DOCS/office"/{projects,meetings,resources,archive}
mkdir -p "$DOCS/personal"/{projects,finance,notes,archive}
mkdir -p "$DOCS/professional"/{projects,clients,resources,archive}

# ── Dev workspace ────────────────────────────────────────────
mkdir -p "$DEV/office"
mkdir -p "$DEV/personal"
mkdir -p "$DEV/professional"
mkdir -p "$DEV/sandbox"

echo ""
echo "✅  Done:"
echo ""
echo "~/Documents/"
echo "  ├── office/       (projects, meetings, resources, archive)"
echo "  ├── personal/     (projects, finance, notes, archive)"
echo "  └── professional/ (projects, clients, resources, archive)"
echo ""
echo "~/dev/"
echo "  ├── office/       ← git uses office email here"
echo "  ├── personal/     ← git uses personal email here"
echo "  ├── professional/ ← git uses professional email here"
echo "  └── sandbox/      ← experiments"
echo ""
