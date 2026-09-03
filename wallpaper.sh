#!/usr/bin/env bash

set -e

CONFIG="$HOME/.config/hypr/hyprpaper.conf"
WALLPAPER_DIR="$HOME/Pictures/Wallpaper"

SDDM_DIR="/usr/share/sddm/themes/sugar-dark"
SDDM_BACKGROUND="$SDDM_DIR/Background.jpg"

HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock/general/background.conf"

clear

# --------------------------------------------------
# Check requirements
# --------------------------------------------------

for cmd in fzf magick kitten sed; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# --------------------------------------------------
# Check paths
# --------------------------------------------------

if [ ! -f "$CONFIG" ]; then
    echo "Error: Hyprpaper config not found:"
    echo "$CONFIG"
    exit 1
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory not found:"
    echo "$WALLPAPER_DIR"
    exit 1
fi

if [ ! -d "$SDDM_DIR" ]; then
    echo "Error: SDDM theme directory not found:"
    echo "$SDDM_DIR"
    exit 1
fi

if [ ! -f "$HYPRLOCK_CONFIG" ]; then
	echo "Error: Hyprlock background config not found:"
	echo "$HYPRLOCK_CONFIG"
	exit 1
fi

# --------------------------------------------------
# Select wallpaper with preview
# --------------------------------------------------

wallpaper=$(
    find "$WALLPAPER_DIR" \
        -maxdepth 1 \
        -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | sort \
        | fzf \
            --prompt="Wallpaper > " \
            --height=90% \
            --border \
            --preview-window="right:60%" \
            --preview="kitten icat --clear --transfer-mode=memory --stdin=no --place=\"\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0\" {}"
) || true

# Exit cleanly if Esc was pressed
if [ -z "$wallpaper" ]; then
    clear
    echo "No wallpaper selected."
    exit 0
fi

# Double-check selected file
if [ ! -f "$wallpaper" ]; then
    echo "Error: Selected wallpaper does not exist."
    exit 1
fi

# --------------------------------------------------
# Update Hyprpaper
# --------------------------------------------------

sed -i \
    "s|^[[:space:]]*path = .*|	path = $wallpaper|" \
    "$CONFIG"

pkill hyprpaper 2>/dev/null || true
hyprpaper >/dev/null 2>&1 &



# --------------------------------------------------
# Update Hyprlock background
# --------------------------------------------------

sed -i \
    "s|^[[:space:]]*path = .*|    path = $wallpaper|" \
    "$HYPRLOCK_CONFIG"


# --------------------------------------------------
# Prepare SDDM background
# --------------------------------------------------

TEMP_BACKGROUND="$(mktemp --suffix=.jpg)"

# Always remove temporary file when script exits
trap 'rm -f -- "$TEMP_BACKGROUND"' EXIT

# Convert selected image to a real JPEG
magick "$wallpaper" "$TEMP_BACKGROUND"

# --------------------------------------------------
# Replace SDDM background
# --------------------------------------------------

# Extra sanity check: don't proceed unless the existing
# SDDM background and your backup both exist.
if [ ! -f "$SDDM_BACKGROUND" ]; then
    echo "Error: Existing SDDM background not found:"
    echo "$SDDM_BACKGROUND"
    exit 1
fi

# This is the ONLY operation performed as root.
sudo install -m 0644 \
    "$TEMP_BACKGROUND" \
    "$SDDM_BACKGROUND"

# --------------------------------------------------
# Finished
# --------------------------------------------------

clear

echo "Wallpaper changed successfully."
echo
echo "Desktop:"
echo "  $wallpaper"
echo
echo "Lock screen:"
echo "  $HYPRLOCK_CONFIG"
echo
echo "SDDM:"
echo "  $SDDM_BACKGROUND"
