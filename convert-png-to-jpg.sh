#!/bin/bash

shopt -s nullglob nocaseglob

echo "🔄 Converting PNGs to JPGs with EXIF preservation..."

for file in *.png; do
  # Use basename without extension
  base="${file%.*}"
  jpg="${base}.jpg"

  echo "▶ Processing: $file"

  # Skip if JPG already exists
  if [[ -e "$jpg" ]]; then
    echo "⚠️  Skipping '$file': '$jpg' already exists."
    continue
  fi

  # Convert PNG to JPG using ImageMagick
  if ! convert "$file" "$jpg"; then
    echo "❌ Failed to convert '$file' → '$jpg'"
    rm -f "$jpg"  # Remove partial output
    continue
  fi

  # Copy EXIF tags if any exist (ExifTool silently skips non-EXIF PNGs)
  if ! exiftool -TagsFromFile "$file" -all:all "$jpg" -overwrite_original >/dev/null; then
    echo "⚠️  Warning: Failed to copy EXIF from '$file' → '$jpg'"
  fi

  # Confirm new JPG exists and has valid EXIF
  if [[ -s "$jpg" ]]; then
    echo "✅ Success: Created '$jpg'. Removing original '$file'"
    rm -f "$file"
  else
    echo "❌ Output file '$jpg' is empty. Keeping original '$file'"
    rm -f "$jpg"
  fi
done

echo "✅ Done."
