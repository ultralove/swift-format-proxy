# swift-format-proxy

A smart proxy wrapper for Xcode's bundled `swift-format` tool that provides intelligent defaults, enhanced error handling, and flexible configuration options for Swift code formatting.

## Overview

`swift-format-proxy` is a command-line utility that acts as an intelligent wrapper around Xcode's bundled `swift-format` tool (accessed via `xcrun`). It automatically detects common Swift project structures and applies sensible default formatting options, while maintaining full compatibility with the underlying `swift-format` command. The primary use case is to enable the apple-swift-format VS Code extension to work with Xcode's bundled swift-format tool.

## Features

- **Intelligent Defaults**: Automatically formats `Sources/` and `Tests/` directories when no arguments are provided
- **Flexible Configuration**: Manage proxy settings with the `config` subcommand
- **Multiple Execution Modes**: Use Xcode's bundled swift-format (via `xcrun`) or swift-format from PATH
- **XDG Compliance**: Configuration stored in XDG Base Directory compliant locations
- **Verbose Output**: Optional detailed logging of operations
- **Error Handling**: Provides clear error messages when `xcrun` or `swift-format` are unavailable
- **Full Compatibility**: Passes through all arguments to the underlying `swift-format` tool
- **Zero Configuration**: Works out of the box with standard Swift package layouts
- **In-place Formatting**: Applies formatting directly to source files by default

## Prerequisites

- macOS with Xcode Command Line Tools installed (required for `xcrun` mode)
- Swift 6.1 or later
- Xcode's bundled `swift-format` available via `xcrun` OR standalone `swift-format` in PATH

**Note**: This tool can work with either Xcode's bundled `swift-format` (default) or standalone swift-format installations. It's designed primarily for use with the apple-swift-format VS Code extension.

## Installation

### Building from Source

1. Clone the repository:

   ```bash
   git clone https://github.com/ultralove/swift-format-proxy.git
   cd swift-format-proxy
   ```

2. Build the executable:

   ```bash
   swift build -c release
   ```

3. Copy to a directory in your PATH:

   ```bash
   cp .build/release/swift-format-proxy /usr/local/bin/
   ```

## Usage

### Configuration Management

`swift-format-proxy` includes a configuration system to manage proxy behavior:

```bash
# Show current configuration
swift-format-proxy config --show

# Initialize configuration file
swift-format-proxy config --initialize

# Enable verbose output
swift-format-proxy config --enable-verbose

# Use swift-format from PATH instead of xcrun
swift-format-proxy config --enable-bypass-xcrun

# Disable verbose output
swift-format-proxy config --disable-verbose

# Use xcrun swift-format (default)
swift-format-proxy config --disable-bypass-xcrun
```

Configuration is stored in XDG Base Directory compliant locations:

- `$XDG_CONFIG_HOME/swift-format-proxy/config.json`
- `~/.config/swift-format-proxy/config.json` (fallback)

### VS Code Integration

To use this tool with the apple-swift-format VS Code extension, add the following to your VS Code settings:

```json
{
  "apple-swift-format.path": [
    "/path/to/swift-format-proxy"
  ],
  "apple-swift-format.configSearchPaths": [
    "/path/to/your/.swift-format"
  ],
  "[swift]": {
    "editor.defaultFormatter": "vknabel.vscode-apple-swift-format",
    "editor.formatOnSave": true
  }
}
```

Replace `/path/to/swift-format-proxy` with the actual path where you installed the tool (e.g., `/usr/local/bin/swift-format-proxy`).

### Basic Usage (Automatic Detection)

When run without arguments in a Swift package directory, `swift-format-proxy` will automatically:

- Look for `Sources/` and `Tests/` directories
- Format all Swift files in those directories recursively
- Apply changes in-place

```bash
# Format using intelligent defaults (format subcommand is default)
swift-format-proxy

# Explicitly use format subcommand
swift-format-proxy format
```

This is equivalent to running:

```bash
xcrun swift-format format -r Sources Tests --in-place
```

### Custom Arguments

You can pass any arguments that `swift-format` accepts to the format subcommand:

```bash
# Format a specific file
swift-format-proxy format MyFile.swift

# Check formatting without making changes
swift-format-proxy format --diff Sources/

# Use custom configuration
swift-format-proxy format --configuration .swift-format Sources/

# Show swift-format help
swift-format-proxy format --help

# Show swift-format-proxy help
swift-format-proxy --help
swift-format-proxy format --configuration .swift-format Sources/

# Show help
swift-format-proxy --help
```

### Integration with Development Workflow

#### Pre-commit Hook

Add to your `.git/hooks/pre-commit`:

```bash
#!/bin/sh
swift-format-proxy format
git add -A
```

#### Makefile Integration

```bash
format:
    swift-format-proxy format

check-format:
    swift-format-proxy format --diff Sources/ Tests/

setup-format:
    swift-format-proxy config --initialize
    swift-format-proxy config --enable-verbose
```

## Error Codes

- **0**: Success
- **1**: General error (failed to run swift-format)
- **126**: `swift-format` is not available or failed to run
- **127**: `xcrun` not found

## Project Structure

```text
swift-format-proxy/
├── Sources/
│   └── main.swift          # Main executable source
├── Package.swift           # Swift package manifest
├── README.md              # This file
└── LICENSE                # MIT License
```

## How It Works

1. **Configuration Loading**: Loads user configuration from XDG-compliant config file (if exists)
2. **Environment Check**: Verifies that `xcrun` is available (unless bypass mode is enabled)
3. **Tool Availability**: Checks that the configured swift-format tool runs successfully
4. **Argument Processing**: If no arguments are provided to the format command, automatically detects `Sources/` and `Tests/` directories
5. **Execution**: Runs the configured swift-format tool with the determined arguments, preserving all input/output streams

### Execution Modes

- **xcrun mode** (default): Uses `/usr/bin/xcrun swift-format` with Xcode's bundled version
- **PATH mode**: Uses `swift-format` from system PATH (enabled with `--enable-bypass-xcrun`)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [apple/swift-format](https://github.com/apple/swift-format) - The standalone Swift code formatter (different from Xcode's bundled version)
- [nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Alternative Swift code formatter

**Important**: This tool is specifically designed for Xcode's bundled `swift-format` and is not compatible with the standalone `apple/swift-format` package.

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/ultralove/swift-format-proxy/issues) page
2. Create a new issue with detailed information about your problem
3. Include your macOS version, Xcode version, and swift-format-proxy version

---

**Note**: This tool supports both Xcode's bundled `swift-format` (via `xcrun`) and standalone swift-format installations (via PATH). The default mode uses Xcode's bundled version, but you can configure it to use other installations with the config subcommand. For non-macOS environments or when you prefer standalone versions, enable bypass mode with `swift-format-proxy config --enable-bypass-xcrun`.
