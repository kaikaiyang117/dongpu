#!/bin/sh
set -eu

tool_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
harmony_dir=$(dirname "$tool_dir")
project_dir=$(dirname "$harmony_dir")
source_dir="$project_dir/assets/vendor/exercises-dataset/videos"
output_dir="$harmony_dir/entry/src/main/resources/rawfile/exercise_videos"

mkdir -p "$output_dir"

find "$source_dir" -type f -name '*.gif' -print0 | \
  xargs -0 -n 1 -P "${EXERCISE_MEDIA_JOBS:-6}" sh -c '
    source_file=$2
    output_file="$1/$(basename "${source_file%.gif}").mp4"
    if [ -s "$output_file" ]; then exit 0; fi
    ffmpeg -v error -i "$source_file" \
      -vf "minterpolate=fps=12:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1,scale=360:360:flags=lanczos,pad=480:360:60:0:color=white,format=yuv420p" \
      -an -c:v libx264 -profile:v baseline -level 3.0 -preset veryfast -crf 25 -movflags +faststart "$output_file"
  ' sh "$output_dir"

count=$(find "$output_dir" -type f -name '*.mp4' | wc -l | tr -d ' ')
echo "Generated $count exercise videos."
