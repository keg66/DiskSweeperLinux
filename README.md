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
   - Custom path
   - Exit

2. **Size Threshold**: Select minimum file size to search for
   - 50MB or larger
   - 100MB or larger (recommended)
   - 500MB or larger
   - 1GB or larger
   - Custom size
   - Use previous threshold

3. **File Selection**: Choose files to delete
   - Individual file selection/deselection
   - Select all files
   - Deselect all files
   - View selected files
   - Execute deletion
   - Return to main menu

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