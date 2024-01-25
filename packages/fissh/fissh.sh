#!/usr/bin/env bash

# Check arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$#" -lt 1 ]; then
    echo "Usage: fissh <destination>"
    exit 1
fi

# Transfer the fish config
ssh "$1" 'cat > /tmp/config.fish' < ~/.config/fish/config.fish

# Connect to the remote server
ssh -At "$1" 'fish --init-command "source /tmp/config.fish; rm /tmp/config.fish"'

