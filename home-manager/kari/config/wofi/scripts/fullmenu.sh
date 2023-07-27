#!/bin/bash
CONFIG="$HOME/.config/wofi/full_config"
STYLE="$HOME/.config/wofi/full_style.css"
COLORS="$HOME/.config/wofi/full_colors"

if [[ ! $(pidof wofi) ]]; then
	wofi --show drun --prompt 'Search...' --conf ${CONFIG} --style ${STYLE} --color ${COLORS}
else
	pkill wofi
fi