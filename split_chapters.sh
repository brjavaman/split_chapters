#!/bin/bash

# Check if video file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <video_file.mp4>"
  exit 1
fi

# Input Parameters
VIDEO_FILE="$1"
CHAPTERS_FILE="${VIDEO_FILE%.mp4}.txt"  # Chapters file is the same name but with .txt extension
OUTPUT_FOLDER="output_chapters"
VIDEO_BASE="$(basename "$VIDEO_FILE" .mp4)"

# Check if chapters file exists
if [ ! -f "$CHAPTERS_FILE" ]; then
  echo "Error: Chapters file '$CHAPTERS_FILE' not found!"
  exit 1
fi

# Create the output folder if it doesn't exist
mkdir -p "$OUTPUT_FOLDER"

# Function to convert time (MM:SS) or (HH:MM:SS) to seconds
convert_to_seconds() {
  local TIME="$1"
  TIME=${TIME// /}  # Remove all spaces
  IFS=: read -r -a parts <<< "$TIME"
  if [ ${#parts[@]} -eq 2 ]; then
    echo $(( 10#${parts[0]} * 60 + 10#${parts[1]} ))
  elif [ ${#parts[@]} -eq 3 ]; then
    echo $(( 10#${parts[0]} * 3600 + 10#${parts[1]} * 60 + 10#${parts[2]} ))
  else
    echo 0
  fi
}

# Function to normalize time format to HH:MM:SS
normalize_time() {
  local TIME="$1"
  TIME=${TIME// /}  # Remove all spaces
  IFS=: read -r -a parts <<< "$TIME"
  if [ ${#parts[@]} -eq 2 ]; then
    printf "00:%02d:%02d" "$((10#${parts[0]}))" "$((10#${parts[1]}))"
  elif [ ${#parts[@]} -eq 3 ]; then
    printf "%02d:%02d:%02d" "$((10#${parts[0]}))" "$((10#${parts[1]}))" "$((10#${parts[2]}))"
  else
    echo "00:00:00"
  fi
}

# Function to clean titles (remove accents, quotes, colons, commas, and special characters)
clean_title() {
  echo "$1" | iconv -f UTF-8 -t ASCII//TRANSLIT | tr -d '"',':'',' | tr ' ' '_' | tr -cd '[:alnum:]_'
}

# Read the chapters file and process each line
PREV_TIME_SEC=0
PREV_NORMALIZED_TIME="00:00:00"
PREV_TITLE=""
FIRST_LINE=true

while IFS= read -r line; do
  TIME=$(echo "$line" | awk -F' - ' '{print $1}' | xargs)      # Extract time (everything before ' - ')
  TITLE=$(echo "$line" | awk -F' - ' '{print $2}' | xargs)     # Extract title (everything after ' - ')

  # Normalize and convert time
  NORMALIZED_TIME=$(normalize_time "$TIME")
  TIME_SEC=$(convert_to_seconds "$NORMALIZED_TIME")

  # Log the parsed values
  echo "==== Parsed Line: '$line'"
  echo "==== Parsed Time: '$TIME' | Normalized Time: '$NORMALIZED_TIME' | Time in Seconds: $TIME_SEC | Title: '$TITLE'"

  # Skip invalid or empty timestamps
  #if [[ -z "$TITLE" || "$TIME_SEC" -le "$PREV_TIME_SEC" ]]; then
  #  echo "===== Warning: Skipping invalid or out-of-order line: '$line'"
  #  continue
  #fi

  # Skip first line for duration calculation
  if [ "$FIRST_LINE" = true ]; then
    FIRST_LINE=false
  else
    # Calculate the duration for the previous chapter
    DURATION=$(( TIME_SEC - PREV_TIME_SEC ))
    CLEAN_TITLE=$(clean_title "$PREV_TITLE")
    OUTPUT_FILE="${OUTPUT_FOLDER}/${VIDEO_BASE}_${PREV_NORMALIZED_TIME//:/}_${CLEAN_TITLE}.mp4"

    echo "==== Extracting '$PREV_TITLE' to '$OUTPUT_FILE' (Duration: $DURATION seconds)..."
    ffmpeg -nostdin -hide_banner -loglevel error -stats -i "$VIDEO_FILE" -ss "$PREV_TIME_SEC" -t "$DURATION" -c:v libx264 -preset ultrafast -c:a copy "$OUTPUT_FILE"
  fi

  # Store current values for next iteration
  PREV_TITLE="$TITLE"
  PREV_TIME_SEC="$TIME_SEC"
  PREV_NORMALIZED_TIME="$NORMALIZED_TIME"

done < "$CHAPTERS_FILE"

# Add the last chapter (up to the end of the video)
if [[ -n "$PREV_TITLE" ]]; then
  CLEAN_TITLE=$(clean_title "$PREV_TITLE")
  OUTPUT_FILE="${OUTPUT_FOLDER}/${VIDEO_BASE}_${PREV_NORMALIZED_TIME//:/}_${CLEAN_TITLE}.mp4"

  echo "==== Extracting last chapter '$PREV_TITLE' to '$OUTPUT_FILE'..."
  ffmpeg -nostdin -hide_banner -loglevel error -stats -i "$VIDEO_FILE" -ss "$PREV_TIME_SEC" -c:v libx264 -preset ultrafast -c:a copy "$OUTPUT_FILE"

fi

echo "===== Chapters successfully extracted!"

