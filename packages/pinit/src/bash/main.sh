#!/usr/bin/env bash
# This script checks if the user is the root user and responds accordingly

if [ "$EUID" -eq 0 ]; then
    echo "You are running this script as the root user."
else
    echo "You are not the root user. Please run this script with sudo."
fi
