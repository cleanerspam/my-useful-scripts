#  1) Wallpaper changer based on day

        Make a schedule on excel or anyother spreadsheet tool convert it to 1920*1080p PNG image and name the image 
        with each day example monday.img tuesday.img and so on..............
        Useful for setting daily schedule as wallpaper so you don't get distracted and follow timetable
        Windows Users should edit the .bat file and change the location of schedule folder on line8 to where they have stored images 
        On Linux only Plasma is supported and linux users should also change the location of schedule folder on lin8 to where they have stored images

        For Automatic Change on boot every day
        Windows User should use Task Scheduler to run this .bat file every time a user logins 
        Plasma User should directly add this .sh file to AutoStart Apps section in Plasma Settings

# 2) Google Drive File Downloader

        Useful for bulk downloading google files using v3 access token on linux using multiple urls 
        placed one in each line inside file_urls.txt file placed in same folder as the script

# 3) Merge /Replace Audio 

        Sometimes you have a video file which has 
        Case a) no audio inside it and you want to merge an external audio file to the video file in batch 
        Case b) video file contains audio but you are not happy with it and want to replace the internal video with an external audio in batch 

        This script is made assuming the video file is in .mp4 format and audio file is in .aac format and
        both files have same name that are to merged except the extension

        Requirements  are only that ffmpeg is installed , and bash is used
        Paste the file in folder which contains all the video and audo files and  
        make the  replaceaudio.sh file executable using `chmod +x replaceaudio.sh`
        then simply run the script with `./replaceaudio.sh`
        the output will be stored in output folder in same directory

# 4) Check Corrupt PDFs

        Many of us have folders filled with pdfs and you wish to comb through them and
        remove corrupted or damaged pdf , this script will simply use pdfinfo to check 
        All the PDFs in current directory and move them to corrupt/ subdirectory in current folder where script is 
        Script will try to install necessary dependencies on popular Linux distributions

# 5) Convert PNG to JPG with EXIF preservation

        This script converts all PNG files in a directory to JPG format while preserving EXIF data using exiftool.
        - It processes each `.png` file, skips files if a `.jpg` with the same base name already exists.
        - Uses ImageMagick's `convert` to convert PNG to JPG.
        - Copies EXIF tags from PNG to JPG using exiftool (if EXIF exists).
        - On successful conversion and EXIF copy, deletes the original PNG file.
        - Shows status messages for each file and at the end.
        - Requirements: `imagemagick` and `exiftool` must be installed.

        Usage: Place `convert-png-to-jpg.sh` in the directory with PNGs and run it with `bash convert-png-to-jpg.sh`.

# 6) Move Non-Face Photos Using AI Model (CPU or GPU)

        This script automatically sorts your images by moving all `.jpg`, `.jpeg`, and `.png` files that do not contain a human face into a `noface/` subdirectory.
        It uses the InsightFace AI library for face detection, and can utilize either your GPU (if available) or CPU for processing.

        - Automatically sets up a Python virtual environment and installs dependencies (`insightface`, `onnxruntime-gpu` or `onnxruntime`, `opencv-python-headless`, `tqdm`).
        - Scans all images in the current directory.
        - Moves images without faces detected to a `noface` folder.
        - Shows progress and error messages for each file.
        - At the end, offers to delete the created virtual environment to save space.

        Usage:
        - Place `facedetect_move.sh` in the folder with your images.
        - Make executable: `chmod +x facedetect_move.sh`
        - Run with: `./facedetect_move.sh`
        - GPU mode enabled by passing "1" as argument: `./facedetect_move.sh 1`
        - CPU-only mode (default): `./facedetect_move.sh`

