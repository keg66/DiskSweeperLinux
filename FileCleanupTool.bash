#!/bin/bash

# FileCleanupTool.bash - Large File Cleanup Tool for Linux
# A bash-based file cleanup utility for Ubuntu 22.04+ 
# Helps users find and remove large files to free up disk space

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.json"
DEFAULT_SIZE_THRESHOLD="100M"
FOUND_FILES=()
SELECTED_FILES=()

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage/help
show_help() {
    echo "大容量ファイル整理スクリプト for Linux"
    echo ""
    echo "使用方法:"
    echo "  ./FileCleanupTool.bash [オプション]"
    echo ""
    echo "オプション:"
    echo "  -h, --help     このヘルプメッセージを表示"
    echo "  -v, --version  バージョン情報を表示"
    echo ""
    echo "機能:"
    echo "  - 指定サイズ以上のファイルを検索"
    echo "  - 対話的なファイル選択"
    echo "  - 選択したファイルをごみ箱に移動"
    echo "  - 設定の自動保存"
}

# Function to show version
show_version() {
    echo "FileCleanupTool.bash version 1.0"
    echo "Large File Cleanup Tool for Ubuntu 22.04+"
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Check if jq is available for JSON parsing
        if command -v jq >/dev/null 2>&1; then
            LAST_FOLDER=$(jq -r '.last_folder // "'"$HOME"'"' "$CONFIG_FILE" 2>/dev/null || echo "$HOME")
            LAST_SIZE_THRESHOLD=$(jq -r '.last_size_threshold // "'"$DEFAULT_SIZE_THRESHOLD"'"' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_SIZE_THRESHOLD")
        else
            # Fallback: simple grep-based parsing
            LAST_FOLDER=$(grep -o '"last_folder"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*"last_folder"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "$HOME")
            LAST_SIZE_THRESHOLD=$(grep -o '"last_size_threshold"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*"last_size_threshold"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "$DEFAULT_SIZE_THRESHOLD")
        fi
    else
        LAST_FOLDER="$HOME"
        LAST_SIZE_THRESHOLD="$DEFAULT_SIZE_THRESHOLD"
    fi
}

# Function to save configuration
save_config() {
    local folder="$1"
    local size_threshold="$2"
    
    cat > "$CONFIG_FILE" <<EOF
{
    "last_folder": "$folder",
    "last_size_threshold": "$size_threshold",
    "created_at": "$(date -Iseconds)"
}
EOF
    
    print_colored "$GREEN" "Configuration saved: $CONFIG_FILE"
}

# Function to convert size to bytes for comparison
size_to_bytes() {
    local size="$1"
    local number=$(echo "$size" | sed 's/[^0-9.]//g')
    local unit=$(echo "$size" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')
    
    case "$unit" in
        "M"|"MB") echo "$number * 1024 * 1024" | bc -l | cut -d. -f1 ;;
        "G"|"GB") echo "$number * 1024 * 1024 * 1024" | bc -l | cut -d. -f1 ;;
        "K"|"KB") echo "$number * 1024" | bc -l | cut -d. -f1 ;;
        *) echo "$number" ;;
    esac
}

# Function to format file size for human-readable display
format_file_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        printf "%.1fGB" "$(echo "scale=1; $bytes / 1073741824" | bc -l)"
    elif (( bytes >= 1048576 )); then
        printf "%.1fMB" "$(echo "scale=1; $bytes / 1048576" | bc -l)"
    elif (( bytes >= 1024 )); then
        printf "%.1fKB" "$(echo "scale=1; $bytes / 1024" | bc -l)"
    else
        printf "%dB" "$bytes"
    fi
}

# Function to get user input for folder selection
get_target_folder() {
    while true; do
        echo "" >&2
        print_colored "$BLUE" "Please select target folder:" >&2
        echo "Previous selection: $LAST_FOLDER" >&2
        echo "" >&2
        echo "1) Use previous folder ($LAST_FOLDER)" >&2
        echo "2) Home directory ($HOME)" >&2
        echo "3) Enter custom path" >&2
        echo "4) Exit" >&2
        echo "" >&2
        if ! read -p "Choice [1-4]: " choice >&2; then
            print_colored "$YELLOW" "Exiting program." >&2
            exit 0
        fi
        
        case $choice in
            1)
                if [[ -d "$LAST_FOLDER" ]]; then
                    echo "$LAST_FOLDER"
                    return 0
                else
                    print_colored "$RED" "Error: Folder does not exist: $LAST_FOLDER" >&2
                fi
                ;;
            2)
                echo "$HOME"
                return 0
                ;;
            3)
                if ! read -p "Enter target folder path: " custom_path >&2; then
                    print_colored "$YELLOW" "Exiting program." >&2
                    exit 0
                fi
                if [[ -d "$custom_path" ]]; then
                    echo "$custom_path"
                    return 0
                else
                    print_colored "$RED" "Error: Folder does not exist: $custom_path" >&2
                fi
                ;;
            4)
                print_colored "$YELLOW" "Exiting program." >&2
                exit 0
                ;;
            *)
                print_colored "$RED" "Invalid choice. Please select 1-4." >&2
                ;;
        esac
    done
}

# Function to get size threshold from user
get_size_threshold() {
    while true; do
        echo "" >&2
        print_colored "$BLUE" "Please select file size threshold:" >&2
        echo "Previous selection: $LAST_SIZE_THRESHOLD" >&2
        echo "" >&2
        echo "1) 50MB or larger" >&2
        echo "2) 100MB or larger (recommended)" >&2
        echo "3) 500MB or larger" >&2
        echo "4) 1GB or larger" >&2
        echo "5) Enter custom size" >&2
        echo "6) Use previous threshold ($LAST_SIZE_THRESHOLD)" >&2
        echo "" >&2
        if ! read -p "Choice [1-6]: " choice >&2; then
            print_colored "$YELLOW" "Exiting program." >&2
            exit 0
        fi
        
        case $choice in
            1) echo "50M"; return 0 ;;
            2) echo "100M"; return 0 ;;
            3) echo "500M"; return 0 ;;
            4) echo "1G"; return 0 ;;
            5)
                if ! read -p "Enter custom size (e.g., 200M, 2G): " custom_size >&2; then
                    print_colored "$YELLOW" "Exiting program." >&2
                    exit 0
                fi
                if [[ "$custom_size" =~ ^[0-9]+[MmGgKk]?$ ]]; then
                    echo "$custom_size"
                    return 0
                else
                    print_colored "$RED" "Invalid size format. Examples: 200M, 2G" >&2
                fi
                ;;
            6) echo "$LAST_SIZE_THRESHOLD"; return 0 ;;
            *)
                print_colored "$RED" "Invalid choice. Please select 1-6." >&2
                ;;
        esac
    done
}

# Function to search for large files
search_files() {
    local target_folder="$1"
    local size_threshold="$2"
    local temp_file
    temp_file=$(mktemp)
    
    print_colored "$YELLOW" "Starting file search..."
    print_colored "$BLUE" "Target folder: $target_folder"
    print_colored "$BLUE" "Size threshold: $size_threshold"
    echo ""
    
    # Reset found files array
    FOUND_FILES=()
    
    # Show progress message and search directly
    printf "Searching for files..."
    find "$target_folder" -type f -size +"$size_threshold" -exec ls -l {} \; 2>/dev/null | \
    awk '{print $5 "|" $9 "|" $6 " " $7 " " $8}' | \
    sed 's/ < \/dev\/null | /|/' | \
    sort -nr > "$temp_file"
    printf "\rSearch complete!    \n"
    
    # Read results into array using mapfile
    if [[ -s "$temp_file" ]]; then
        mapfile -t FOUND_FILES < "$temp_file"
    else
        FOUND_FILES=()
    fi
    
    rm -f "$temp_file"
    
    print_colored "$GREEN" "Search results: ${#FOUND_FILES[@]} files found"
    echo ""
}

# Function to display found files
display_files() {
    if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
        print_colored "$YELLOW" "No files found matching the criteria."
        return 1
    fi
    
    echo "Found files list:"
    echo "----------------------------------------"
    printf "%-3s %-10s %-19s %s\n" "No" "Size" "Modified" "File Path"
    echo "----------------------------------------"
    
    local i=1
    for file_info in "${FOUND_FILES[@]}"; do
        IFS='|' read -r size filepath modtime <<< "$file_info"
        local human_size
        human_size=$(format_file_size "$size")
        printf "%-3d %-10s %-19s %s\n" "$i" "$human_size" "$modtime" "$filepath"
        ((i++))
    done
    echo ""
}

# Function for file selection interface
select_files() {
    if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
        return 1
    fi
    
    # Initialize selection array
    SELECTED_FILES=()
    local selected_indices=()
    
    while true; do
        echo "" >&2
        print_colored "$BLUE" "File selection menu:" >&2
        echo "1) Select/deselect individual files" >&2
        echo "2) Select all" >&2
        echo "3) Deselect all" >&2
        echo "4) Show selected files" >&2
        echo "5) Delete selected files" >&2
        echo "6) Return to main menu" >&2
        echo "" >&2
        
        if [[ ${#selected_indices[@]} -gt 0 ]]; then
            print_colored "$GREEN" "Currently ${#selected_indices[@]} files are selected" >&2
        fi
        
        if ! read -p "Choice [1-6]: " choice >&2; then
            print_colored "$YELLOW" "Exiting program." >&2
            exit 0
        fi
        
        case $choice in
            1)
                echo "" >&2
                if ! read -p "Enter file number (1-${#FOUND_FILES[@]}): " file_num >&2; then
                    print_colored "$YELLOW" "Exiting program." >&2
                    exit 0
                fi
                if [[ "$file_num" =~ ^[0-9]+$ ]] && (( file_num >= 1 && file_num <= ${#FOUND_FILES[@]} )); then
                    # Toggle selection
                    local index=$((file_num - 1))
                    if [[ " ${selected_indices[*]} " =~ " ${index} " ]]; then
                        # Remove from selection
                        selected_indices=(${selected_indices[@]/$index})
                        print_colored "$YELLOW" "Deselected file $file_num" >&2
                    else
                        # Add to selection
                        selected_indices+=("$index")
                        print_colored "$GREEN" "Selected file $file_num" >&2
                    fi
                else
                    print_colored "$RED" "Invalid file number" >&2
                fi
                ;;
            2)
                selected_indices=($(seq 0 $((${#FOUND_FILES[@]} - 1))))
                print_colored "$GREEN" "Selected all files (${#FOUND_FILES[@]} files)" >&2
                ;;
            3)
                selected_indices=()
                print_colored "$YELLOW" "Deselected all files" >&2
                ;;
            4)
                if [[ ${#selected_indices[@]} -eq 0 ]]; then
                    print_colored "$YELLOW" "No files are selected" >&2
                else
                    echo "" >&2
                    echo "Selected files:" >&2
                    echo "----------------------------------------" >&2
                    local total_size=0
                    for index in "${selected_indices[@]}"; do
                        local file_info="${FOUND_FILES[$index]}"
                        IFS='|' read -r size filepath modtime <<< "$file_info"
                        local human_size
                        human_size=$(format_file_size "$size")
                        printf "%-10s %-19s %s\n" "$human_size" "$modtime" "$filepath" >&2
                        total_size=$((total_size + size))
                    done
                    echo "----------------------------------------" >&2
                    local total_human_size
                    total_human_size=$(format_file_size "$total_size")
                    print_colored "$GREEN" "Total size: $total_human_size" >&2
                fi
                ;;
            5)
                if [[ ${#selected_indices[@]} -eq 0 ]]; then
                    print_colored "$RED" "No files selected for deletion" >&2
                else
                    delete_selected_files "${selected_indices[@]}"
                    return 0
                fi
                ;;
            6)
                return 0
                ;;
            *)
                print_colored "$RED" "Invalid choice. Please select 1-6." >&2
                ;;
        esac
    done
}

# Function to delete selected files
delete_selected_files() {
    local indices=("$@")
    local total_size=0
    
    # Calculate total size and prepare file list
    SELECTED_FILES=()
    for index in "${indices[@]}"; do
        local file_info="${FOUND_FILES[$index]}"
        IFS='|' read -r size filepath modtime <<< "$file_info"
        SELECTED_FILES+=("$filepath")
        total_size=$((total_size + size))
    done
    
    # Show confirmation
    echo "" >&2
    print_colored "$YELLOW" "Delete confirmation" >&2
    echo "----------------------------------------" >&2
    print_colored "$RED" "The following ${#SELECTED_FILES[@]} files will be moved to trash:" >&2
    
    for filepath in "${SELECTED_FILES[@]}"; do
        echo "  $filepath" >&2
    done
    
    local total_human_size
    total_human_size=$(format_file_size "$total_size")
    echo "----------------------------------------" >&2
    print_colored "$BLUE" "Total deletion size: $total_human_size" >&2
    echo "" >&2
    
    if ! read -p "Are you sure you want to delete? (y/N): " confirm >&2; then
        print_colored "$YELLOW" "Delete operation cancelled." >&2
        return 0
    fi
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local success_count=0
        local error_count=0
        
        print_colored "$YELLOW" "Moving files to trash..." >&2
        
        for filepath in "${SELECTED_FILES[@]}"; do
            if command -v gio >/dev/null 2>&1; then
                if gio trash "$filepath" 2>/dev/null; then
                    ((success_count++))
                    print_colored "$GREEN" "Move completed: $(basename "$filepath")" >&2
                else
                    ((error_count++))
                    print_colored "$RED" "Move failed: $filepath" >&2
                fi
            else
                # Fallback: move to a trash directory
                local trash_dir="$HOME/.local/share/Trash/files"
                mkdir -p "$trash_dir"
                if mv "$filepath" "$trash_dir/" 2>/dev/null; then
                    ((success_count++))
                    print_colored "$GREEN" "Move completed: $(basename "$filepath")" >&2
                else
                    ((error_count++))
                    print_colored "$RED" "Move failed: $filepath" >&2
                fi
            fi
        done
        
        echo "" >&2
        print_colored "$GREEN" "Delete operation completed!" >&2
        print_colored "$BLUE" "Success: $success_count files" >&2
        if [[ $error_count -gt 0 ]]; then
            print_colored "$RED" "Failed: $error_count files" >&2
        fi
    else
        print_colored "$YELLOW" "Delete operation cancelled." >&2
    fi
}

# Main function
main() {
    # Check for help or version flags
    for arg in "$@"; do
        case $arg in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
        esac
    done
    
    # Check for required commands
    local missing_commands=()
    for cmd in find bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_colored "$RED" "Error: Required commands not found: ${missing_commands[*]}"
        print_colored "$BLUE" "Install with: sudo apt update && sudo apt install findutils bc"
        exit 1
    fi
    
    # Load configuration
    load_config
    
    # Main program loop
    print_colored "$GREEN" "Large File Cleanup Script for Linux"
    print_colored "$BLUE" "Disk Cleanup Tool for Ubuntu 22.04+"
    echo ""
    
    while true; do
        # Get target folder
        local target_folder
        target_folder=$(get_target_folder)
        
        # Get size threshold
        local size_threshold
        size_threshold=$(get_size_threshold)
        
        # Save configuration
        save_config "$target_folder" "$size_threshold"
        
        # Search for files
        search_files "$target_folder" "$size_threshold"
        
        # Display results
        if display_files; then
            # File selection and deletion
            select_files
        fi
        
        # Ask if user wants to continue
        echo ""
        if ! read -p "Would you like to perform another search? (y/N): " continue_search; then
            break
        fi
        if [[ ! "$continue_search" =~ ^[Yy]$ ]]; then
            break
        fi
    done
    
    print_colored "$GREEN" "Exiting program. Thank you for using this tool!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi