#!/bin/bash

# MP4 Processing Pipeline with Region Cropping
# Usage: ./process_video.sh input.mp4 start_time end_time [output_name] [crop_params]

set -e  # Exit on error

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed"
    exit 1
fi

# Parse arguments
INPUT_FILE="$1"
START_TIME="$2"
END_TIME="$3"
OUTPUT_NAME="${4:-output}"
CROP_PARAMS="$5"  # Format: "width:height:x:y" or empty for no crop

# Validate input
if [ -z "$INPUT_FILE" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
    echo "Usage: $0 <input.mp4> <start_time> <end_time> [output_name] [crop_params]"
    echo ""
    echo "Examples:"
    echo "  $0 video.mp4 00:00:10 00:00:15 my_animation"
    echo "  $0 video.mp4 00:00:10 00:00:15 my_animation \"800:600:100:50\""
    echo "  $0 video.mp4 5 10 output \"iw/2:ih/2:iw/4:ih/4\""
    echo ""
    echo "Time format: HH:MM:SS or seconds"
    echo "Crop format: width:height:x:y"
    echo "  - width/height: crop dimensions"
    echo "  - x/y: top-left position"
    echo "  - Can use expressions like 'iw/2' (half input width), 'ih/2' (half input height)"
    echo ""
    echo "Common crop examples:"
    echo "  Center square crop: \"iw:iw:(iw-iw)/2:(ih-iw)/2\""
    echo "  Top-left 1920x1080: \"1920:1080:0:0\""
    echo "  Center 50%: \"iw/2:ih/2:iw/4:ih/4\""
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Setup output directories
WORK_DIR="./processing_${OUTPUT_NAME}"
FRAMES_DIR="${WORK_DIR}/frames"
TRUNCATED_FILE="${WORK_DIR}/${OUTPUT_NAME}_truncated.mp4"
SPRITESHEET="${WORK_DIR}/${OUTPUT_NAME}_spritesheet.png"

echo "Creating working directory..."
mkdir -p "$FRAMES_DIR"

# Build video filter chain
VIDEO_FILTERS=""

# Add crop filter if specified
if [ -n "$CROP_PARAMS" ]; then
    VIDEO_FILTERS="crop=${CROP_PARAMS}"
    echo "Crop parameters: $CROP_PARAMS"
fi

# Step 1: Truncate video (and optionally crop)
echo "Step 1: Processing video from $START_TIME to $END_TIME..."

if [ -n "$VIDEO_FILTERS" ]; then
    # With crop: need to re-encode
    ffmpeg -i "$INPUT_FILE" \
        -ss "$START_TIME" \
        -to "$END_TIME" \
        -vf "$VIDEO_FILTERS" \
        -c:v libx264 \
        -preset fast \
        -crf 18 \
        -c:a copy \
        "$TRUNCATED_FILE" \
        -y
    echo "✓ Video truncated and cropped"
else
    # Without crop: fast copy
    ffmpeg -i "$INPUT_FILE" \
        -ss "$START_TIME" \
        -to "$END_TIME" \
        -c copy \
        "$TRUNCATED_FILE" \
        -y
    echo "✓ Video truncated"
fi

echo "✓ Processed video saved to: $TRUNCATED_FILE"

# Step 2: Extract frames as 256x256 PNG files
echo "Step 2: Extracting frames as 256x256 PNG images..."
ffmpeg -i "$TRUNCATED_FILE" \
    -vf "scale=256:256:force_original_aspect_ratio=decrease,pad=256:256:(ow-iw)/2:(oh-ih)/2" \
    "${FRAMES_DIR}/frame_%04d.png" \
    -y

FRAME_COUNT=$(ls -1 "${FRAMES_DIR}"/*.png 2>/dev/null | wc -l)
echo "✓ Extracted $FRAME_COUNT frames to: $FRAMES_DIR"

if [ "$FRAME_COUNT" -eq 0 ]; then
    echo "Error: No frames were extracted"
    exit 1
fi

# Step 3: Create spritesheet (2048x2048)
echo "Step 3: Creating 2048x2048 spritesheet..."

# Calculate grid dimensions
# 2048 / 256 = 8, so we can fit 8x8 = 64 frames per sheet
FRAMES_PER_ROW=8
FRAMES_PER_COL=8
MAX_FRAMES=$((FRAMES_PER_ROW * FRAMES_PER_COL))

if [ "$FRAME_COUNT" -gt "$MAX_FRAMES" ]; then
    echo "Warning: $FRAME_COUNT frames exceed $MAX_FRAMES maximum. Only first $MAX_FRAMES will be used."
    echo "Consider increasing spritesheet size or reducing frame count."
fi

# Create spritesheet using ffmpeg tile filter
ffmpeg -i "${FRAMES_DIR}/frame_%04d.png" \
    -frames:v $MAX_FRAMES \
    -filter_complex "tile=${FRAMES_PER_ROW}x${FRAMES_PER_COL}" \
    "$SPRITESHEET" \
    -y

echo "✓ Spritesheet created: $SPRITESHEET"

# Summary
echo ""
echo "=========================================="
echo "Processing complete!"
echo "=========================================="
echo "Working directory: $WORK_DIR"
echo "Truncated video:   $TRUNCATED_FILE"
echo "Frames directory:  $FRAMES_DIR"
echo "Spritesheet:       $SPRITESHEET"
echo ""
echo "Frames processed:  $FRAME_COUNT"
echo "Spritesheet grid:  ${FRAMES_PER_ROW}x${FRAMES_PER_COL} (${MAX_FRAMES} frames max)"
if [ -n "$CROP_PARAMS" ]; then
    echo "Crop applied:      $CROP_PARAMS"
fi
echo "=========================================="

