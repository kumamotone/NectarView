#!/bin/bash

# Function to display help
function display_help {
    echo "Usage: sh create-dmg.sh [directory]"
    echo "Navigates to the specified directory and executes create-dmg."
    echo "Example: sh create-dmg.sh ~/Downloads/NectarView\\ 2024-10-18\\ 07-45-32"
}

# Check if no arguments or help flag is passed
if [ "$#" -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    exit 0
fi

# Target directory specified by the argument
target_dir="$1"

# Remove trailing slash from target_dir if present
target_dir=$(echo "$target_dir" | sed 's:/*$::')

# Check if the specified directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: The specified directory does not exist."
    exit 1
fi

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "create-dmg is not installed. Please install it using 'brew install create-dmg'."
    exit 1
fi

# Navigate to the specified directory
cd "$target_dir" || exit

# Execute the create-dmg command
create-dmg \
    --volname "NectarView Installer" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "NectarView.app" 150 190 \
    --hide-extension "NectarView.app" \
    --app-drop-link 450 190 \
    --no-internet-enable \
    "NectarView.dmg" \
    NectarView.app