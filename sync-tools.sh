#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/external"
CONFIG_FILE="$SCRIPT_DIR/tools.yaml"
ZSHRC_FILE="$HOME/.zshrc"

# Markers for managed aliases section
ALIAS_START_MARKER="# === Sync-Tools Managed Aliases (DO NOT EDIT) ==="
ALIAS_END_MARKER="# === End Sync-Tools Managed Aliases ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for yq (YAML parser)
if ! command -v yq &> /dev/null; then
    log_error "yq is required but not installed."
    echo "Install with: brew install yq"
    exit 1
fi

# Create tools directory if it doesn't exist
mkdir -p "$TOOLS_DIR"

# Parse tools.yaml and sync each tool
tool_count=$(yq '.tools | length' "$CONFIG_FILE")

if [ "$tool_count" == "0" ] || [ "$tool_count" == "null" ]; then
    log_warn "No tools configured in tools.yaml"
    echo "Add your repos to tools.yaml to get started."
    exit 0
fi

log_info "Syncing $tool_count tool(s)..."

for i in $(seq 0 $((tool_count - 1))); do
    name=$(yq -r ".tools[$i].name" "$CONFIG_FILE")
    repo=$(yq -r ".tools[$i].repo" "$CONFIG_FILE")
    branch=$(yq -r ".tools[$i].branch // \"\"" "$CONFIG_FILE")
    
    tool_path="$TOOLS_DIR/$name"
    
    echo ""
    log_info "Processing: $name"
    
    if [ -d "$tool_path" ]; then
        # Tool exists - pull latest
        log_info "  Updating existing repo..."
        cd "$tool_path"
        git fetch --all --prune
        
        if [ -n "$branch" ] && [ "$branch" != "null" ]; then
            git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch"
        fi
        
        git pull --ff-only || log_warn "  Could not fast-forward, may have local changes"
        cd "$SCRIPT_DIR"
    else
        # Tool doesn't exist - clone it
        log_info "  Cloning fresh..."
        if [ -n "$branch" ] && [ "$branch" != "null" ]; then
            git clone --branch "$branch" "$repo" "$tool_path"
        else
            git clone "$repo" "$tool_path"
        fi
    fi
    
    # Run post-sync hook if defined
    post_sync=$(yq -r ".tools[$i].post_sync // \"\"" "$CONFIG_FILE")
    if [ -n "$post_sync" ] && [ "$post_sync" != "null" ]; then
        log_info "  Running post-sync: $post_sync"
        (cd "$tool_path" && eval "$post_sync")
    fi

    log_info "  Done: $name"
done

echo ""
log_info "Sync complete!"

# === Alias Management ===
log_info "Updating aliases in dot_zshrc..."

# Build aliases into a temp file
TEMP_ALIASES=$(mktemp)
echo "$ALIAS_START_MARKER" > "$TEMP_ALIASES"

for i in $(seq 0 $((tool_count - 1))); do
    name=$(yq -r ".tools[$i].name" "$CONFIG_FILE")
    alias_name=$(yq -r ".tools[$i].alias.name // \"\"" "$CONFIG_FILE")
    alias_command=$(yq -r ".tools[$i].alias.command // \"\"" "$CONFIG_FILE")
    
    if [ -n "$alias_name" ] && [ "$alias_name" != "null" ] && [ -n "$alias_command" ] && [ "$alias_command" != "null" ]; then
        tool_path="$TOOLS_DIR/$name"
        full_command="$tool_path/$alias_command"
        echo "alias $alias_name='$full_command'" >> "$TEMP_ALIASES"
        log_info "  Added alias: $alias_name -> $full_command"
    fi
done

echo "$ALIAS_END_MARKER" >> "$TEMP_ALIASES"

# Remove old managed section if it exists
if grep -q "$ALIAS_START_MARKER" "$ZSHRC_FILE"; then
    sed -i '' "/$ALIAS_START_MARKER/,/$ALIAS_END_MARKER/d" "$ZSHRC_FILE"
fi

# Insert after "# === Custom Aliases ===" line
if grep -q "# === Custom Aliases ===" "$ZSHRC_FILE"; then
    # Use sed to insert after the marker line
    sed -i '' "/# === Custom Aliases ===/r $TEMP_ALIASES" "$ZSHRC_FILE"
    log_info "Aliases added to dot_zshrc"
else
    # Append to end if marker not found
    echo "" >> "$ZSHRC_FILE"
    cat "$TEMP_ALIASES" >> "$ZSHRC_FILE"
    log_info "Aliases appended to dot_zshrc"
fi

rm "$TEMP_ALIASES"

echo ""
log_info "All done!"
