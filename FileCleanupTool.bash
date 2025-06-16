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
    echo "Ubuntu 22.04+ 用大容量ファイル整理ツール"
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
    
    print_colored "$GREEN" "設定を保存しました: $CONFIG_FILE"
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
        echo ""
        print_colored "$BLUE" "検索対象フォルダを選択してください:"
        echo "前回の選択: $LAST_FOLDER"
        echo ""
        echo "1) 前回と同じフォルダを使用 ($LAST_FOLDER)"
        echo "2) ホームディレクトリ ($HOME)"
        echo "3) カスタムパスを入力"
        echo "4) 終了"
        echo ""
        read -p "選択 [1-4]: " choice
        
        case $choice in
            1)
                if [[ -d "$LAST_FOLDER" ]]; then
                    echo "$LAST_FOLDER"
                    return 0
                else
                    print_colored "$RED" "エラー: フォルダが存在しません: $LAST_FOLDER"
                fi
                ;;
            2)
                echo "$HOME"
                return 0
                ;;
            3)
                read -p "検索対象フォルダのパスを入力: " custom_path
                if [[ -d "$custom_path" ]]; then
                    echo "$custom_path"
                    return 0
                else
                    print_colored "$RED" "エラー: フォルダが存在しません: $custom_path"
                fi
                ;;
            4)
                print_colored "$YELLOW" "プログラムを終了します。"
                exit 0
                ;;
            *)
                print_colored "$RED" "無効な選択です。1-4を選んでください。"
                ;;
        esac
    done
}

# Function to get size threshold from user
get_size_threshold() {
    while true; do
        echo ""
        print_colored "$BLUE" "検索するファイルサイズの閾値を選択してください:"
        echo "前回の選択: $LAST_SIZE_THRESHOLD"
        echo ""
        echo "1) 50MB以上"
        echo "2) 100MB以上 (推奨)"
        echo "3) 500MB以上"
        echo "4) 1GB以上"
        echo "5) カスタムサイズを入力"
        echo "6) 前回と同じ閾値を使用 ($LAST_SIZE_THRESHOLD)"
        echo ""
        read -p "選択 [1-6]: " choice
        
        case $choice in
            1) echo "50M"; return 0 ;;
            2) echo "100M"; return 0 ;;
            3) echo "500M"; return 0 ;;
            4) echo "1G"; return 0 ;;
            5)
                read -p "カスタムサイズを入力 (例: 200M, 2G): " custom_size
                if [[ "$custom_size" =~ ^[0-9]+[MmGgKk]?$ ]]; then
                    echo "$custom_size"
                    return 0
                else
                    print_colored "$RED" "無効なサイズ形式です。例: 200M, 2G"
                fi
                ;;
            6) echo "$LAST_SIZE_THRESHOLD"; return 0 ;;
            *)
                print_colored "$RED" "無効な選択です。1-6を選んでください。"
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
    
    print_colored "$YELLOW" "ファイル検索を開始します..."
    print_colored "$BLUE" "対象フォルダ: $target_folder"
    print_colored "$BLUE" "サイズ閾値: $size_threshold"
    echo ""
    
    # Reset found files array
    FOUND_FILES=()
    
    # Show progress during search
    local search_pid
    {
        find "$target_folder" -type f -size +"$size_threshold" -printf "%s|%p|%TY-%Tm-%Td %TH:%TM\n" 2>/dev/null | \
        sort -nr > "$temp_file"
    } &
    search_pid=$!
    
    # Show progress indicator
    local count=0
    while kill -0 $search_pid 2>/dev/null; do
        case $((count % 4)) in
            0) printf "\r検索中 |   " ;;
            1) printf "\r検索中 /   " ;;
            2) printf "\r検索中 -   " ;;
            3) printf "\r検索中 \\   " ;;
        esac
        ((count++))
        sleep 0.1
    done
    wait $search_pid
    printf "\r検索完了!    \n"
    
    # Read results into array
    local line_count=0
    while IFS='|' read -r size filepath modtime; do
        if [[ -n "$size" && -n "$filepath" ]]; then
            FOUND_FILES+=("$size|$filepath|$modtime")
            ((line_count++))
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    print_colored "$GREEN" "検索結果: ${#FOUND_FILES[@]} 個のファイルが見つかりました"
    echo ""
}

# Function to display found files
display_files() {
    if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
        print_colored "$YELLOW" "条件に合うファイルが見つかりませんでした。"
        return 1
    fi
    
    echo "見つかったファイル一覧:"
    echo "----------------------------------------"
    printf "%-3s %-10s %-19s %s\n" "No" "サイズ" "更新日時" "ファイルパス"
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
        echo ""
        print_colored "$BLUE" "ファイル選択メニュー:"
        echo "1) 個別ファイル選択/選択解除"
        echo "2) 全選択"
        echo "3) 全解除"
        echo "4) 選択したファイルを表示"
        echo "5) 選択したファイルを削除実行"
        echo "6) メインメニューに戻る"
        echo ""
        
        if [[ ${#selected_indices[@]} -gt 0 ]]; then
            print_colored "$GREEN" "現在 ${#selected_indices[@]} 個のファイルが選択されています"
        fi
        
        read -p "選択 [1-6]: " choice
        
        case $choice in
            1)
                echo ""
                read -p "ファイル番号を入力 (1-${#FOUND_FILES[@]}): " file_num
                if [[ "$file_num" =~ ^[0-9]+$ ]] && (( file_num >= 1 && file_num <= ${#FOUND_FILES[@]} )); then
                    # Toggle selection
                    local index=$((file_num - 1))
                    if [[ " ${selected_indices[*]} " =~ " ${index} " ]]; then
                        # Remove from selection
                        selected_indices=(${selected_indices[@]/$index})
                        print_colored "$YELLOW" "ファイル $file_num の選択を解除しました"
                    else
                        # Add to selection
                        selected_indices+=("$index")
                        print_colored "$GREEN" "ファイル $file_num を選択しました"
                    fi
                else
                    print_colored "$RED" "無効なファイル番号です"
                fi
                ;;
            2)
                selected_indices=($(seq 0 $((${#FOUND_FILES[@]} - 1))))
                print_colored "$GREEN" "全ファイルを選択しました (${#FOUND_FILES[@]} 個)"
                ;;
            3)
                selected_indices=()
                print_colored "$YELLOW" "全選択を解除しました"
                ;;
            4)
                if [[ ${#selected_indices[@]} -eq 0 ]]; then
                    print_colored "$YELLOW" "選択されたファイルはありません"
                else
                    echo ""
                    echo "選択されたファイル:"
                    echo "----------------------------------------"
                    local total_size=0
                    for index in "${selected_indices[@]}"; do
                        local file_info="${FOUND_FILES[$index]}"
                        IFS='|' read -r size filepath modtime <<< "$file_info"
                        local human_size
                        human_size=$(format_file_size "$size")
                        printf "%-10s %-19s %s\n" "$human_size" "$modtime" "$filepath"
                        total_size=$((total_size + size))
                    done
                    echo "----------------------------------------"
                    local total_human_size
                    total_human_size=$(format_file_size "$total_size")
                    print_colored "$GREEN" "合計サイズ: $total_human_size"
                fi
                ;;
            5)
                if [[ ${#selected_indices[@]} -eq 0 ]]; then
                    print_colored "$RED" "削除するファイルが選択されていません"
                else
                    delete_selected_files "${selected_indices[@]}"
                    return 0
                fi
                ;;
            6)
                return 0
                ;;
            *)
                print_colored "$RED" "無効な選択です。1-6を選んでください。"
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
    echo ""
    print_colored "$YELLOW" "削除確認"
    echo "----------------------------------------"
    print_colored "$RED" "以下の ${#SELECTED_FILES[@]} 個のファイルをごみ箱に移動します:"
    
    for filepath in "${SELECTED_FILES[@]}"; do
        echo "  $filepath"
    done
    
    local total_human_size
    total_human_size=$(format_file_size "$total_size")
    echo "----------------------------------------"
    print_colored "$BLUE" "合計削除サイズ: $total_human_size"
    echo ""
    
    read -p "本当に削除しますか？ (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local success_count=0
        local error_count=0
        
        print_colored "$YELLOW" "ファイルをごみ箱に移動しています..."
        
        for filepath in "${SELECTED_FILES[@]}"; do
            if command -v gio >/dev/null 2>&1; then
                if gio trash "$filepath" 2>/dev/null; then
                    ((success_count++))
                    print_colored "$GREEN" "移動完了: $(basename "$filepath")"
                else
                    ((error_count++))
                    print_colored "$RED" "移動失敗: $filepath"
                fi
            else
                # Fallback: move to a trash directory
                local trash_dir="$HOME/.local/share/Trash/files"
                mkdir -p "$trash_dir"
                if mv "$filepath" "$trash_dir/" 2>/dev/null; then
                    ((success_count++))
                    print_colored "$GREEN" "移動完了: $(basename "$filepath")"
                else
                    ((error_count++))
                    print_colored "$RED" "移動失敗: $filepath"
                fi
            fi
        done
        
        echo ""
        print_colored "$GREEN" "削除操作完了!"
        print_colored "$BLUE" "成功: $success_count 個"
        if [[ $error_count -gt 0 ]]; then
            print_colored "$RED" "失敗: $error_count 個"
        fi
    else
        print_colored "$YELLOW" "削除操作をキャンセルしました。"
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
        print_colored "$RED" "エラー: 必要なコマンドが見つかりません: ${missing_commands[*]}"
        print_colored "$BLUE" "インストール: sudo apt update && sudo apt install findutils bc"
        exit 1
    fi
    
    # Load configuration
    load_config
    
    # Main program loop
    print_colored "$GREEN" "大容量ファイル整理スクリプト for Linux"
    print_colored "$BLUE" "Ubuntu 22.04+ 用ディスククリーンアップツール"
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
        read -p "別の検索を実行しますか？ (y/N): " continue_search
        if [[ ! "$continue_search" =~ ^[Yy]$ ]]; then
            break
        fi
    done
    
    print_colored "$GREEN" "プログラムを終了します。ご利用ありがとうございました！"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi