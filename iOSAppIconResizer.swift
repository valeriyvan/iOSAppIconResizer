#!/usr/bin/swift

//  Created by Valeriy Van on 03-JUL-2018.
//  Copyright © 2019 Valeriy Van. All rights reserved.

import Foundation
import Cocoa

let sizes: [(Double, String)] = [
    // iPhone Notification
    // iOS 7-14
    // 20pt
    (40.0, "20@2x"),
    (60.0, "20@3x"),

    // iPhone Settings
    // iOS 7-14
    // 29pt
    (58.0, "29@2x"),
    (87.0, "29@3x"),

    // iPhone Spotlight
    // iOS 7-14
    // 40pt
    (80.0, "40@2x"),
    (120.0, "40@3x"),

    // iPhone App
    // iOS 7-14
    // 60pt
    (120.0, "60@2x"),
    (180.0, "60@3x"),

    // iPad Notifications
    // iOS 7-14
    // 20pt
    (20.0, "20"),
    (40.0, "20@2x"),

    // iPad Settings
    // iOS 7-14
    // 29pt
    (29.0, "29"),
    (58.0, "29@2x"),

    // iPad Spotlight
    // iOS 7-14
    // 40pt
    (40.0, "40"),
    (80.0, "40@2x"),

    // iPad App
    // iOS 7-14
    // 76pt
    (76.0, "76"),
    (152.0, "76@2x"),

    // iPad Pro (12.9-inch) App
    // iOS 9-14
    // 83.5pt
    (167.0, "83,5@2x"),

    // App Store
    // iOS
    // 1024pt
    (1024.0, "1024")
]

extension NSImage {
    private func bitmapImageRep(size: NSSize) -> NSBitmapImageRep? {
        return NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0)
    }

    private func draw(bitmapImageRep: NSBitmapImageRep, at: NSPoint, from: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapImageRep)
        draw(at: at, from: from, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
    }

    private var unscaledBitmapImageRep: NSBitmapImageRep {
        guard let rep = bitmapImageRep(size: size) else { preconditionFailure() }
        draw(bitmapImageRep: rep, at: .zero, from: .zero)
        return rep
    }

    var centerCroppedImage: NSImage {
        let minSize = min(size.width, size.height)
        let croppedSize = NSSize(width: minSize, height: minSize)
        let croppedOrigin = NSPoint(x: (size.width - minSize) / 2.0, y: (size.height - minSize) / 2.0)
        let croppedRect = NSRect(origin: croppedOrigin, size: croppedSize)
        guard let rep = bitmapImageRep(size: croppedSize) else { preconditionFailure() }
        draw(bitmapImageRep: rep, at: .zero, from: croppedRect)
        let image = NSImage(size: croppedSize)
        image.addRepresentation(rep)
        return image
    }

    func write(usingType type: NSBitmapImageRep.FileType, pixelsSize: NSSize?, to url: URL) throws {
        if let pixelsSize = pixelsSize {
            size = pixelsSize
        }
        guard let data = unscaledBitmapImageRep.representation(using: type, properties: [.compressionFactor: 1.0]) else {
            preconditionFailure()
        }
        try data.write(to: url)
    }
}

func main() -> Int32 {
    let defaultOutputFolder = "output"
    let defaultExt = "png"

    guard [2,3].contains(CommandLine.argc) else {
        let url = URL(fileURLWithPath: CommandLine.arguments[0])
        let name = url.lastPathComponent
        print("""
            Usage: \(name) path-to-source-icon [output]
                Rescales source icon to sizes needed by Xcode 11 for iOS 7 - 14 and puts them to output-folder.
                If output is not provided, subfolder `\(defaultOutputFolder)` in path-to-source-icon is used
                for writing images, filename of path-to-source-icon is used as base of file name.
                If output is provided, it might specify output folder, base file name or both:
                    if output doesn't contain `/` it is treated as base file name only;
                    if output ends with `/` it is treated as specifying output folder only;
                    otherwise part before last `/` is treated as output folder and after last `/` as base file name.
            """)
        return 1
    }

    let inputUrl = URL(fileURLWithPath: CommandLine.arguments[1])
    let ext = inputUrl.pathExtension.isEmpty ? defaultExt : inputUrl.pathExtension
    guard var inputImage = NSImage(contentsOf: inputUrl) else {
        print("Can't open \(inputUrl)")
        return -1
    }

    if inputImage.size.width != inputImage.size.height {
        print("Warning: input image has size \(Int(inputImage.size.width))x\(Int(inputImage.size.height)) which isn't square. Output images will be croped.")
        inputImage = inputImage.centerCroppedImage
    }

    let outputFolderUrl: URL
    let outputBaseFileName: String
    let inputFilename = inputUrl.deletingPathExtension().lastPathComponent
    if CommandLine.argc == 3 {
        let argument2 = CommandLine.arguments[2]
        if argument2.contains("/") {
            if argument2.last! == "/" {
                let outputFolderString = argument2.dropLast(argument2.count > 1 ? 1 : 0) // keep unchanges "/" otherwise drop last char
                outputFolderUrl = URL(fileURLWithPath: String(outputFolderString), isDirectory: true)
                outputBaseFileName = inputFilename
            } else {
                let range = argument2.range(of: "/", options: .backwards)!
                outputFolderUrl = URL(fileURLWithPath: String(argument2[..<range.lowerBound]), isDirectory: true)
                outputBaseFileName = String(argument2[range.upperBound...])
            }
        } else {
            outputFolderUrl = inputUrl.deletingLastPathComponent().appendingPathComponent(defaultOutputFolder, isDirectory: true)
            outputBaseFileName = argument2
        }
    } else {
        outputFolderUrl = inputUrl.deletingLastPathComponent().appendingPathComponent(defaultOutputFolder, isDirectory: true)
        outputBaseFileName = inputFilename
    }

    do {
        try FileManager.default.createDirectory(at: outputFolderUrl, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print(error)
        // continue
    }

    for (size, suffix) in sizes {
        let outputUrl = outputFolderUrl
            .appendingPathComponent(outputBaseFileName + suffix, isDirectory: false)
            .appendingPathExtension(ext)
        print(outputUrl.path.removingPercentEncoding ?? outputUrl.path, terminator: "")
        do {
            try inputImage.write(usingType: .png, pixelsSize: NSSize(width: size, height: size), to: outputUrl)
        } catch {
            print(" ", error)
            continue
        }
        print()
    }

    return 0
}

let code = main()
exit(code)
