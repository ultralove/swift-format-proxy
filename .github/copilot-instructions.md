# Copilot Instructions for swift-format-proxy

*Last updated: August 25, 2025*

## Project Understanding

This project is `swift-format-proxy`, a smart wrapper around Xcode's bundled `swift-format` tool. Based on my analysis of the codebase and README:

### Core Purpose
- **Primary Goal**: Enable VS Code's apple-swift-format extension to work with Xcode's bundled swift-format (via `xcrun`)
- **Bridge Tool**: Connects VS Code ecosystem with macOS native Swift tooling
- **Intelligent Wrapper**: Provides smart defaults and enhanced error handling for swift-format

### Key Technical Details
1. **Platform Specific**: macOS-only tool that requires Xcode Command Line Tools
2. **Swift 6.1**: Uses latest Swift version with swift-tools-version 6.1
3. **Single File**: Simple `main.swift` executable with focused functionality
4. **No Dependencies**: Pure Foundation-based implementation

### Architecture Analysis
The tool follows a clear, simple architecture:

1. **Environment Validation**:
   - Checks for `xcrun` availability at `/usr/bin/xcrun`
   - Validates `swift-format` can be executed via `xcrun`

2. **Intelligent Defaults**:
   - Auto-detects `Sources/` and `Tests/` directories
   - Applies sensible default arguments when none provided
   - Falls back to help when no valid directories found

3. **Pass-through Design**:
   - Maintains full compatibility with underlying swift-format
   - Preserves all I/O streams (stdin, stdout, stderr)
   - Returns proper exit codes for CI/scripting integration

### Use Case Prioritization
1. **Primary**: VS Code extension integration
2. **Secondary**: Command-line usage with smart defaults
3. **Tertiary**: CI/CD integration and pre-commit hooks

### Design Philosophy
- **Zero Configuration**: Works out of the box for standard Swift packages
- **Non-invasive**: Doesn't change swift-format behavior, just enhances it
- **Error Clarity**: Provides clear, actionable error messages
- **Compatibility First**: Maintains 100% compatibility with underlying tool

## Development Guidelines

When working on this project:

1. **Maintain Simplicity**: Keep the single-file architecture
2. **Preserve Compatibility**: Never break swift-format argument compatibility
3. **macOS Focus**: This is intentionally macOS-specific, don't add cross-platform abstractions
4. **VS Code Priority**: Primary use case is VS Code extension support
5. **Error Handling**: Maintain clear, helpful error messages with specific exit codes
6. **Performance**: Keep startup time minimal for responsive editor integration

### Commit Workflow
When asked to "commit the latest changes":
1. Stage all changes with `git add .`
2. Write a detailed but concise commit message using conventional commits format
3. Commit the changes with the generated message
4. Do this automatically without asking for confirmation

## Context for AI Assistance

This tool solves a specific integration problem: VS Code's apple-swift-format extension needs to work with Xcode's bundled swift-format tool, but the extension expects certain behaviors that the raw tool doesn't provide. The proxy adds:

- Automatic project structure detection
- Sensible default arguments
- Enhanced error reporting
- Reliable exit code handling

The tool is intentionally minimal and focused, avoiding feature creep while solving the core integration challenge effectively.

## Recent Updates & Decisions

*This section tracks significant changes and decisions made during development.*

### August 25, 2025
- **Added timestamp and decision log structure**: Enhanced copilot instructions with "Last updated" timestamp and "Recent Updates & Decisions" section for better change tracking and project history maintenance.
- **Added SwiftArgumentParser dependency**: Introduced SwiftArgumentParser package to enable more robust command-line argument parsing. This maintains compatibility while providing better error handling and help documentation. The dependency is minimal and aligns with the project's focus on improving the CLI experience for VS Code integration.
- **Updated SwiftArgumentParser to latest version**: Changed dependency specification from `from: "1.0.0"` to `.upToNextMajor(from: "1.5.0")` to ensure we always use the latest stable version (currently 1.6.1) while maintaining API compatibility within the major version.
- **Added project version constant**: Defined version "1.0.1" as a constant in main.swift for use in version reporting and help text. Swift Package Manager doesn't support version properties in Package.swift, so the version is maintained in the source code where it can be accessed by SwiftArgumentParser for --version flags.
- **Added config subcommand**: Implemented `config` subcommand using SwiftArgumentParser with three main functions: `--show` (display current swift-format configuration), `--initialize` (create default .swift-format file), and `--validate <path>` (validate configuration file). Restructured main command to use subcommands with `format` as the default subcommand, maintaining backward compatibility while expanding functionality for better swift-format configuration management.
- **Refactored config to manage swift-format-proxy settings**: Changed config subcommand from managing swift-format's configuration to managing swift-format-proxy's own settings. Added ProxyConfiguration structure with settings for default directories, format arguments, verbose output, and xcrun path. Configuration is stored in `~/.swift-format-proxy.json` and provides options like `--set-directories`, `--enable-verbose`, and `--set-xcrun-path` for customization.
- **Streamlined config options and added PATH support**: Removed default directories and format arguments from configuration (now hardcoded to Sources/Tests and standard options) to simplify the tool. Added `--enable-bypass-xcrun` option to use swift-format from PATH instead of xcrun, enabling support for non-Xcode swift-format installations. Configuration now focuses on execution mode (xcrun vs PATH) and verbosity rather than behavioral defaults.
- **Implemented XDG Base Directory compliance**: Updated configuration file location to follow XDG Base Directory Specification. Config file is now stored at `$XDG_CONFIG_HOME/swift-format-proxy/config.json` (with fallback to `~/.config/swift-format-proxy/config.json`). This provides better system integration and follows Unix/Linux configuration standards, while automatically creating necessary directories when saving configuration.
