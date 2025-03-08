#!/bin/bash

# Function to handle cleanup on exit
cleanup() {
    echo -e "\nScript terminated. Exiting..."
    exit 0
}

# Trap SIGINT (Ctrl+C) signal
trap cleanup SIGINT

# Function to install poppler-utils based on the distribution
install_dependencies() {
    if ! command -v pdfinfo &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            echo "Detected Debian/Ubuntu. Installing poppler-utils..."
            sudo apt-get update && sudo apt-get install -y poppler-utils
        elif command -v dnf &> /dev/null; then
            echo "Detected Fedora. Installing poppler-utils..."
            sudo dnf install -y poppler-utils
        elif command -v yum &> /dev/null; then
            echo "Detected CentOS/RHEL. Installing poppler-utils..."
            sudo yum install -y poppler-utils
        elif command -v pacman &> /dev/null; then
            echo "Detected Arch Linux. Installing poppler-utils..."
            sudo pacman -Syu --noconfirm poppler
        else
            echo "Unsupported distribution. Please install poppler-utils manually."
            exit 1
        fi
    else
        echo "poppler-utils is already installed."
    fi
}

# Check for required arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <pdf_directory>"
    echo "Example: $0 /path/to/pdfs"
    exit 1
fi

# Directory containing PDF files
PDF_DIR="$1"
# Output file for corrupted PDF names
OUTPUT_FILE="corrupted_pdfs.txt"
# Directory to move corrupted files
CORRUPT_DIR="$PDF_DIR/corrupt"

# Install dependencies if not already installed
install_dependencies

# Create the corrupt directory if it doesn't exist
mkdir -p "$CORRUPT_DIR"

# Clear the output file
> "$OUTPUT_FILE"

# Initialize counters
total_files=0
checked_files=0
corrupted_files=0

# Count total PDF files
for pdf in "$PDF_DIR"/*.pdf; do
    if [ -f "$pdf" ]; then
        total_files=$((total_files + 1))
    fi
done

# Loop through PDF files in the directory
for pdf in "$PDF_DIR"/*.pdf; do
    if [ -f "$pdf" ]; then
        # Increment checked files counter
        checked_files=$((checked_files + 1))

        # Display the name of the file being checked
        echo "Checking file: $(basename "$pdf")"

        # Use pdfinfo to check for errors
        pdfinfo "$pdf" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "$pdf" >> "$OUTPUT_FILE"
            mv "$pdf" "$CORRUPT_DIR/"
            corrupted_files=$((corrupted_files + 1))
        else
            # Clear the line for non-error files
            echo -e "\rFile checked: $(basename "$pdf") - No errors found."
        fi

        # Display the current status
        echo "Total PDF files: $total_files | Checked: $checked_files | Corrupted: $corrupted_files"
    fi
done

# Final summary
echo "Processing complete."
echo "Total PDF files: $total_files"
echo "Checked for errors: $checked_files"
echo "Corrupted PDF files: $corrupted_files"
echo "Corrupted PDF files have been moved to $CORRUPT_DIR and listed in $OUTPUT_FILE"
