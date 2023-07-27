#!/bin/bash

# Config
CONFIG="$HOME/.config/wofi/config_drun"
STYLE="$HOME/.config/wofi/style.css"
COLORS="$HOME/.config/wofi/colors"

if [[ ! $(pidof wofi) ]]; then
	wofi --prompt 'Search...' --conf ${CONFIG} --style ${STYLE} --color ${COLORS}
else
	pkill wofi
fi