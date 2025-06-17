# FileCleanupTool - Large File Cleanup Utility for Linux

A bash-based file cleanup utility for Ubuntu 22.04+ that helps users find and remove large files to free up disk space.

## Features

- **File Search**: Find files above configurable size thresholds (50MB, 100MB, 500MB, 1GB+)
- **Interactive CUI**: Command-line interface with progress display
- **File Selection**: Individual and bulk file selection with checkboxes
- **Safe Deletion**: Move files to trash (not permanent deletion)
- **Configuration**: Save user preferences (last folder, size threshold)
- **No Admin Rights**: Runs with regular user permissions
- **Zero Dependencies**: Uses only Ubuntu standard tools

## Requirements

- Ubuntu 22.04 or later
- Standard Ubuntu commands: `find`, `bc`, `gio` (for trash functionality)
- No additional packages required

## Installation

1. Download the script:
   ```bash
   wget https://github.com/your-repo/DiskSweeperLinux/raw/main/FileCleanupTool.bash
   ```

2. Make it executable:
   ```bash
   chmod +x FileCleanupTool.bash
   ```

## Usage

### Basic Usage

Run the script directly:
```bash
./FileCleanupTool.bash
```

### Command Line Options

```bash
./FileCleanupTool.bash [options]

Options:
  -h, --help     Show help message
  -v, --version  Show version information
```

### Interactive Menu

The tool provides an interactive menu system in Japanese:

1. **Folder Selection**: Choose target directory to scan
   - Use previous folder
   - Home directory
   - Custom path (with Tab completion and tilde expansion)
   - Exit

2. **Size Threshold**: Select minimum file size to search for
   - 50MB or larger
   - 100MB or larger (recommended)
   - 500MB or larger
   - 1GB or larger
   - Custom size
   - Use previous threshold

3. **File Selection**: Choose files to delete
   - Multiple file selection/deselection (single, multiple, ranges)
   - Select all files
   - Deselect all files
   - View selected files
   - Execute deletion
   - Return to main menu

### Path Input Features

When entering a custom folder path:

- **Tab Completion**: Press Tab to auto-complete directory paths
  - Example: Type `/ho` and press Tab → completes to `/home/`
- **Tilde Expansion**: Use `~` as shorthand for home directory
  - Example: `~/Documents` expands to `/home/username/Documents`
- **Real-time Validation**: Immediate feedback if path doesn't exist

### Multiple File Selection

When selecting files for deletion, you can use various input formats:

- **Single file**: `5` - Select/deselect file number 5
- **Multiple files**: `1,3,5` - Select/deselect files 1, 3, and 5
- **Range selection**: `2-7` - Select/deselect files 2 through 7
- **Mixed format**: `1,3,5-8` - Select/deselect file 1, 3, and files 5 through 8

**Examples:**
```
Enter file number(s): 1,3,5      # Select files 1, 3, and 5
Enter file number(s): 2-7        # Select files 2 through 7
Enter file number(s): 1,3,5-8    # Select file 1, 3, and files 5-8
Enter file number(s): 10         # Toggle selection of file 10
```

## Configuration

The tool automatically saves your preferences in `config.json`:

```json
{
    "last_folder": "/home/username",
    "last_size_threshold": "100M",
    "created_at": "2025-06-16T10:30:00+09:00"
}
```

## File Structure

```
FileCleanupTool.bash    # Main executable script
config.json            # Auto-generated configuration file
README.md              # This documentation
```

## Safety Features

- **Trash Integration**: Uses `gio trash` to move files to system trash
- **Confirmation Dialog**: Simple confirmation before deletion
- **No Permanent Deletion**: Files can be recovered from trash
- **Error Handling**: Appropriate error messages for common issues

## Performance

- **Lightweight**: Minimal system resource usage
- **Progress Display**: Real-time search progress indication
- **Memory Efficient**: Processes files without loading all into memory
- **Non-blocking**: Won't interfere with other applications

## Troubleshooting

### Missing Commands

If you get "command not found" errors:

```bash
# Install required packages
sudo apt update
sudo apt install findutils bc

# For trash functionality
sudo apt install glib2.0-bin
```

### Permission Issues

- The script runs with regular user permissions
- Cannot access system files that require admin rights
- This is by design for safety
- **Note**: You may see a message about skipped directories - this is normal when scanning directories with restricted access (like system files)

### Large Directory Scanning

- Scanning very large directories may take time
- Progress indicator shows current status
- Press Ctrl+C to cancel if needed

## Development

### Testing Syntax

```bash
# Check bash syntax
bash -n FileCleanupTool.bash
```

### Running in Debug Mode

```bash
# Enable bash debugging
bash -x FileCleanupTool.bash
```

## License

This project is released under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and feature requests, please use the GitHub issue tracker.

## Version History

- **v1.0** - Initial release
  - Basic file search and deletion functionality
  - Interactive CUI interface
  - Configuration management
  - Trash integration