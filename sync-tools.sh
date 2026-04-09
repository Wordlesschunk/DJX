#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/external"
CONFIG_FILE="$SCRIPT_DIR/tools.yaml"
ZSHRC_FILE="$HOME/.zshrc"

# Markers for managed aliases section
ALIAS_START_MARKER="# === Sync-Tools Managed Aliases (DO NOT EDIT) ==="
ALIAS_END_MARKER="# === End Sync-Tools Managed Aliases ==="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Icons
CHECK="✓"
ARROW="→"
WARN="⚠"
ERROR="✗"

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${YELLOW}${ARROW}${NC} $1"
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}${WARN}${NC} $1"
}

print_error() {
    echo -e "${RED}${ERROR}${NC} $1"
}

print_header "DJX Tool Sync"

# Check for yq (YAML parser)
echo ""
print_step "Checking dependencies..."
if ! command -v yq &> /dev/null; then
    print_error "yq is required but not installed"
    echo -e "  Install with: ${CYAN}brew install yq${NC}"
    exit 1
fi
print_success "yq found"

# Create tools directory if it doesn't exist
mkdir -p "$TOOLS_DIR"

# Parse tools.yaml and sync each tool
tool_count=$(yq '.tools | length' "$CONFIG_FILE")

if [ "$tool_count" == "0" ] || [ "$tool_count" == "null" ]; then
    print_warn "No tools configured in tools.yaml"
    echo -e "  Add your repos to ${CYAN}tools.yaml${NC} to get started"
    exit 0
fi

print_header "Syncing $tool_count tool(s)"

for i in $(seq 0 $((tool_count - 1))); do
    name=$(yq -r ".tools[$i].name" "$CONFIG_FILE")
    repo=$(yq -r ".tools[$i].repo" "$CONFIG_FILE")
    branch=$(yq -r ".tools[$i].branch // \"\"" "$CONFIG_FILE")
    
    tool_path="$TOOLS_DIR/$name"
    
    echo ""
    echo -e "  ${CYAN}${name}${NC}"
    
    if [ -d "$tool_path" ]; then
        # Tool exists - pull latest
        print_step "Updating existing repo..."
        cd "$tool_path"
        git fetch --all --prune
        
        if [ -n "$branch" ] && [ "$branch" != "null" ]; then
            git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch"
        fi
        
        git pull --ff-only || print_warn "Could not fast-forward, may have local changes"
        cd "$SCRIPT_DIR"
        print_success "Updated"
    else
        # Tool doesn't exist - clone it
        print_step "Cloning fresh..."
        if [ -n "$branch" ] && [ "$branch" != "null" ]; then
            git clone --branch "$branch" "$repo" "$tool_path"
        else
            git clone "$repo" "$tool_path"
        fi
        print_success "Cloned"
    fi
    
    # Run post-sync hook if defined
    post_sync=$(yq -r ".tools[$i].post_sync // \"\"" "$CONFIG_FILE")
    if [ -n "$post_sync" ] && [ "$post_sync" != "null" ]; then
        print_step "Running post-sync hook..."
        (cd "$tool_path" && eval "$post_sync")
        print_success "Post-sync complete"
    fi
done

print_header "Updating Aliases"

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
        print_success "${alias_name} → ${full_command}"
    fi
done

echo "$ALIAS_END_MARKER" >> "$TEMP_ALIASES"

# Remove old managed section if it exists
if grep -q "$ALIAS_START_MARKER" "$ZSHRC_FILE"; then
    sed -i '' "/$ALIAS_START_MARKER/,/$ALIAS_END_MARKER/d" "$ZSHRC_FILE"
fi

# Insert after "# === Custom Aliases ===" line
echo ""
if grep -q "# === Custom Aliases ===" "$ZSHRC_FILE"; then
    sed -i '' "/# === Custom Aliases ===/r $TEMP_ALIASES" "$ZSHRC_FILE"
    print_success "Aliases added to dot_zshrc"
else
    echo "" >> "$ZSHRC_FILE"
    cat "$TEMP_ALIASES" >> "$ZSHRC_FILE"
    print_success "Aliases appended to dot_zshrc"
fi

rm "$TEMP_ALIASES"

echo ""
print_step "Making scripts executable..."
find "$TOOLS_DIR" -name "*.sh" -type f -exec chmod +x {} \;
print_success "All .sh files in external/ are executable"

print_header "${CHECK} Sync Complete!"
echo ""
echo -e "  ${GREEN}Your tools are ready to use${NC}"
echo ""
