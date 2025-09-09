#!/bin/bash

# Script to rename ebooks to "Author - Title.extension" or "Title.extension" format
# Requires Calibre CLI tools to be installed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TITLE_ONLY=false
RECURSIVE=false
PROCESS_DIR="."

# Function to show help
show_help() {
    echo "Usage: $0 [options] [directory]"
    echo ""
    echo "Options:"
    echo "  -t, --title-only    Rename to 'Title.ext' format instead of 'Author - Title.ext'"
    echo "  -r, --recursive     Process subdirectories recursively"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Rename files in current directory to 'Author - Title.ext'"
    echo "  $0 /path/to/books      # Rename files in specified directory to 'Author - Title.ext'"
    echo "  $0 -t                  # Rename files in current directory to 'Title.ext'"
    echo "  $0 -r                  # Rename files recursively in current directory"
    echo "  $0 -t -r               # Rename files recursively to 'Title.ext' format"
    echo "  $0 -t -r /path/to/books # Rename files recursively in specified directory to 'Title.ext'"
}

# Function to clean filename (remove invalid characters)
clean_filename() {
    echo "$1" | sed 's/[<>:"/\\|?*]//g' | sed 's/  / /g' | sed 's/^ *//g' | sed 's/ *$//g'
}

# Function to process a single epub file
process_epub() {
    local epub_file="$1"
    local base_name="${epub_file%.*}"
    local dir_name=$(dirname "$epub_file")
    
    echo -e "${YELLOW}Processing: $epub_file${NC}"
    
    # Extract metadata using ebook-meta
    local metadata=$(ebook-meta "$epub_file" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not read metadata from $epub_file${NC}"
        return 1
    fi
    
    # Extract author and title
    local author=$(echo "$metadata" | grep "^Author(s)" | sed 's/^Author(s)[[:space:]]*:[[:space:]]*//' | head -1)
    local title=$(echo "$metadata" | grep "^Title" | sed 's/^Title[[:space:]]*:[[:space:]]*//' | head -1)
    
    # Check if we got title (author is optional now)
    if [ -z "$title" ]; then
        echo -e "${RED}Warning: Could not extract title from $epub_file${NC}"
        echo "Title: '$title'"
        return 1
    fi
    
    # Clean the title for filename use (and author if using it)
    title=$(clean_filename "$title")
    
    # Create new filename based on mode
    local new_base
    if [ "$TITLE_ONLY" = "true" ]; then
        new_base="$title"
        echo "Title: $title"
        echo "New name: $new_base"
    else
        if [ -z "$author" ]; then
            echo -e "${RED}Warning: Could not extract author from $epub_file${NC}"
            echo "Author: '$author'"
            return 1
        fi
        author=$(clean_filename "$author")
        new_base="${author} - ${title}"
        echo "Author: $author"
        echo "Title: $title"
        echo "New name: $new_base"
    fi
    
    local new_epub="${dir_name}/${new_base}.epub"
    local new_pdf="${dir_name}/${new_base}.pdf"
    
    # Check if files with new names already exist
    if [ "$epub_file" != "$new_epub" ]; then
        if [ -f "$new_epub" ]; then
            echo -e "${RED}Warning: $new_epub already exists, skipping epub rename${NC}"
        else
            # Rename the epub file
            mv "$epub_file" "$new_epub"
            echo -e "${GREEN}✓ Renamed epub: $new_epub${NC}"
        fi
    else
        echo "✓ EPUB already has correct name"
    fi
    
    # Check for corresponding PDF file and rename it too
    local old_pdf="${base_name}.pdf"
    if [ -f "$old_pdf" ]; then
        if [ -f "$new_pdf" ]; then
            echo -e "${RED}Warning: $new_pdf already exists, skipping pdf rename${NC}"
        else
            mv "$old_pdf" "$new_pdf"
            echo -e "${GREEN}✓ Renamed PDF: $new_pdf${NC}"
        fi
    fi
    
    echo ""
}

# Simple argument processing
i=1
while [ $i -le $# ]; do
    arg=${!i}
    case $arg in
        -t|--title-only)
            TITLE_ONLY=true
            ;;
        -r|--recursive)
            RECURSIVE=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $arg${NC}"
            exit 1
            ;;
        *)
            PROCESS_DIR="$arg"
            ;;
    esac
    i=$((i+1))
done

# Main script
echo "EPUB/PDF Renaming Script"
echo "======================="
echo ""

# Check if ebook-meta is available
if ! command -v ebook-meta &> /dev/null; then
    echo -e "${RED}Error: ebook-meta command not found. Please install Calibre CLI tools.${NC}"
    echo "On most systems: sudo apt install calibre (Linux) or brew install calibre (Mac)"
    exit 1
fi

# Validate directory
if [ ! -d "$PROCESS_DIR" ]; then
    echo -e "${RED}Error: Directory '$PROCESS_DIR' does not exist${NC}"
    exit 1
fi

echo "Processing directory: $PROCESS_DIR"
if [ "$TITLE_ONLY" = "true" ]; then
    echo "Mode: Title only (Title.ext)"
else
    echo "Mode: Author and Title (Author - Title.ext)"
fi
if [ "$RECURSIVE" = "true" ]; then
    echo "Recursive: Yes (processing subdirectories)"
else
    echo "Recursive: No (current directory only)"
fi
echo ""

# Find all epub files and process them
if [ "$RECURSIVE" = "true" ]; then
    find "$PROCESS_DIR" -name "*.epub" -type f | while read -r epub_file; do
        process_epub "$epub_file"
    done
else
    find "$PROCESS_DIR" -maxdepth 1 -name "*.epub" -type f | while read -r epub_file; do
        process_epub "$epub_file"
    done
fi

echo -e "${GREEN}Processing complete!${NC}"