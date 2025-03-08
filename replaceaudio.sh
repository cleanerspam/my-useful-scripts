#!/bin/bash
mkdir -p output
FRAMES=$(ffprobe -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 -v quiet -i "$Fvideo_name")

for video_name in *.mp4

do

    audio_name="${video_name%.*}.aac"
    echo Merging $video_name with $audio_name

    echo "                                   "
    ffmpeg  -v error -stats -i $video_name -i $audio_name -c copy -map 0:v:0 -map 1:a:0 "output/$video_name"
    echo "                                   "
    echo "  Succesfull ✅ , file saved as   output/$video_name         "
    echo "                                   "
    echo "                                   "
done
 
