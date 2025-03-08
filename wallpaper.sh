#!/bin/bash

# Get the current day of the week (0-6, 0=Sunday)
day_of_week=$(date +%u)  # 1 (Monday) to 7 (Sunday)
# Adjust for zero-based indexing (0 for Sunday)
day_of_week=$((day_of_week % 7))

# Define the wallpaper path
wallpaper_dir="/home/a/Pictures/schedule"
wallpaper_files=("sunday.png" "monday.png" "tuesday.png" "wednesday.png" "thursday.png" "friday.png" "saturday.png")

# Set the wallpaper
plasma-apply-wallpaperimage "$wallpaper_dir/${wallpaper_files[day_of_week]}"
