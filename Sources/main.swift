//
// main.swift
// swift-format-proxy
//
// Copyright © 2025 Ultralove Contributors
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

import Foundation

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

// ---- MAIN ----

if !isXcrunAvailable() {
    fputs("Error: xcrun not found at /usr/bin/xcrun.\n", stderr)
    exit(127)
}

if !isSwiftFormatAvailable() {
    fputs("Error: 'xcrun swift-format' is not available or failed to run.\n", stderr)
    exit(126)
}

let userArgs = Array(CommandLine.arguments.dropFirst())
let argsToUse = userArgs.isEmpty ? defaultFormatArguments() : userArgs

exit(runSwiftFormat(arguments: argsToUse))
