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
        helpNames: [.short, .long]
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

/// Check if xcrun exists
func isXcrunAvailable() -> Bool {
    FileManager.default.isExecutableFile(atPath: "/usr/bin/xcrun")
}

/// Check if xcrun swift-format is functional
func isSwiftFormatAvailable() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift-format", "--version"]
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
    if fm.fileExists(atPath: "Sources", isDirectory: nil) {
        paths.append("Sources")
    }
    if fm.fileExists(atPath: "Tests", isDirectory: nil) {
        paths.append("Tests")
    }

    guard !paths.isEmpty else {
        fputs("swift-format-proxy: No 'Sources/' or 'Tests/' directory found in current directory.\n", stderr)
        return ["--help"]
    }

    return ["format", "-r"] + paths + ["--in-place"]
}

/// Run xcrun swift-format with arguments
func runSwiftFormat(arguments: [String]) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift-format"] + arguments
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    process.standardInput = FileHandle.standardInput

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
    catch {
        fputs("Error: Failed to run xcrun swift-format: \(error)\n", stderr)
        return 1
    }
}
