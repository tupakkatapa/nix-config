#!/usr/bin/env bash

# Initialize verbose and show flags
verbose=false
show=false

# Display usage information
display_usage() {
    cat <<USAGE
Usage: monitor-adjust [options]

Description:
  This script adjusts the monitor settings using ddcutil.

Options:
  -b, --brightness <value>
    Adjust brightness. Value can be <+value>, <-value>, or <value>.

  -c, --contrast <value>
    Adjust contrast. Value can be <+value>, <-value>, or <value>.

  -v, --verbose
    Enable verbose output for debugging.

  --show
    Display the current values of brightness and contrast.

USAGE
}

# Function to print verbose messages
verbose_msg() {
    if $verbose; then
        echo "$@"
    fi
}

# Function to show current values
show_values() {
    echo "Current Monitor Settings:"
    ddcutil getvcp 10 | awk -F'current value = |, max value = ' '/Brightness/{print "Brightness: " $2}'
    ddcutil getvcp 12 | awk -F'current value = |, max value = ' '/Contrast/{print "Contrast: " $2}'
}

# Function to adjust brightness or contrast
adjust_value() {
    local feature_code=$1
    local adjustment=$2
    local current_value max_value new_value

    # Extract current and max value
    read -r current_value max_value < <(ddcutil getvcp "$feature_code" | awk -F'current value = |, max value = ' 'NR==1{print $2" "$3}')
    verbose_msg "Current value: $current_value, Max value: $max_value"

    # Calculate new value
    if [[ $adjustment == +* ]]; then
        new_value=$((current_value + ${adjustment#+}))
    elif [[ $adjustment == -* ]]; then
        new_value=$((current_value - ${adjustment#-}))
    else
        new_value=$adjustment  # Direct value setting
    fi

    # Cap value at max and min values
    new_value=$((new_value > max_value ? max_value : new_value))
    new_value=$((new_value < 0 ? 0 : new_value))

    verbose_msg "Adjusted value: $new_value"

    # Set new value
    ddcutil setvcp "$feature_code" "$new_value"
    echo "Value set to $new_value."
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b | --brightness)
            brightness_value="$2"
            shift 2
            ;;
        -c | --contrast)
            contrast_value="$2"
            shift 2
            ;;
        -v | --verbose)
            verbose=true
            shift
            ;;
        --show)
            show=true
            shift
            ;;
        -h | --help)
            display_usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option -- '$1'"
            echo "Try '--help' for more information."
            exit 1
            ;;
    esac
done

# Show current values if --show is used
if $show; then
    show_values
    exit 0
fi

# Apply adjustments
if [[ -n $brightness_value ]]; then
    adjust_value 10 "$brightness_value"
fi

if [[ -n $contrast_value ]]; then
    adjust_value 12 "$contrast_value"
fi

