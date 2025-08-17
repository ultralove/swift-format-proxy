# swift-format-proxy

A smart proxy wrapper for Xcode's bundled `swift-format` tool that provides intelligent defaults and enhanced error handling for Swift code formatting.

## Overview

`swift-format-proxy` is a command-line utility that acts as an intelligent wrapper around Xcode's bundled `swift-format` tool (accessed via `xcrun`). It automatically detects common Swift project structures and applies sensible default formatting options, while maintaining full compatibility with the underlying `swift-format` command. The primary use case is to enable the apple-swift-format VS Code extension to work with Xcode's bundled swift-format tool.

## Features

- **Intelligent Defaults**: Automatically formats `Sources/` and `Tests/` directories when no arguments are provided
- **Error Handling**: Provides clear error messages when `xcrun` or `swift-format` are unavailable
- **Full Compatibility**: Passes through all arguments to the underlying `swift-format` tool
- **Zero Configuration**: Works out of the box with standard Swift package layouts
- **In-place Formatting**: Applies formatting directly to source files by default

## Prerequisites

- macOS with Xcode Command Line Tools installed (required for `xcrun`)
- Swift 6.1 or later
- Xcode's bundled `swift-format` available via `xcrun`

**Note**: This tool specifically works with Xcode's bundled `swift-format` and is designed primarily for use with the apple-swift-format VS Code extension.

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
swift-format-proxy
```

This is equivalent to running:

```bash
xcrun swift-format format -r Sources Tests --in-place
```

### Custom Arguments

You can pass any arguments that Xcode's `swift-format` accepts:

```bash
# Format a specific file
swift-format-proxy format MyFile.swift

# Check formatting without making changes
swift-format-proxy format --diff Sources/

# Use custom configuration
swift-format-proxy format --configuration .swift-format Sources/

# Show help
swift-format-proxy --help
```

### Integration with Development Workflow

#### Pre-commit Hook

Add to your `.git/hooks/pre-commit`:

```bash
#!/bin/sh
swift-format-proxy
git add -A
```

#### Makefile Integration

```makefile
format:
    swift-format-proxy

check-format:
    swift-format-proxy --diff Sources/ Tests/
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

1. **Environment Check**: Verifies that `xcrun` is available at `/usr/bin/xcrun`
2. **Tool Availability**: Checks that `xcrun swift-format --version` runs successfully (Xcode's bundled version)
3. **Argument Processing**: If no arguments are provided, automatically detects `Sources/` and `Tests/` directories
4. **Execution**: Runs `xcrun swift-format` with the determined arguments, preserving all input/output streams

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

**Note**: This tool requires Xcode's bundled `swift-format` to be installed and available via `xcrun`. It is not compatible with standalone swift-format packages or VS Code extensions. If you're using a non-macOS environment or prefer the standalone version, consider using alternative Swift formatting tools.
