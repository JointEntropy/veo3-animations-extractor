#!/bin/bash

set -e  # Exit on error

# Input video file
INPUT_VIDEO="examples/input.mp4"

# Animation configurations
# Format: "name|start_time|end_time|width|height|offset_x|offset_y|fps"
# Use pipe separator to avoid conflict with HH:MM:SS time format
ANIMATIONS=(
    "JUMP|00:00:00|00:00:04|605|605|28|218|12"
    "IDLE|00:00:00|00:00:04|605|605|650|218|12"
    "STUNNED|00:00:00|00:00:04|605|605|1272|218|12"
)

# Process each animation
for animation_config in "${ANIMATIONS[@]}"; do
    # Skip comments and empty lines
    [[ "$animation_config" =~ ^#.*$ ]] && continue
    [[ -z "$animation_config" ]] && continue

    # Parse configuration using pipe separator
    IFS='|' read -r name start_time end_time width height offset_x offset_y fps <<< "$animation_config"

    # Construct crop parameters
    crop_params="$width:$height:$offset_x:$offset_y"

    echo ""
    echo "=========================================="
    echo "Processing: $name"
    echo "=========================================="
    echo "Time range: $start_time - $end_time"
    echo "Region: ${width}x${height} at ($offset_x, $offset_y)"
    echo "FPS: $fps"
    echo ""

    # Run pipeline
    ./scripts/pipeline.sh "$INPUT_VIDEO" "$start_time" "$end_time" "$name" "$crop_params" "$fps"
done

echo ""
echo "=========================================="
echo "All animations processed!"
echo "=========================================="

