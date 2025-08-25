//
// Copyright (c) 2025 Ultralove Contributors
//
// MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import ArgumentParser
import Foundation

/// swift-format-proxy - A smart wrapper around Xcode's bundled swift-format tool
@main
struct SwiftFormatProxy: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-format-proxy",
        abstract: "A smart wrapper around Xcode's bundled swift-format tool",
        version: "1.0.1",
        subcommands: [Format.self, Config.self],
        defaultSubcommand: Format.self,
        helpNames: [.short, .long]
    )
}

/// Format subcommand - the default behavior
struct Format: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "format",
        abstract: "Format Swift code using Xcode's bundled swift-format (default command)"
    )

    @Argument(
        parsing: .remaining,
        help: "Arguments to pass to swift-format. If no arguments are provided, defaults to formatting Sources/ and Tests/ directories."
    )
    var arguments: [String] = []

    mutating func run() throws {
        // Environment validation
        guard isXcrunAvailable() else {
            throw ValidationError("xcrun not found at /usr/bin/xcrun.")
        }

        guard isSwiftFormatAvailable() else {
            throw ValidationError("'xcrun swift-format' is not available or failed to run.")
        }

        // Determine arguments to use
        let argsToUse = arguments.isEmpty ? defaultFormatArguments() : arguments

        // Run swift-format
        let exitCode = runSwiftFormat(arguments: argsToUse)
        throw ExitCode(exitCode)
    }
}

/// swift-format-proxy configuration structure
struct ProxyConfiguration: Codable {
    /// Whether to show verbose output
    var verbose: Bool = false

    /// Whether to bypass xcrun and use swift-format from PATH
    var bypassXcrun: Bool = false

    /// Custom xcrun path (if not using /usr/bin/xcrun)
    var xcrunPath: String = "/usr/bin/xcrun"

    /// Configuration file version for future compatibility
    var version: String = "1.0"
}

/// Config subcommand - manage swift-format-proxy configuration
struct Config: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage swift-format-proxy configuration and settings"
    )

    @Flag(name: .shortAndLong, help: "Show current swift-format-proxy configuration")
    var show: Bool = false

    @Flag(name: .shortAndLong, help: "Initialize a default swift-format-proxy configuration file")
    var initialize: Bool = false

    @Flag(name: .long, help: "Enable verbose output")
    var enableVerbose: Bool = false

    @Flag(name: .long, help: "Disable verbose output")
    var disableVerbose: Bool = false

    @Flag(name: .long, help: "Enable bypassing xcrun and use swift-format from PATH")
    var enableBypassXcrun: Bool = false

    @Flag(name: .long, help: "Disable bypassing xcrun (use xcrun swift-format)")
    var disableBypassXcrun: Bool = false

    @Option(name: .long, help: "Set custom xcrun path")
    var setXcrunPath: String?

    mutating func run() throws {
        let configPath = getConfigPath()

        if show {
            try showConfig(configPath: configPath)
        } else if initialize {
            try initializeConfig(configPath: configPath)
        } else if enableVerbose || disableVerbose || enableBypassXcrun || disableBypassXcrun || setXcrunPath != nil {
            try updateConfig(configPath: configPath)
        } else {
            throw ValidationError("Please specify an action: --show, --initialize, or set a configuration option")
        }
    }

    private func getConfigPath() -> String {
        return getXDGConfigPath()
    }

    private func loadConfig(from path: String) throws -> ProxyConfiguration {
        guard FileManager.default.fileExists(atPath: path) else {
            return ProxyConfiguration() // Return default config if none exists
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(ProxyConfiguration.self, from: data)
    }

    private func saveConfig(_ config: ProxyConfiguration, to path: String) throws {
        // Create directory if it doesn't exist
        let configURL = URL(fileURLWithPath: path)
        let configDir = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true, attributes: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }

    private func showConfig(configPath: String) throws {
        let config = try loadConfig(from: configPath)

        print("swift-format-proxy configuration:")
        print("├─ Configuration file: \(configPath)")
        print("├─ Verbose output: \(config.verbose ? "enabled" : "disabled")")
        print("├─ Bypass xcrun: \(config.bypassXcrun ? "enabled (use PATH swift-format)" : "disabled (use xcrun)")")
        print("├─ xcrun path: \(config.xcrunPath)")
        print("└─ Configuration version: \(config.version)")

        if !FileManager.default.fileExists(atPath: configPath) {
            print("\nNote: Using default configuration (no config file found)")
            print("Run 'swift-format-proxy config --initialize' to create a configuration file.")
        }
    }

    private func initializeConfig(configPath: String) throws {
        if FileManager.default.fileExists(atPath: configPath) {
            print("Configuration file already exists: \(configPath)")
            print("Use configuration options to modify settings, or remove the file to reinitialize.")
            return
        }

        let config = ProxyConfiguration()
        try saveConfig(config, to: configPath)
        print("Created swift-format-proxy configuration file: \(configPath)")
        print("Use 'swift-format-proxy config --show' to view current settings.")
    }

    private func updateConfig(configPath: String) throws {
        var config = try loadConfig(from: configPath)
        var changes: [String] = []

        if enableVerbose {
            config.verbose = true
            changes.append("verbose output: enabled")
        }

        if disableVerbose {
            config.verbose = false
            changes.append("verbose output: disabled")
        }

        if enableBypassXcrun {
            config.bypassXcrun = true
            changes.append("bypass xcrun: enabled (will use swift-format from PATH)")
        }

        if disableBypassXcrun {
            config.bypassXcrun = false
            changes.append("bypass xcrun: disabled (will use xcrun swift-format)")
        }

        if let xcrunPath = setXcrunPath {
            config.xcrunPath = xcrunPath
            changes.append("xcrun path: \(xcrunPath)")
        }

        if changes.isEmpty {
            print("No configuration changes specified.")
            return
        }

        try saveConfig(config, to: configPath)
        print("Updated swift-format-proxy configuration:")
        for change in changes {
            print("  ✓ \(change)")
        }
    }
}

/// Get XDG-compliant config directory path
func getXDGConfigPath() -> String {
    // Check XDG_CONFIG_HOME first
    if let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !xdgConfigHome.isEmpty {
        return "\(xdgConfigHome)/swift-format-proxy/config.json"
    }

    // Fallback to ~/.config
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    return "\(homeDir)/.config/swift-format-proxy/config.json"
}

/// Load proxy configuration
func loadProxyConfig() -> ProxyConfiguration {
    let configPath = getXDGConfigPath()

    guard FileManager.default.fileExists(atPath: configPath) else {
        return ProxyConfiguration() // Return default config if none exists
    }

    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        return try JSONDecoder().decode(ProxyConfiguration.self, from: data)
    } catch {
        // If config is corrupted, return default
        return ProxyConfiguration()
    }
}

/// Check if xcrun exists (or if we're bypassing xcrun)
func isXcrunAvailable() -> Bool {
    let config = loadProxyConfig()

    if config.bypassXcrun {
        // When bypassing xcrun, we don't need to check for it
        return true
    } else {
        // Check if xcrun exists
        return FileManager.default.isExecutableFile(atPath: config.xcrunPath)
    }
}

/// Check if xcrun swift-format is functional
func isSwiftFormatAvailable() -> Bool {
    let config = loadProxyConfig()
    let process = Process()

    if config.bypassXcrun {
        // Check swift-format from PATH
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift-format", "--version"]
    } else {
        // Check xcrun swift-format
        process.executableURL = URL(fileURLWithPath: config.xcrunPath)
        process.arguments = ["swift-format", "--version"]
    }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
    catch {
        return false
    }
}

/// Return default arguments if none are passed
func defaultFormatArguments() -> [String] {
    let fm = FileManager.default
    var paths: [String] = []

    // Use hardcoded default directories
    let defaultDirs = ["Sources", "Tests"]
    for dir in defaultDirs {
        if fm.fileExists(atPath: dir, isDirectory: nil) {
            paths.append(dir)
        }
    }

    guard !paths.isEmpty else {
        fputs("swift-format-proxy: No default directories (Sources, Tests) found in current directory.\n", stderr)
        return ["--help"]
    }

    return ["format", "-r"] + paths + ["--in-place"]
}/// Run xcrun swift-format with arguments
func runSwiftFormat(arguments: [String]) -> Int32 {
    let config = loadProxyConfig()
    let process = Process()

    if config.bypassXcrun {
        // Use swift-format from PATH
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift-format"] + arguments

        if config.verbose {
            fputs("swift-format-proxy: Running swift-format \(arguments.joined(separator: " ")) (from PATH)\n", stderr)
        }
    } else {
        // Use xcrun swift-format
        process.executableURL = URL(fileURLWithPath: config.xcrunPath)
        process.arguments = ["swift-format"] + arguments

        if config.verbose {
            fputs("swift-format-proxy: Running \(config.xcrunPath) swift-format \(arguments.joined(separator: " "))\n", stderr)
        }
    }

    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    process.standardInput = FileHandle.standardInput

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
    catch {
        fputs("Error: Failed to run swift-format: \(error)\n", stderr)
        return 1
    }
}
