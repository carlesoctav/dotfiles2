#!/usr/bin/env bash

set -e

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -o, --output DIR    Output directory for saved chats (default: ~/saved_chats)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "This script helps you save opencode chat sessions as markdown files."
    echo "It will:"
    echo "1. Let you select a repository using fzf"
    echo "2. Let you select a session from that repository using fzf"
    echo "3. Render the session to a markdown file"
}

# Default output directory
OUTPUT_DIR="$HOME/personal/saved_chats"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "🔍 Selecting repository..."

# Step 1: Select repository using fzf
selected_repo=$(find ~/personal ~/work ~/.config ~/.local ~/dotfiles/.config ~/dotfiles/ ~/learn -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf --prompt="Select repository: " --height=40% --border)

if [[ -z $selected_repo ]]; then
    echo "❌ No repository selected. Exiting."
    exit 0
fi

echo "📁 Selected repository: $selected_repo"
echo "🔍 Loading sessions..."

# Step 2: Get sessions for the selected repository and let user select one
sessions_output=$(cnotes sessions "$selected_repo" 2>/dev/null)

if [[ -z $sessions_output ]]; then
    echo "❌ No sessions found for repository: $selected_repo"
    exit 1
fi

echo "📋 Found $(echo "$sessions_output" | wc -l) session(s)"

# Create a more readable format for fzf: "session_id - title"
sessions_for_fzf=$(echo "$sessions_output" | awk '{
    session_id = $1
    title = ""
    for(i=2; i<=NF; i++) {
        if(i==2) title = $i
        else title = title " " $i
    }
    # Replace underscores with spaces in title for display
    gsub(/_/, " ", title)
    print session_id " - " title
}')

selected_session_line=$(echo "$sessions_for_fzf" | fzf --prompt="Select session: " --height=40% --border)

if [[ -z $selected_session_line ]]; then
    echo "❌ No session selected. Exiting."
    exit 0
fi

# Extract session ID from the selected line
session_id=$(echo "$selected_session_line" | awk '{print $1}')
session_title=$(echo "$selected_session_line" | cut -d' ' -f3- | tr ' ' '_')

echo "💬 Selected session: $session_id"
echo "📝 Session title: $session_title"

# Step 3: Let user customize output path
repo_name=$(basename "$selected_repo")
timestamp=$(date +"%Y%m%d_%H%M%S")
default_filename="${repo_name}_${session_title}_${timestamp}.md"

echo "📁 Customizing output path..."

# Predefined output options
output_options=(
    "$OUTPUT_DIR/$default_filename"
    "$OUTPUT_DIR/by_repo/$repo_name/$default_filename"
    "$OUTPUT_DIR/by_date/$(date +%Y)/$(date +%m)/$default_filename"
    "$OUTPUT_DIR/by_topic/$session_title/$default_filename"
    "Custom path..."
)

# Use fzf to select output path
selected_output=$(printf '%s\n' "${output_options[@]}" | fzf --prompt="Select output path: " --height=40% --border)

if [[ -z $selected_output ]]; then
    echo "❌ No output path selected. Exiting."
    exit 0
fi

if [[ $selected_output == "Custom path..." ]]; then
    echo "📝 Enter custom path (relative to $OUTPUT_DIR):"
    read -r custom_path
    if [[ -z $custom_path ]]; then
        echo "❌ No custom path provided. Exiting."
        exit 0
    fi
    # If custom path doesn't end with .md, append default filename
    if [[ $custom_path != *.md ]]; then
        output_file="$OUTPUT_DIR/$custom_path/$default_filename"
    else
        output_file="$OUTPUT_DIR/$custom_path"
    fi
else
    output_file="$selected_output"
fi

# Create directory if it doesn't exist
output_dir=$(dirname "$output_file")
mkdir -p "$output_dir"

echo "💾 Rendering session to: $output_file"

# Step 4: Render the session to markdown
if cnotes render "$selected_repo" "$session_id" -o "$output_file"; then
    echo "✅ Chat saved successfully!"
    echo "📄 File: $output_file"
    
    # Show file size and first few lines as confirmation
    file_size=$(du -h "$output_file" | cut -f1)
    echo "📊 File size: $file_size"
    
    echo ""
    echo "📖 Preview (first 10 lines):"
    echo "─────────────────────────────────"
    head -10 "$output_file"
    echo "─────────────────────────────────"
    
    # Ask if user wants to open the file
    echo ""
    read -p "🔍 Open the file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create tmux session for saved_chats and open with nvim
        session_name="saved_chats"
        saved_chats_dir="$HOME/personal/saved_chats"
        
        # Check if tmux is available
        if ! command -v tmux >/dev/null 2>&1; then
            echo "❌ tmux not found. Opening with available editor..."
            if command -v nvim >/dev/null 2>&1; then
                nvim "$output_file"
            elif command -v vim >/dev/null 2>&1; then
                vim "$output_file"
            else
                echo "📝 No suitable editor found. File saved at: $output_file"
            fi
            exit 0
        fi
        
        # Check if nvim is available
        if ! command -v nvim >/dev/null 2>&1; then
            echo "❌ nvim not found. Using vim instead..."
            editor="vim"
        else
            editor="nvim"
        fi
        
        tmux_running=$(pgrep tmux)
        
        # Create tmux session if it doesn't exist
        if ! tmux has-session -t="$session_name" 2>/dev/null; then
            tmux new-session -ds "$session_name" -c "$saved_chats_dir"
        fi
        
        # Open the file in nvim within the tmux session
        tmux send-keys -t "$session_name" "$editor \"$output_file\"" Enter
        
        # Attach to the session if not already in tmux, otherwise switch to it
        if [[ -z $TMUX ]]; then
            echo "🚀 Opening in tmux session '$session_name' with $editor..."
            tmux attach -t "$session_name"
        else
            echo "🚀 Switching to tmux session '$session_name' with $editor..."
            tmux switch-client -t "$session_name"
        fi
    fi
else
    echo "❌ Failed to render session"
    exit 1
fi