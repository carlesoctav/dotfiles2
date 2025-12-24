#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="$HOME/dotfiles/.config"
DEFAULT_CONFIG="$HOME/.config"

echo "Pruning default configs from $DEFAULT_CONFIG"
for source_path in "$CONFIG_ROOT"/*; do
    [ -e "$source_path" ] || continue
    entry_name="$(basename "$source_path")"
    target_path="$DEFAULT_CONFIG/$entry_name"

    if [ -L "$target_path" ]; then
        link_target="$(readlink -f "$target_path")"
        source_target="$(realpath "$source_path")"
        if [ "$link_target" = "$source_target" ]; then
            echo "  skipping linked $target_path"
            continue
        fi
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        echo "  removing $target_path"
        rm -rf -- "$target_path"
    fi
done

bashrc_target="$HOME/.bashrc"
if [ -L "$bashrc_target" ]; then
    bashrc_link="$(readlink -f "$bashrc_target")"
    if [ -e "$HOME/dotfiles/.bashrc" ]; then
        dotfiles_bashrc="$(realpath "$HOME/dotfiles/.bashrc")"
    else
        dotfiles_bashrc=""
    fi
    if [ -n "$dotfiles_bashrc" ] && [ "$bashrc_link" = "$dotfiles_bashrc" ]; then
        echo "Skipping linked $bashrc_target"
        bashrc_target=""
    fi
fi

if [ -n "$bashrc_target" ] && { [ -e "$bashrc_target" ] || [ -L "$bashrc_target" ]; }; then
    echo "Removing $HOME/.bashrc"
    rm -f -- "$HOME/.bashrc"
fi

echo "Done."
